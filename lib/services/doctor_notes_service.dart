// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../constants/endpoints.dart';
import '../models/doctor_notes_model.dart';
import '../models/patient_model.dart';

class DoctorNotesService extends ChangeNotifier {
  
  // ================================
  // STATE MANAGEMENT
  // ================================
  
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;
  
  // Data cache
  final Map<String, DoctorNotesList> _sessionNotes = <String, DoctorNotesList>{};
  final Map<String, AnalysisInfo> _analysisCapabilities = <String, AnalysisInfo>{};
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  String get uploadProgressPercent => '${(_uploadProgress * 100).toInt()}%';
  
  // ================================
  // PRIVATE HELPERS
  // ================================
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setUploading(bool uploading, [double progress = 0.0]) {
    _isUploading = uploading;
    _uploadProgress = progress;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    _isUploading = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  String _getCacheKey(String patientId, int sessionId) {
    return '${patientId}_$sessionId';
  }
  
  int _getNumericPatientId(String patientId) {
    // Convert "P1" to 1, or return as is if already numeric
    if (patientId.startsWith('P')) {
      return int.parse(patientId.substring(1));
    }
    return int.parse(patientId);
  }

  // ================================
  // FILE VALIDATION
  // ================================

  /// Validate files before upload - Updated to match backend validation
  List<FileValidationResult> validateFiles(List<File> files) {
    if (files.isEmpty) {
      return [
        const FileValidationResult(
          isValid: false,
          error: 'No files selected',
          filename: '',
        )
      ];
    }

    // Backend allows max 10 files per upload
    if (files.length > 10) {
      return [
        const FileValidationResult(
          isValid: false,
          error: 'Maximum 10 files allowed per upload',
          filename: '',
        )
      ];
    }

    return files.map((file) => FileValidationResult.validate(file)).toList();
  }

  /// Get only valid files from validation results
  List<File> getValidFiles(List<File> files, List<FileValidationResult> validationResults) {
    final validFiles = <File>[];
    for (int i = 0; i < files.length && i < validationResults.length; i++) {
      if (validationResults[i].isValid) {
        validFiles.add(files[i]);
      }
    }
    return validFiles;
  }

  /// Check if there are validation errors
  bool hasValidationErrors(List<FileValidationResult> results) {
    return results.any((result) => !result.isValid);
  }

  /// Get all validation error messages
  List<String> getValidationErrors(List<FileValidationResult> results) {
    return results
        .where((result) => !result.isValid)
        .map((result) => result.error ?? 'Unknown error')
        .toList();
  }

  /// Get file count summary for UI
  String getFileCountSummary(List<FileValidationResult> results) {
    final validCount = results.where((result) => result.isValid).length;
    final totalCount = results.length;
    return '$validCount of $totalCount files valid';
  }

  // ================================
  // UPLOAD OPERATIONS
  // ================================

  /// Upload multiple doctor notes files using File objects
  Future<ApiResponse<UploadResult>> uploadDoctorNotes({
    required String patientId,
    required int sessionId,
    required List<File> files,
  }) async {
    try {
      clearError();
      
      if (files.isEmpty) {
        return ApiResponse.error('No files selected');
      }
      
      // Validate files
      final validationResults = validateFiles(files);
      final invalidFiles = getValidationErrors(validationResults);
      
      if (invalidFiles.isNotEmpty) {
        final errors = invalidFiles.take(3).join(', ');
        return ApiResponse.error('Validation failed: $errors');
      }
      
      _setUploading(true, 0.0);
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.uploadDoctorNotes(numericId, sessionId));
      final request = http.MultipartRequest('POST', uri);
      
      // Add files with correct field name - backend expects 'doctor_notes'
      for (final file in files) {
        final multipartFile = await http.MultipartFile.fromPath(
          'doctor_notes', // Backend expects this field name
          file.path,
        );
        request.files.add(multipartFile);
      }
      
      // Send request
      final streamedResponse = await request.send();
      _setUploading(true, 1.0);
      
      final response = await http.Response.fromStream(streamedResponse);
      
      _setUploading(false);
      
      // Check if response body is empty
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      // Parse JSON
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        final error = 'Invalid JSON response: ${response.body}';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        final uploadResult = UploadResult.fromJson(responseData);
        
        // Invalidate cache to force refresh
        final cacheKey = _getCacheKey(patientId, sessionId);
        _sessionNotes.remove(cacheKey);
        _analysisCapabilities.remove(cacheKey);
        
        notifyListeners();
        return ApiResponse.success(uploadResult, message: responseData['message']);
      } else {
        final error = responseData['error'] ?? 'Upload failed (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setUploading(false);
      final error = 'Upload error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Upload multiple doctor notes using PlatformFile objects (for file_picker)
  Future<ApiResponse<UploadResult>> uploadDoctorNotesFromPlatformFiles({
    required String patientId,
    required int sessionId,
    required List<PlatformFile> files,
  }) async {
    try {
      clearError();
      
      if (files.isEmpty) {
        return ApiResponse.error('No files selected');
      }
      
      _setUploading(true, 0.0);
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.uploadDoctorNotes(numericId, sessionId));
      final request = http.MultipartRequest('POST', uri);
      
      // Add files with correct field name - backend expects 'doctor_notes'
      for (final file in files) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'doctor_notes', // Backend expects this field name
              file.bytes!,
              filename: file.name,
            ),
          );
        }
      }
      
      // Send request
      final streamedResponse = await request.send();
      _setUploading(true, 1.0);
      
      final response = await http.Response.fromStream(streamedResponse);
      
      _setUploading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        final uploadResult = UploadResult.fromJson(responseData);
        
        // Invalidate cache to force refresh
        final cacheKey = _getCacheKey(patientId, sessionId);
        _sessionNotes.remove(cacheKey);
        _analysisCapabilities.remove(cacheKey);
        
        notifyListeners();
        return ApiResponse.success(uploadResult, message: responseData['message']);
      } else {
        final error = responseData['error'] ?? 'Upload failed';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setUploading(false);
      final error = 'Upload error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Upload single doctor note using File object
  Future<ApiResponse<UploadResult>> uploadSingleDoctorNote({
    required String patientId,
    required int sessionId,
    required File file,
  }) async {
    try {
      clearError();
      
      _setUploading(true, 0.0);
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.uploadSingleDoctorNote(numericId, sessionId));
      final request = http.MultipartRequest('POST', uri);
      
      // Add single file with correct field name - backend expects 'doctor_note' for single upload
      final multipartFile = await http.MultipartFile.fromPath(
        'doctor_note', // Backend expects this field name for single upload
        file.path,
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      _setUploading(true, 1.0);
      
      final response = await http.Response.fromStream(streamedResponse);
      
      _setUploading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // For single file upload, create UploadResult from response
        final uploadResult = UploadResult(
          fileIds: [responseData['data']['file_id']],
          patientId: responseData['data']['patient_id'],
          sessionId: responseData['data']['session_id'],
          uploadedCount: 1,
        );
        
        // Invalidate cache to force refresh
        final cacheKey = _getCacheKey(patientId, sessionId);
        _sessionNotes.remove(cacheKey);
        _analysisCapabilities.remove(cacheKey);
        
        notifyListeners();
        return ApiResponse.success(uploadResult, message: responseData['message']);
      } else {
        final error = responseData['error'] ?? 'Upload failed';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setUploading(false);
      final error = 'Upload error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Upload single doctor note using bytes
  Future<ApiResponse<UploadResult>> uploadSingleDoctorNoteFromBytes({
    required String patientId,
    required int sessionId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final platformFile = PlatformFile(
      name: filename,
      size: bytes.length,
      bytes: bytes,
    );
    
    return await uploadDoctorNotesFromPlatformFiles(
      patientId: patientId,
      sessionId: sessionId,
      files: [platformFile],
    );
  }

  // ================================
  // RETRIEVAL OPERATIONS
  // ================================

  /// Get doctor notes for a session
  Future<ApiResponse<DoctorNotesList>> getDoctorNotes({
    required String patientId,
    required int sessionId,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = _getCacheKey(patientId, sessionId);
      
      // Return cached data if available and not forcing refresh
      if (!forceRefresh && _sessionNotes.containsKey(cacheKey)) {
        return ApiResponse.success(_sessionNotes[cacheKey]!);
      }
      
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.getDoctorNotes(numericId, sessionId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        final notesList = DoctorNotesList.fromJson(responseData);
        
        // Cache the result
        _sessionNotes[cacheKey] = notesList;
        
        return ApiResponse.success(notesList);
      } else {
        final error = responseData['error'] ?? 'Failed to get doctor notes';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Get notes error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Get patient doctor notes summary across all sessions
  Future<ApiResponse<PatientDoctorNotesSummary>> getPatientDoctorNotesSummary({
    required String patientId,
  }) async {
    try {
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.getPatientDoctorNotesSummary(numericId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        final summary = PatientDoctorNotesSummary.fromJson(responseData);
        return ApiResponse.success(summary);
      } else {
        final error = responseData['error'] ?? 'Failed to get summary';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Get summary error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  // ================================
  // DELETE OPERATIONS
  // ================================

  /// Delete a specific doctor note
  Future<ApiResponse<bool>> deleteDoctorNote({
    required String patientId,
    required int sessionId,
    required String fileId,
  }) async {
    try {
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.deleteDoctorNote(numericId, sessionId, fileId));
      final response = await http.delete(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Invalidate cache to force refresh
        final cacheKey = _getCacheKey(patientId, sessionId);
        _sessionNotes.remove(cacheKey);
        _analysisCapabilities.remove(cacheKey);
        
        notifyListeners();
        return ApiResponse.success(true, message: responseData['message']);
      } else {
        final error = responseData['error'] ?? 'Failed to delete doctor note';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Delete error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Clear all doctor notes from a session
  Future<ApiResponse<bool>> clearAllDoctorNotes({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.clearAllDoctorNotes(numericId, sessionId));
      final response = await http.delete(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Invalidate cache to force refresh
        final cacheKey = _getCacheKey(patientId, sessionId);
        _sessionNotes.remove(cacheKey);
        _analysisCapabilities.remove(cacheKey);
        
        notifyListeners();
        return ApiResponse.success(true, message: responseData['message']);
      } else {
        final error = responseData['error'] ?? 'Failed to clear doctor notes';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Clear error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  // ================================
  // ANALYSIS OPERATIONS
  // ================================

  /// Get analysis capabilities for a session
  Future<ApiResponse<AnalysisInfo>> getAnalysisCapabilities({
    required String patientId,
    required int sessionId,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = _getCacheKey(patientId, sessionId);
      
      // Return cached data if available and not forcing refresh
      if (!forceRefresh && _analysisCapabilities.containsKey(cacheKey)) {
        return ApiResponse.success(_analysisCapabilities[cacheKey]!);
      }
      
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.getAnalysisCapabilities(numericId, sessionId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        final analysisInfo = AnalysisInfo.fromJson(responseData);
        
        // Cache the result
        _analysisCapabilities[cacheKey] = analysisInfo;
        
        return ApiResponse.success(analysisInfo);
      } else {
        final error = responseData['error'] ?? 'Failed to get analysis capabilities';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Analysis capabilities error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Generate enhanced report with doctor notes - CORRECTED VERSION
Future<ApiResponse<EnhancedReportResult>> generateEnhancedReport({
  required String patientId,
  required int sessionId,
  String analysisType = 'auto',
}) async {
  try {
    _setLoading(true);
    clearError();
    
    final numericId = _getNumericPatientId(patientId);
    final uri = Uri.parse(ApiConstants.generateEnhancedReport(numericId, sessionId));
    
    // Critical debug logging
    print('🔍 DOCTOR NOTES ENDPOINT CHECK:');
    print('🔍 Endpoint: ${uri.toString()}');
    print('🔍 Expected: /api/doctor-notes/patient/$numericId/session/$sessionId/generate-enhanced-report');
    print('🔍 Patient ID: $patientId -> Numeric: $numericId');
    print('🔍 Session ID: $sessionId');
    print('🔍 Analysis Type: $analysisType');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'analysis_type': analysisType,
        'include_images': true,
      }),
    );
    
    _setLoading(false);
    
    print('🔍 Response Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');
    
    if (response.body.isEmpty) {
      final error = 'Server returned empty response (Status: ${response.statusCode})';
      _setError(error);
      return ApiResponse.error(error);
    }
    
    final responseData = json.decode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode == 200 && responseData['success'] == true) {
      final result = EnhancedReportResult.fromJson(responseData);
      
      // CRITICAL VERIFICATION
      print('🔍 VERIFICATION RESULTS:');
      print(result.verificationStatus);
      
      if (result.isValidDoctorNotesReport) {
        print('✅ DOCTOR NOTES ENDPOINT USED SUCCESSFULLY');
        print('✅ Analysis Type: ${result.analysisType}');
        print('✅ Prompt Used: ${result.promptUsed}');
        print('✅ Doctor Notes Count: ${result.doctorNotesCount}');
        print('✅ Images Included: ${result.imagesIncluded}');
      } else {
        print('❌ DOCTOR NOTES ENDPOINT NOT USED PROPERLY');
        print('❌ This appears to be a standard report, not enhanced');
        print('❌ Check backend logs for why enhancement failed');
      }
      
      return ApiResponse.success(result, message: responseData['message']);
    } else {
      final error = responseData['error'] ?? 'Failed to generate enhanced report';
      print('❌ Enhanced report generation failed: $error');
      _setError(error);
      return ApiResponse.error(error);
    }
    
  } catch (e) {
    _setLoading(false);
    final error = 'Generate report error: ${e.toString()}';
    print('❌ Exception during enhanced report generation: $error');
    _setError(error);
    return ApiResponse.error(error);
  }
}

  /// Check enhancement readiness for a session
  Future<ApiResponse<Map<String, dynamic>>> checkEnhancementReadiness({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.checkEnhancementReadiness(numericId, sessionId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        final error = responseData['error'] ?? 'Failed to check enhancement readiness';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Enhancement readiness error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Prepare analysis data for a session
  Future<ApiResponse<Map<String, dynamic>>> prepareAnalysisData({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.prepareAnalysisData(numericId, sessionId));
      final response = await http.post(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        final error = responseData['error'] ?? 'Failed to prepare analysis data';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Prepare analysis error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Integrate with existing report
  Future<ApiResponse<Map<String, dynamic>>> integrateWithExistingReport({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      _setLoading(true);
      clearError();
      
      final numericId = _getNumericPatientId(patientId);
      final uri = Uri.parse(ApiConstants.integrateWithExistingReport(numericId, sessionId));
      final response = await http.post(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        final error = responseData['error'] ?? 'Failed to integrate with existing report';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Integration error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  // ================================
  // VALIDATION OPERATIONS
  // ================================

  /// Validate files before upload using the backend endpoint
  Future<ApiResponse<Map<String, dynamic>>> validateDoctorNotesFiles({
    required List<PlatformFile> files,
  }) async {
    try {
      _setLoading(true);
      clearError();
      
      final uri = Uri.parse(ApiConstants.validateDoctorNotesFiles);
      final request = http.MultipartRequest('POST', uri);
      
      // Add files for validation
      for (final file in files) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'doctor_notes',
              file.bytes!,
              filename: file.name,
            ),
          );
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        final error = responseData['error'] ?? 'Validation failed';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Validation error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  // ================================
  // DOWNLOAD OPERATIONS
  // ================================

  /// Download a doctor note file
  Future<ApiResponse<List<int>>> downloadDoctorNote(String fileId) async {
    try {
      _setLoading(true);
      clearError();
      
      final uri = Uri.parse(ApiConstants.downloadDoctorNote(fileId));
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(response.bodyBytes);
      } else {
        final error = 'Failed to download doctor note (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
    } catch (e) {
      _setLoading(false);
      final error = 'Download error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Get download URL for a doctor note file
  String getDoctorNoteDownloadUrl(String fileId) {
    return ApiConstants.downloadDoctorNote(fileId);
  }

  // ================================
  // HEALTH CHECK OPERATIONS
  // ================================

  /// Check doctor notes service health
  Future<ApiResponse<Map<String, dynamic>>> checkServiceHealth() async {
    try {
      _setLoading(true);
      clearError();
      
      final uri = Uri.parse(ApiConstants.doctorNotesHealth);
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        final error = responseData['error'] ?? 'Health check failed';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Health check error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  /// Get supported formats from backend
  Future<ApiResponse<Map<String, dynamic>>> getSupportedFormats() async {
    try {
      _setLoading(true);
      clearError();
      
      final uri = Uri.parse(ApiConstants.doctorNotesSupportedFormats);
      final response = await http.get(uri);
      
      _setLoading(false);
      
      if (response.body.isEmpty) {
        final error = 'Server returned empty response (Status: ${response.statusCode})';
        _setError(error);
        return ApiResponse.error(error);
      }
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        final error = responseData['error'] ?? 'Failed to get supported formats';
        _setError(error);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      _setLoading(false);
      final error = 'Get formats error: ${e.toString()}';
      _setError(error);
      return ApiResponse.error(error);
    }
  }

  // ================================
  // CONVENIENCE METHODS
  // ================================

  /// Get cached doctor notes for a session (no API call)
  DoctorNotesList? getCachedDoctorNotes(String patientId, int sessionId) {
    final cacheKey = _getCacheKey(patientId, sessionId);
    return _sessionNotes[cacheKey];
  }

  /// Get cached analysis capabilities (no API call)
  AnalysisInfo? getCachedAnalysisCapabilities(String patientId, int sessionId) {
    final cacheKey = _getCacheKey(patientId, sessionId);
    return _analysisCapabilities[cacheKey];
  }

  /// Check if session has doctor notes (from cached data or session model)
  bool sessionHasDoctorNotes(Session session) {
    return session.hasDoctorNotes;
  }

  /// Get analysis type for session (from cached data or session model)
  String getSessionAnalysisType(Session session) {
    return session.analysisType;
  }

  /// Check if session has doctor notes (async version)
  Future<bool> hasDoctorNotes({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final result = await getDoctorNotes(
        patientId: patientId,
        sessionId: sessionId,
      );
      return result.success && (result.data?.hasNotes ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Get doctor notes count for a session
  Future<int> getDoctorNotesCount({
    required String patientId,
    required int sessionId,
  }) async {
    try {
      final result = await getDoctorNotes(
        patientId: patientId,
        sessionId: sessionId,
      );
      return result.data?.notesCount ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Refresh all data for a session
  Future<void> refreshSessionData({
    required String patientId,
    required int sessionId,
  }) async {
    // Clear cache
    final cacheKey = _getCacheKey(patientId, sessionId);
    _sessionNotes.remove(cacheKey);
    _analysisCapabilities.remove(cacheKey);

    // Fetch fresh data
    await Future.wait([
      getDoctorNotes(patientId: patientId, sessionId: sessionId, forceRefresh: true),
      getAnalysisCapabilities(patientId: patientId, sessionId: sessionId, forceRefresh: true),
    ]);
  }

  /// Clear all cached data
  void clearCache() {
    _sessionNotes.clear();
    _analysisCapabilities.clear();
    notifyListeners();
  }

  /// Clear cached data for specific session
  void clearSessionCache(String patientId, int sessionId) {
    final cacheKey = _getCacheKey(patientId, sessionId);
    _sessionNotes.remove(cacheKey);
    _analysisCapabilities.remove(cacheKey);
    notifyListeners();
  }

  // ================================
  // UI HELPER METHODS
  // ================================

  /// Format analysis type for display
  String formatAnalysisType(String analysisType) {
    switch (analysisType) {
      case 'comprehensive_with_notes':
        return 'Full Analysis + Doctor Notes';
      case 'speech_with_notes':
        return 'Speech Analysis + Doctor Notes';
      case 'comprehensive':
        return 'Full Analysis';
      case 'speech_only':
        return 'Speech Only';
      case 'basic':
        return 'Basic Analysis';
      case 'notes_only':
        return 'Doctor Notes Only';
      default:
        return 'Unknown';
    }
  }

  /// Get recommended next steps for a session
  List<String> getRecommendedNextSteps(Session session) {
    final recommendations = <String>[];

    if (!session.hasDoctorNotes) {
      recommendations.add('Upload doctor notes for enhanced analysis');
    }

    final hasFer = session.featureData?['FER'] != null;
    final hasSpeech = session.featureData?['Speech'] != null;

    if (!hasFer) {
      recommendations.add('Add facial expression analysis');
    }

    if (!hasSpeech) {
      recommendations.add('Add speech/audio analysis');
    }

    if (session.hasDoctorNotes && (hasFer || hasSpeech)) {
      recommendations.add('Ready for enhanced analysis');
    }

    return recommendations;
  }

  /// Get supported file formats (local version - matches backend validation)
  SupportedFormats doctorNotesSupportedFormats() {
    return const SupportedFormats(
      images: ['jpg', 'jpeg', 'png', 'bmp', 'tiff', 'webp'], // Changed from 'extensions' to 'images'
      maxFileSizeMb: 10,
      maxFilesPerUpload: 10,
      recommendedFormats: ['jpg', 'png'],
    );
  }

  /// Get analysis readiness level for a session
  String getAnalysisReadinessLevel(Session session) {
    final hasNotes = session.hasDoctorNotes;
    final hasFer = session.featureData?['FER'] != null;
    final hasSpeech = session.featureData?['Speech'] != null;

    if (hasNotes && hasFer && hasSpeech) {
      return 'excellent';
    } else if (hasNotes && (hasFer || hasSpeech)) {
      return 'good';
    } else if (hasFer || hasSpeech) {
      return 'fair';
    } else if (hasNotes) {
      return 'basic';
    } else {
      return 'insufficient';
    }
  }

  /// Get analysis readiness description
  String getAnalysisReadinessDescription(String level) {
    switch (level) {
      case 'excellent':
        return 'All analysis types available - doctor notes, FER, and speech data present';
      case 'good':
        return 'Enhanced analysis available - doctor notes with either FER or speech data';
      case 'fair':
        return 'Standard analysis available - FER or speech data present';
      case 'basic':
        return 'Limited analysis available - only doctor notes present';
      case 'insufficient':
        return 'No analysis data available - upload files to begin analysis';
      default:
        return 'Unknown readiness level';
    }
  }

  /// Get session data availability summary
  Map<String, bool> getSessionDataAvailability(Session session) {
    return {
      'has_doctor_notes': session.hasDoctorNotes,
      'has_fer': session.featureData?['FER'] != null,
      'has_speech': session.featureData?['Speech'] != null,
      'has_transcription': session.featureData?['Transcription'] != null,
    };
  }

  /// Check if session is ready for comprehensive analysis
  bool isSessionReadyForComprehensiveAnalysis(Session session) {
    final hasNotes = session.hasDoctorNotes;
    final hasFer = session.featureData?['FER'] != null;
    final hasSpeech = session.featureData?['Speech'] != null;
    
    return hasNotes && hasFer && hasSpeech;
  }

  /// Check if session is ready for enhanced analysis
  bool isSessionReadyForEnhancedAnalysis(Session session) {
    final hasNotes = session.hasDoctorNotes;
    final hasFer = session.featureData?['FER'] != null;
    final hasSpeech = session.featureData?['Speech'] != null;
    
    return hasNotes && (hasFer || hasSpeech);
  }

  /// Get upload status summary
  Map<String, dynamic> getUploadStatusSummary() {
    return {
      'is_uploading': _isUploading,
      'progress': _uploadProgress,
      'progress_percent': uploadProgressPercent,
      'has_error': _error != null,
      'error_message': _error,
      'is_loading': _isLoading,
    };
  }

  /// Get session analysis recommendations
  List<String> getSessionAnalysisRecommendations(Session session) {
    final recommendations = <String>[];
    final hasNotes = session.hasDoctorNotes;
    final hasFer = session.featureData?['FER'] != null;
    final hasSpeech = session.featureData?['Speech'] != null;

    if (!hasNotes && !hasFer && !hasSpeech) {
      recommendations.add('Start by uploading doctor notes or analysis files');
    } else if (hasNotes && !hasFer && !hasSpeech) {
      recommendations.add('Add FER or speech analysis for comprehensive insights');
    } else if (!hasNotes && (hasFer || hasSpeech)) {
      recommendations.add('Upload doctor notes to enhance analysis quality');
    } else if (hasNotes && hasFer && !hasSpeech) {
      recommendations.add('Add speech analysis for complete multimodal analysis');
    } else if (hasNotes && !hasFer && hasSpeech) {
      recommendations.add('Add facial expression analysis for complete insights');
    } else {
      recommendations.add('All data types available - ready for comprehensive analysis');
    }

    return recommendations;
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }

  /// Verify session is ready for enhanced report generation
Future<ApiResponse<Map<String, dynamic>>> verifySessionForEnhancedReport({
  required String patientId,
  required int sessionId,
}) async {
  try {
    print('🔍 VERIFYING SESSION FOR ENHANCED REPORT...');
    
    // Step 1: Check if doctor notes exist
    final notesResult = await getDoctorNotes(
      patientId: patientId,
      sessionId: sessionId,
    );
    
    if (!notesResult.success) {
      return ApiResponse.error('Failed to check doctor notes: ${notesResult.error}');
    }
    
    final notesList = notesResult.data!;
    print('🔍 Doctor Notes Status:');
    print('   - Has Notes: ${notesList.hasNotes}');
    print('   - Notes Count: ${notesList.notesCount}');
    
    if (!notesList.hasNotes || notesList.notesCount == 0) {
      return ApiResponse.error('No doctor notes found. Upload doctor notes first.');
    }
    
    // Step 2: Check enhancement readiness
    final readinessResult = await checkEnhancementReadiness(
      patientId: patientId,
      sessionId: sessionId,
    );
    
    if (!readinessResult.success) {
      return ApiResponse.error('Enhancement readiness check failed: ${readinessResult.error}');
    }
    
    print('🔍 Enhancement Readiness: ${readinessResult.data}');
    
    // Step 3: Check analysis capabilities
    final capabilitiesResult = await getAnalysisCapabilities(
      patientId: patientId,
      sessionId: sessionId,
    );
    
    if (!capabilitiesResult.success) {
      return ApiResponse.error('Analysis capabilities check failed: ${capabilitiesResult.error}');
    }
    
    final capabilities = capabilitiesResult.data!;
    print('🔍 Analysis Capabilities:');
    print('   - Analysis Type: ${capabilities.analysisType}');
    print('   - Prompt Type: ${capabilities.promptType}');
    print('   - Has FER: ${capabilities.hasFer}');
    print('   - Has Speech: ${capabilities.hasSpeech}');
    print('   - Has Doctor Notes: ${capabilities.hasDoctorNotes}');
    print('   - Doctor Notes Count: ${capabilities.doctorNotesCount}');
    
    // Verify analysis type includes doctor notes
    if (!capabilities.analysisType.contains('_with_notes')) {
      return ApiResponse.error('Analysis type does not include doctor notes: ${capabilities.analysisType}');
    }
    
    // All checks passed
    return ApiResponse.success({
      'ready': true,
      'notes_count': notesList.notesCount,
      'analysis_type': capabilities.analysisType,
      'prompt_type': capabilities.promptType,
      'expected_prompt': capabilities.analysisType == 'comprehensive_with_notes' 
          ? 'FER + TOV + Doctor Notes' 
          : 'TOV + Doctor Notes',
    });
    
  } catch (e) {
    return ApiResponse.error('Verification error: ${e.toString()}');
  }
}


}