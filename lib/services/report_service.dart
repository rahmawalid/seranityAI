import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/endpoints.dart';

class ReportService {
  
  // ================================
  // NEW ADVANCED REPORT GENERATION
  // ================================
  
  /// Generate analysis report with automatic type detection (TOV-only vs comprehensive)
  static Future<Map<String, dynamic>> generateAnalysisReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.generateAnalysisReport(numericPatientId, sessionId));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to generate analysis report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate analysis report: $e');
    }
  }

  /// Generate TOV-only analysis report specifically
  static Future<Map<String, dynamic>> generateTovOnlyReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.generateTovOnlyReport(numericPatientId, sessionId));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to generate TOV-only report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate TOV-only report: $e');
    }
  }

  /// Generate comprehensive FER+TOV analysis report specifically
  static Future<Map<String, dynamic>> generateComprehensiveReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.generateComprehensiveReport(numericPatientId, sessionId));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to generate comprehensive report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate comprehensive report: $e');
    }
  }

  /// Generate enhanced report with doctor notes
  static Future<Map<String, dynamic>> generateReportWithDoctorNotes({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.generateReportWithDoctorNotes(numericPatientId, sessionId));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to generate enhanced report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate enhanced report: $e');
    }
  }

  /// Force regenerate report even if one already exists
  static Future<Map<String, dynamic>> forceRegenerateReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.forceRegenerateReport(numericPatientId, sessionId));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to force regenerate report: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to force regenerate report: $e');
    }
  }

  // ================================
  // REPORT METADATA & CAPABILITIES
  // ================================

  /// Get report metadata for a session
  static Future<Map<String, dynamic>> getReportMetadata({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.getReportMetadata(numericPatientId, sessionId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['metadata'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get report metadata: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get report metadata: $e');
    }
  }

  /// Get analysis capabilities and recommendations
  static Future<Map<String, dynamic>> getAnalysisCapabilities({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.getAnalysisCapabilities(numericPatientId, sessionId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get analysis capabilities: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get analysis capabilities: $e');
    }
  }

  /// Get current report status
  static Future<Map<String, dynamic>> getReportStatus({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.getReportStatus(numericPatientId, sessionId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get report status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get report status: $e');
    }
  }

  // ================================
  // SMART REPORT GENERATION
  // ================================

  /// Get recommended report type based on available data
  static Future<String> getRecommendedReportType({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final capabilities = await getAnalysisCapabilities(
        patientId: patientId,
        sessionId: sessionId,
      );
      
      final recommendation = capabilities['recommendation'] as Map<String, dynamic>?;
      return recommendation?['type'] as String? ?? 'automatic';
    } catch (e) {
      return 'automatic';
    }
  }

  /// Generate report using the recommended type
  static Future<Map<String, dynamic>> generateRecommendedReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final recommendedType = await getRecommendedReportType(
        patientId: patientId,
        sessionId: sessionId,
      );

      switch (recommendedType) {
        case 'comprehensive':
          return await generateComprehensiveReport(
            patientId: patientId,
            sessionId: sessionId,
          );
        case 'tov_only':
          return await generateTovOnlyReport(
            patientId: patientId,
            sessionId: sessionId,
          );
        default:
          return await generateAnalysisReport(
            patientId: patientId,
            sessionId: sessionId,
          );
      }
    } catch (e) {
      throw Exception('Failed to generate recommended report: $e');
    }
  }

  // ================================
  // REPORT DOWNLOAD OPERATIONS
  // ================================

  /// Download session report (existing or generate new)
  static Future<Uint8List> downloadSessionReportBytes({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.downloadSessionReport(numericPatientId, sessionId));
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download session report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download session report: $e');
    }
  }

  /// Download PDF report by ID and return bytes
  static Future<Uint8List> downloadReportBytes(String reportId) async {
    try {
      final url = Uri.parse(ApiConstants.downloadReport(reportId));
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download report: $e');
    }
  }

  /// Download session report for viewing in app
  static Future<String> downloadSessionReportForViewing({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final bytes = await downloadSessionReportBytes(
        patientId: patientId,
        sessionId: sessionId,
      );
      
      // Get temporary directory to store the PDF
      final directory = await getTemporaryDirectory();
      final fileName = 'session_report_${patientId}_${sessionId}.pdf';
      final file = File('${directory.path}/$fileName');
      
      // Write PDF bytes to local file
      await file.writeAsBytes(bytes);
      
      // Return the local file path
      return file.path;
    } catch (e) {
      throw Exception('Failed to download session report for viewing: $e');
    }
  }

  /// Download PDF and return the local file path for viewing in app
  static Future<String> downloadReportForViewing(String reportId) async {
    try {
      final bytes = await downloadReportBytes(reportId);
      
      // Get temporary directory to store the PDF
      final directory = await getTemporaryDirectory();
      final fileName = 'session_analysis_report_$reportId.pdf';
      final file = File('${directory.path}/$fileName');
      
      // Write PDF bytes to local file
      await file.writeAsBytes(bytes);
      
      // Return the local file path
      return file.path;
    } catch (e) {
      throw Exception('Failed to download report for viewing: $e');
    }
  }
  
  /// Download PDF and save to device storage
  static Future<String> downloadReportToStorage(String reportId, {String? customFileName}) async {
    try {
      final bytes = await downloadReportBytes(reportId);
      
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
      
      final fileName = customFileName ?? 'session_analysis_report_$reportId.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to download report to storage: $e');
    }
  }

  /// Download session report and save to device storage
  static Future<String> downloadSessionReportToStorage({
    required String patientId,
    required int sessionId,
    String? customFileName,
  }) async {
    try {
      final bytes = await downloadSessionReportBytes(
        patientId: patientId,
        sessionId: sessionId,
      );
      
      // Try different directories based on platform availability
      Directory? directory;
      
      try {
        directory = await getDownloadsDirectory();
      } catch (e) {
        print('Downloads directory not available: $e');
      }
      
      directory ??= await getApplicationDocumentsDirectory();
      
      final fileName = customFileName ?? 'analysis_report_${patientId}_session_${sessionId}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to download session report to storage: $e');
    }
  }

  // ================================
  // LEGACY SUPPORT (DEPRECATED)
  // ================================

  /// Generate analysis report for a session (DEPRECATED - use generateAnalysisReport)
  @Deprecated('Use generateAnalysisReport instead')
  static Future<Map<String, dynamic>> generateReport({
    required String patientId,
    required int sessionId,
  }) async {
    print('Warning: generateReport is deprecated. Use generateAnalysisReport instead.');
    return await generateAnalysisReport(
      patientId: patientId,
      sessionId: sessionId,
    );
  }

  // ================================
  // REPORT URL OPERATIONS
  // ================================
  
  /// Get the direct download URL for a report
  static String getReportDownloadUrl(String reportId) {
    return ApiConstants.downloadReport(reportId);
  }

  /// Get the direct view URL for a report (for web viewing)
  static String getReportViewUrl(String fileId) {
    return ApiConstants.viewReport(fileId);
  }

  /// Get session report download URL
  static String getSessionReportDownloadUrl({
    required String patientId,
    required int sessionId,
  }) {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    return ApiConstants.downloadSessionReport(numericPatientId, sessionId);
  }

  // ================================
  // REPORT VALIDATION & UTILITIES
  // ================================

  /// Check if a report exists for a session
  static Future<bool> hasReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final metadata = await getReportMetadata(
        patientId: patientId,
        sessionId: sessionId,
      );
      return metadata['has_existing_report'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get existing report ID for a session
  static Future<String?> getExistingReportId({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final metadata = await getReportMetadata(
        patientId: patientId,
        sessionId: sessionId,
      );
      return metadata['existing_report_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check if session can generate a report
  static Future<bool> canGenerateReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final metadata = await getReportMetadata(
        patientId: patientId,
        sessionId: sessionId,
      );
      return metadata['can_generate_report'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get available data types for report generation
  static Future<Map<String, bool>> getAvailableDataTypes({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final metadata = await getReportMetadata(
        patientId: patientId,
        sessionId: sessionId,
      );
      final availableData = metadata['available_data'] as Map<String, dynamic>? ?? {};
      
      return {
        'fer_excel': availableData['fer_excel'] as bool? ?? false,
        'fer_images': availableData['fer_images'] as bool? ?? false,
        'speech_excel': availableData['speech_excel'] as bool? ?? false,
        'session_text': availableData['session_text'] as bool? ?? false,
      };
    } catch (e) {
      return {
        'fer_excel': false,
        'fer_images': false,
        'speech_excel': false,
        'session_text': false,
      };
    }
  }

  /// Get detailed analysis capabilities
  static Future<Map<String, dynamic>> getDetailedCapabilities({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final capabilities = await getAnalysisCapabilities(
        patientId: patientId,
        sessionId: sessionId,
      );
      
      final caps = capabilities['capabilities'] as Map<String, dynamic>? ?? {};
      final recommendation = capabilities['recommendation'] as Map<String, dynamic>? ?? {};
      
      return {
        'tov_only': {
          'available': caps['tov_only']?['available'] ?? false,
          'description': caps['tov_only']?['description'] ?? '',
          'prompt_type': 'tov_only_diagnostic_prompt',
        },
        'comprehensive': {
          'available': caps['comprehensive']?['available'] ?? false,
          'description': caps['comprehensive']?['description'] ?? '',
          'prompt_type': 'comprehensive_diagnostic_prompt',
        },
        'recommendation': {
          'type': recommendation['type'] ?? 'none',
          'reason': recommendation['reason'] ?? '',
        },
      };
    } catch (e) {
      return {
        'tov_only': {'available': false, 'description': '', 'prompt_type': ''},
        'comprehensive': {'available': false, 'description': '', 'prompt_type': ''},
        'recommendation': {'type': 'none', 'reason': 'Error retrieving capabilities'},
      };
    }
  }

  // ================================
  // DEBUG & TESTING
  // ================================

  /// Get debug information for report generation
  static Future<Map<String, dynamic>> getDebugInfo({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
      final url = Uri.parse(ApiConstants.debugReportData(numericPatientId, sessionId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['debug_info'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get debug info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get debug info: $e');
    }
  }

  /// Test prompt alignment and service status
  static Future<Map<String, dynamic>> testPrompts() async {
    try {
      final url = Uri.parse(ApiConstants.testReportPrompts);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to test prompts: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to test prompts: $e');
    }
  }

  // ================================
  // FILE MANAGEMENT UTILITIES
  // ================================

  /// Generate safe filename for report
  static String generateReportFileName({
    required String patientId,
    required int sessionId,
    String? customName,
    DateTime? timestamp,
    String? analysisType,
  }) {
    final time = timestamp ?? DateTime.now();
    final dateStr = '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    
    String prefix = 'report';
    if (analysisType != null) {
      switch (analysisType) {
        case 'tov_only':
          prefix = 'tov_analysis';
          break;
        case 'comprehensive':
          prefix = 'comprehensive_analysis';
          break;
        case 'enhanced_with_notes':
          prefix = 'enhanced_analysis';
          break;
      }
    }
    
    if (customName != null && customName.isNotEmpty) {
      return '${customName}_$dateStr.pdf';
    }
    
    return '${prefix}_${patientId}_session_${sessionId}_$dateStr.pdf';
  }

  /// Check if local report file exists
  static Future<bool> localReportExists(String reportId) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'session_analysis_report_$reportId.pdf';
      final file = File('${directory.path}/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Check if local session report exists
  static Future<bool> localSessionReportExists({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'session_report_${patientId}_${sessionId}.pdf';
      final file = File('${directory.path}/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get local report file path if it exists
  static Future<String?> getLocalReportPath(String reportId) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'session_analysis_report_$reportId.pdf';
      final file = File('${directory.path}/$fileName');
      
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get local session report path if it exists
  static Future<String?> getLocalSessionReportPath({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'session_report_${patientId}_${sessionId}.pdf';
      final file = File('${directory.path}/$fileName');
      
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear cached local reports
  static Future<void> clearLocalReports() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file is File && 
            (file.path.contains('session_analysis_report_') || 
             file.path.contains('session_report_'))) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Failed to clear local reports: $e');
    }
  }

  /// Get local report file size
  static Future<int?> getLocalReportSize(String reportId) async {
    try {
      final path = await getLocalReportPath(reportId);
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
  // CONVENIENCE METHODS
  // ================================

  /// Download or get cached report for viewing
  static Future<String> getReportForViewing(String reportId) async {
    // Check if already cached locally
    final localPath = await getLocalReportPath(reportId);
    if (localPath != null) {
      return localPath;
    }
    
    // Download if not cached
    return await downloadReportForViewing(reportId);
  }

  /// Download or get cached session report for viewing
  static Future<String> getSessionReportForViewing({
    required String patientId,
    required int sessionId,
  }) async {
    // Check if already cached locally
    final localPath = await getLocalSessionReportPath(
      patientId: patientId,
      sessionId: sessionId,
    );
    if (localPath != null) {
      return localPath;
    }
    
    // Download if not cached
    return await downloadSessionReportForViewing(
      patientId: patientId,
      sessionId: sessionId,
    );
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

  /// Validate report ID format
  static bool isValidReportId(String reportId) {
    // Basic validation for ObjectId format (24 hex characters)
    final regex = RegExp(r'^[0-9a-fA-F]{24}$');
    return regex.hasMatch(reportId);
  }

  /// Get report generation status description
  static String getReportStatusDescription(Map<String, dynamic> statusData) {
    final status = statusData['status'] as String? ?? 'unknown';
    final message = statusData['message'] as String? ?? '';
    
    switch (status) {
      case 'completed':
        return 'Report ready for download';
      case 'ready_to_generate':
        return 'Ready to generate report';
      case 'insufficient_data':
        return 'Insufficient data for report generation';
      default:
        return message.isNotEmpty ? message : 'Unknown status';
    }
  }

  /// Get analysis type description
  static String getAnalysisTypeDescription(String analysisType) {
  switch (analysisType) {
    case 'tov_only':
      return 'Text tone analysis with DSM-5/ICD-11 diagnostic insights';
    case 'comprehensive':
      return 'Combined facial expression and text tone analysis with mismatch detection';
    case 'enhanced_with_notes':
      return 'Enhanced analysis including doctor notes integration';
    case 'speech_with_notes':
      return 'Speech analysis enhanced with clinical notes';
    case 'comprehensive_with_notes':
      return 'Comprehensive analysis enhanced with clinical notes';
    case 'automatic':
      return 'Automatic analysis based on available data';
    default:
      return 'Unknown analysis type';
  }
}

  /// Get prompt type description
  static String getPromptTypeDescription(String promptType) {
    switch (promptType) {
      case 'tov_only_diagnostic_prompt':
        return 'TOV-only prompt from tov_wirhout_notes.ipynb';
      case 'comprehensive_diagnostic_prompt':
        return 'Comprehensive prompt from full_without_doctornotes_Apis.ipynb';
      case 'enhanced_with_notes_prompt':
        return 'Enhanced prompt with doctor notes integration';
      default:
        return 'Standard analysis prompt';
    }
  }

  /// Download PDF report and save to device storage (for user download)
  static Future<String> downloadReport(String reportId, {String? customFileName}) async {
    try {
      final bytes = await downloadReportBytes(reportId);
      
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
      
      final fileName = customFileName ?? 'session_analysis_report_$reportId.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to download report: $e');
    }
  }
}