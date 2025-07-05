import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/endpoints.dart';

class TranscriptionService {
  static final _client = http.Client();

  // ================================
  // UPLOAD OPERATIONS
  // ================================

  /// Upload an audio/video file for transcription
  /// Returns the GridFS file ID on success.
  static Future<String> uploadTranscriptionVideo({
    required String patientId,
    required int sessionId,
    required File file,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final uri = Uri.parse(ApiConstants.uploadTranscriptionVideo(numericPatientId, sessionId));
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('video', file.path));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return body['video_file_id'] as String;
      } else {
        final err = jsonDecode(resp.body);
        throw Exception(err['error'] ?? 'Upload failed (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload transcription video: $e');
    }
  }

  /// Upload audio/video file using bytes
  static Future<String> uploadTranscriptionVideoFromBytes({
    required String patientId,
    required int sessionId,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final uri = Uri.parse(ApiConstants.uploadTranscriptionVideo(numericPatientId, sessionId));
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('video', bytes, filename: filename));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return body['video_file_id'] as String;
      } else {
        final err = jsonDecode(resp.body);
        throw Exception(err['error'] ?? 'Upload failed (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload transcription video from bytes: $e');
    }
  }

  // ================================
  // ANALYSIS OPERATIONS
  // ================================

  /// Kick off transcription analysis on a previously-uploaded file
  /// Returns the generated PDF file ID.
  static Future<String> analyzeTranscription({
    required String fileId,
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final uri = Uri.parse(ApiConstants.analyzeTranscription(fileId, numericPatientId, sessionId));
      final resp = await _client.get(uri);
      
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return body['pdf_file_id'] as String;
      } else {
        final err = jsonDecode(resp.body);
        throw Exception(err['error'] ?? 'Analysis failed (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      throw Exception('Failed to analyze transcription: $e');
    }
  }

  // ================================
  // DOWNLOAD OPERATIONS
  // ================================

  /// Download the transcription PDF bytes
  static Future<Uint8List> downloadTranscription({
    required String pdfFileId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.downloadTranscription(pdfFileId));
      final resp = await _client.get(uri);
      
      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      } else {
        throw Exception('Download failed (${resp.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to download transcription: $e');
    }
  }

  /// Download transcription and save to local file for viewing
  static Future<String> downloadTranscriptionForViewing({
    required String pdfFileId,
    String? customFileName,
  }) async {
    try {
      final bytes = await downloadTranscription(pdfFileId: pdfFileId);
      
      // Get temporary directory to store the PDF
      final directory = await getTemporaryDirectory();
      final fileName = customFileName ?? 'transcription_$pdfFileId.pdf';
      final file = File('${directory.path}/$fileName');
      
      // Write PDF bytes to local file
      await file.writeAsBytes(bytes);
      
      // Return the local file path
      return file.path;
    } catch (e) {
      throw Exception('Failed to download transcription for viewing: $e');
    }
  }

  /// Download transcription and save to device storage
  static Future<String> downloadTranscriptionToStorage({
    required String pdfFileId,
    String? customFileName,
  }) async {
    try {
      final bytes = await downloadTranscription(pdfFileId: pdfFileId);
      
      // Try different directories based on platform availability
      Directory? directory;
      
      try {
        // Try Downloads directory first (Windows 10+, Android)
        directory = await getDownloadsDirectory();
      } catch (e) {
        print('Downloads directory not available: $e');
      }
      
      // Fallback to Documents directory
      directory ??= await getApplicationDocumentsDirectory();
      
      final fileName = customFileName ?? 'transcription_$pdfFileId.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to download transcription to storage: $e');
    }
  }

  // ================================
  // VIEW OPERATIONS
  // ================================

  /// Build a URI for in-app PDF viewing
  static Uri viewTranscriptionUrl(String pdfFileId) =>
      Uri.parse(ApiConstants.viewTranscription(pdfFileId));

  /// Get view URL as string
  static String getTranscriptionViewUrl(String pdfFileId) =>
      ApiConstants.viewTranscription(pdfFileId);

  /// Get download URL as string
  static String getTranscriptionDownloadUrl(String pdfFileId) =>
      ApiConstants.downloadTranscription(pdfFileId);

  // ================================
  // STATUS OPERATIONS
  // ================================

  /// Check transcription status for a session
  static Future<Map<String, dynamic>> getTranscriptionStatus({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final uri = Uri.parse(ApiConstants.transcriptionStatus(numericPatientId, sessionId));
      final resp = await _client.get(uri);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        // Return default fallback on error
        return {
          'has_transcription': false,
          'transcription_file_id': null,
          'can_generate_transcription': false,
          'needs_media_upload': true,
        };
      }
    } catch (e) {
      // Return default fallback on exception
      return {
        'has_transcription': false,
        'transcription_file_id': null,
        'can_generate_transcription': false,
        'needs_media_upload': true,
      };
    }
  }

  /// Get patient transcriptions summary across all sessions
  static Future<Map<String, dynamic>> getPatientTranscriptionsSummary({
    required String patientId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final uri = Uri.parse(ApiConstants.getTranscriptionsSummary(numericPatientId));
      final resp = await _client.get(uri);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get transcriptions summary: ${resp.body}');
      }
    } catch (e) {
      throw Exception('Failed to get transcriptions summary: $e');
    }
  }

  // ================================
  // CONVENIENCE METHODS
  // ================================

  /// Check if a transcription PDF exists for a session
  static Future<bool> hasTranscription({
    required String patientId,
    required int sessionId,
  }) async {
    final status = await getTranscriptionStatus(
      patientId: patientId,
      sessionId: sessionId,
    );
    return status['has_transcription'] as bool? ?? false;
  }

  /// Check if session can generate transcription
  static Future<bool> canGenerateTranscription({
    required String patientId,
    required int sessionId,
  }) async {
    final status = await getTranscriptionStatus(
      patientId: patientId,
      sessionId: sessionId,
    );
    return status['can_generate_transcription'] as bool? ?? false;
  }

  /// Check if session needs media upload for transcription
  static Future<bool> needsMediaUpload({
    required String patientId,
    required int sessionId,
  }) async {
    final status = await getTranscriptionStatus(
      patientId: patientId,
      sessionId: sessionId,
    );
    return status['needs_media_upload'] as bool? ?? true;
  }

  /// Get transcription file ID if available
  static Future<String?> getTranscriptionFileId({
    required String patientId,
    required int sessionId,
  }) async {
    final status = await getTranscriptionStatus(
      patientId: patientId,
      sessionId: sessionId,
    );
    return status['transcription_file_id'] as String?;
  }

  // ================================
  // VALIDATION & UTILITIES
  // ================================

  /// Validate file for transcription
  static bool isValidTranscriptionFile(File file) {
    const supportedExtensions = ['.mp4', '.avi', '.mov', '.mkv', '.webm', '.wmv', '.mp3', '.wav', '.m4a', '.aac', '.flac'];
    final extension = file.path.toLowerCase().split('.').last;
    return supportedExtensions.contains('.$extension');
  }

  /// Get supported file formats
  static List<String> getSupportedFormats() {
    return ['.mp4', '.avi', '.mov', '.mkv', '.webm', '.wmv', '.mp3', '.wav', '.m4a', '.aac', '.flac'];
  }

  /// Get file size limit (500MB as per backend)
  static int getMaxFileSizeBytes() {
    return 500 * 1024 * 1024; // 500MB
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Validate file size
  static bool isValidFileSize(File file) {
    try {
      final size = file.lengthSync();
      return size <= getMaxFileSizeBytes();
    } catch (e) {
      return false;
    }
  }

  /// Generate safe filename for transcription
  static String generateTranscriptionFileName({
    required String patientId,
    required int sessionId,
    String? customName,
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final dateStr = '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    
    if (customName != null && customName.isNotEmpty) {
      return '${customName}_$dateStr.pdf';
    }
    
    return 'transcription_${patientId}_session_${sessionId}_$dateStr.pdf';
  }

  // ================================
  // LOCAL FILE MANAGEMENT
  // ================================

  /// Check if transcription is cached locally
  static Future<bool> isTranscriptionCached(String pdfFileId) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'transcription_$pdfFileId.pdf';
      final file = File('${directory.path}/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get local transcription path if cached
  static Future<String?> getLocalTranscriptionPath(String pdfFileId) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'transcription_$pdfFileId.pdf';
      final file = File('${directory.path}/$fileName');
      
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get transcription for viewing (cached or download)
  static Future<String> getTranscriptionForViewing(String pdfFileId) async {
    // Check if already cached locally
    final localPath = await getLocalTranscriptionPath(pdfFileId);
    if (localPath != null) {
      return localPath;
    }
    
    // Download if not cached
    return await downloadTranscriptionForViewing(pdfFileId: pdfFileId);
  }

  /// Clear cached transcriptions
  static Future<void> clearCachedTranscriptions() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('transcription_')) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Failed to clear cached transcriptions: $e');
    }
  }

  /// Get cached transcription file size
  static Future<int?> getCachedTranscriptionSize(String pdfFileId) async {
    try {
      final path = await getLocalTranscriptionPath(pdfFileId);
      if (path != null) {
        final file = File(path);
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ================================
  // STATUS DESCRIPTIONS
  // ================================

  /// Get user-friendly status description
  static String getStatusDescription(Map<String, dynamic> status) {
    final hasTranscription = status['has_transcription'] as bool? ?? false;
    final canGenerate = status['can_generate_transcription'] as bool? ?? false;
    final needsMedia = status['needs_media_upload'] as bool? ?? true;
    
    if (hasTranscription) {
      return 'Transcription available for download';
    } else if (canGenerate) {
      return 'Ready for transcription analysis';
    } else if (needsMedia) {
      return 'Upload audio/video file to generate transcription';
    } else {
      return 'Transcription not available';
    }
  }

  /// Get transcription progress description
  static String getProgressDescription(Map<String, dynamic> status) {
    final hasTranscription = status['has_transcription'] as bool? ?? false;
    final canGenerate = status['can_generate_transcription'] as bool? ?? false;
    final needsMedia = status['needs_media_upload'] as bool? ?? true;
    
    if (hasTranscription) {
      return 'Completed';
    } else if (canGenerate) {
      return 'Ready for analysis';
    } else if (needsMedia) {
      return 'Waiting for media upload';
    } else {
      return 'Not available';
    }
  }

  // ================================
  // CLEANUP
  // ================================

  /// Dispose of HTTP client
  static void dispose() {
    _client.close();
  }
}