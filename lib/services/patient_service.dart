// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../constants/endpoints.dart';
import '../models/patient_model.dart';

class PatientService {
  // ================================
  // PATIENT CRUD OPERATIONS
  // ================================

  /// Create a new patient
  static Future<Patient> createPatient(Patient patient) async {
    final uri = Uri.parse(ApiConstants.createPatient);
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patient.toJson()),
    );

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return Patient.fromJson(data);
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Failed to create patient');
    }
  }

  /// Get patient by ID
  static Future<Patient> getPatientById(String patientId) async {
    // Convert string ID like "P1" to integer for backend
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.getPatientById(numericId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Patient.fromJson(data);
    } else {
      throw Exception(
          'Failed to load patient (${resp.statusCode}): ${resp.body}');
    }
  }

  /// Update patient information
  static Future<Patient> updatePatient(
      String patientId, Map<String, dynamic> updateData) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.updatePatient(numericId));
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Patient.fromJson(data['patient']);
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Failed to update patient');
    }
  }

  /// Delete patient
  static Future<bool> deletePatient(String patientId) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.deletePatient(numericId));
    final resp = await http.delete(uri);

    return resp.statusCode == 200;
  }

  /// List all patients
  static Future<List<Patient>> listPatients() async {
    final uri = Uri.parse(ApiConstants.listPatients);
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final List<dynamic> patientsList = data['patients'] as List<dynamic>;
      return patientsList
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load patients');
    }
  }

  /// List patients by doctor ID
  static Future<List<Patient>> listPatientsByDoctor(String doctorId) async {
    final uri = Uri.parse(ApiConstants.listPatientsByDoctor(doctorId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final List<dynamic> patientsList = data['patients'] as List<dynamic>;
      return patientsList
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load patients for doctor');
    }
  }

  // ================================
  // SESSION MANAGEMENT
  // ================================

  /// Create a new session for a patient
  static Future<Session> createSession(
      String patientId, Map<String, dynamic> sessionData) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.createSession(numericId));
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sessionData),
    );

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return Session.fromJson(data['session']);
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Failed to create session');
    }
  }

  /// Get session by ID
  static Future<Session> getSessionById(String patientId, int sessionId) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.getSessionById(numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Session.fromJson(data);
    } else {
      throw Exception('Failed to load session');
    }
  }

  // ================================
  // FILE UPLOAD OPERATIONS
  // ================================

  /// Internal helper for file uploads using bytes
  static Future<String> _upload({
    required String url,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse(url);
    final req = http.MultipartRequest('POST', uri);

    // Use correct field names based on endpoint type
    if (url.contains('upload-video') || url.contains('uploadSpeechVideo')) {
      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    } else if (url.contains('upload-audio')) {
      req.files.add(
        http.MultipartFile.fromBytes('audio', bytes, filename: filename),
      );
    } else if (url.contains('upload-report')) {
      req.files.add(
        http.MultipartFile.fromBytes('report', bytes, filename: filename),
      );
    } else {
      // Default fallback
      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(resp.body);
      if (body.containsKey('file_id')) {
        return body['file_id'] as String;
      } else {
        throw Exception(
            'Upload succeeded but no file_id returned: ${resp.body}');
      }
    } else {
      throw Exception('Upload failed (${resp.statusCode}): ${resp.body}');
    }
  }

  /// Upload audio file using bytes
  static Future<String> uploadAudio({
    required String patientId,
    required int sessionId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    return await _upload(
      url: ApiConstants.uploadAudio(numericId, sessionId),
      bytes: bytes,
      filename: filename,
    );
  }

  /// Upload video file using bytes
  static Future<String> uploadVideo({
    required String patientId,
    required int sessionId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    return await _upload(
      url: ApiConstants.uploadVideo(numericId, sessionId),
      bytes: bytes,
      filename: filename,
    );
  }

  /// Upload report file using bytes
  static Future<String> uploadReport({
    required String patientId,
    required int sessionId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    return await _upload(
      url: ApiConstants.uploadReport(numericId, sessionId),
      bytes: bytes,
      filename: filename,
    );
  }

  /// Upload audio file using File object
  static Future<String> uploadAudioFile({
    required String patientId,
    required int sessionId,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split('/').last;
    return await uploadAudio(
      patientId: patientId,
      sessionId: sessionId,
      bytes: bytes,
      filename: filename,
    );
  }

  /// Upload video file using File object
  static Future<String> uploadVideoFile({
    required String patientId,
    required int sessionId,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split('/').last;
    return await uploadVideo(
      patientId: patientId,
      sessionId: sessionId,
      bytes: bytes,
      filename: filename,
    );
  }

  // ================================
  // REPORT GENERATION
  // ================================

  /// Generate analysis report for a session
  static Future<Map<String, dynamic>> generateReport({
    required String patientId,
    required int sessionId,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.generateReport(numericId, sessionId));
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Failed to generate report');
    }
  }

  /// Get report metadata
  static Future<Map<String, dynamic>> getReportMetadata({
    required String patientId,
    required int sessionId,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.getReportMetadata(numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['metadata'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get report metadata');
    }
  }

  /// Get download URL for a report
  static String getReportDownloadUrl(String reportId) {
    return ApiConstants.downloadReport(reportId);
  }

  /// Get view URL for a report
  static String getReportViewUrl(String fileId) {
    return ApiConstants.viewReport(fileId);
  }

  // ================================
  // SPEECH & TRANSCRIPTION
  // ================================

  /// Upload video for speech analysis
  static Future<String> uploadSpeechVideo({
    required String patientId,
    required int sessionId,
    required File file,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final bytes = await file.readAsBytes();
    final filename = file.path.split('/').last;

    return await _upload(
      url: ApiConstants.uploadSpeechVideo(numericId, sessionId),
      bytes: bytes,
      filename: filename,
    );
  }

  /// Analyze speech and tone of voice
  static Future<Map<String, dynamic>> analyzeSpeechAndTov(
    String fileId,
    String patientId,
    int sessionId,
  ) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(
        ApiConstants.analyzeSpeechAndTov(fileId, numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Speech analysis failed');
    }
  }

  /// Get speech analysis status
  static Future<Map<String, dynamic>> getSpeechStatus({
    required String patientId,
    required int sessionId,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.getSpeechStatus(numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get speech analysis status');
    }
  }

  /// Get speech analysis results
  static Future<Map<String, dynamic>> getSpeechResults({
    required String patientId,
    required int sessionId,
  }) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.getSpeechResults(numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get speech analysis results');
    }
  }

  // ================================
  // ANALYSIS OPERATIONS
  // ================================

  /// Analyze FER (Facial Expression Recognition) and save results
  static Future<Map<String, dynamic>> analyzeFerAndSave(
    String fileId,
    String patientId,
    int sessionId,
  ) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri =
        Uri.parse(ApiConstants.ferAnalyzeAndSave(fileId, numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'FER analysis failed');
    }
  }

  // ================================
  // TRANSCRIPTION OPERATIONS
  // ================================

  /// Upload video for transcription
  static Future<Map<String, dynamic>> uploadTranscriptionVideo(
    String patientId,
    int sessionId,
    String fileId,
  ) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri =
        Uri.parse(ApiConstants.uploadTranscriptionVideo(numericId, sessionId));
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'file_id': fileId}),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to upload transcription video: ${resp.body}');
    }
  }

  /// Analyze and transcribe speech
  static Future<Map<String, dynamic>> analyzeAndTranscribe(
    String fileId,
    String patientId,
    int sessionId,
  ) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(
        ApiConstants.analyzeTranscription(fileId, numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to analyze and transcribe: ${resp.body}');
    }
  }

  /// Get transcription status
  static Future<Map<String, dynamic>> getTranscriptionStatus(
    String patientId,
    int sessionId,
  ) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri =
        Uri.parse(ApiConstants.transcriptionStatus(numericId, sessionId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get transcription status: ${resp.body}');
    }
  }

  /// Get patient transcriptions summary
  static Future<Map<String, dynamic>> getPatientTranscriptionsSummary(
      String patientId) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final uri = Uri.parse(ApiConstants.getTranscriptionsSummary(numericId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get transcriptions summary: ${resp.body}');
    }
  }

  // ================================
  // UTILITY METHODS
  // ================================

  /// Convert patient ID between formats
  static String formatPatientId(dynamic patientId) {
    if (patientId is String) {
      // If already formatted like "P1", return as is
      if (patientId.startsWith('P')) {
        return patientId;
      }
      // If numeric string, add P prefix
      return 'P$patientId';
    } else if (patientId is int) {
      // If integer, add P prefix
      return 'P$patientId';
    }
    return patientId.toString();
  }

  /// Extract numeric ID from patient ID
  static int getNumericPatientId(String patientId) {
    if (patientId.startsWith('P')) {
      return int.parse(patientId.substring(1));
    }
    return int.parse(patientId);
  }

  /// Validate patient data before submission
  static Map<String, String> validatePatientData(Patient patient) {
    final errors = <String, String>{};

    if (patient.personalInfo.fullName == null ||
        patient.personalInfo.fullName!.trim().isEmpty) {
      errors['fullName'] = 'Full name is required';
    }

    if (patient.personalInfo.contactInformation?.email != null) {
      final email = patient.personalInfo.contactInformation!.email!;
      if (email.isNotEmpty &&
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        errors['email'] = 'Invalid email format';
      }
    }

    return errors;
  }

  /// Get patient display name
  static String getDisplayName(Patient patient) {
    return patient.personalInfo.fullName ?? 'Unknown Patient';
  }

  /// Get patient age from date of birth
  static int? getAge(Patient patient) {
    if (patient.personalInfo.dateOfBirth == null) return null;

    try {
      final dob = DateTime.parse(patient.personalInfo.dateOfBirth!);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  /// Check if patient has sessions
  static bool hasSessions(Patient patient) {
    return patient.sessions.isNotEmpty;
  }

  /// Get latest session for patient
  static Session? getLatestSession(Patient patient) {
    if (patient.sessions.isEmpty) return null;

    // Sort by session_id (latest first)
    final sortedSessions = List<Session>.from(patient.sessions);
    sortedSessions
        .sort((a, b) => (b.sessionId ?? 0).compareTo(a.sessionId ?? 0));
    return sortedSessions.first;
  }

  /// Count sessions with specific feature data
  static int countSessionsWithFeature(Patient patient, String featureType) {
    return patient.sessions
        .where((session) => session.featureData?[featureType] != null)
        .length;
  }

  /// Get session analysis summary
  static Map<String, dynamic> getSessionAnalysisSummary(Session session) {
    final hasFer = session.featureData?['FER'] != null;
    final hasSpeech = session.featureData?['Speech'] != null;
    final hasDoctorNotes = session.doctorNotesImages?.isNotEmpty ?? false;
    final hasReport = session.report != null;
    final hasTranscription = session.transcription != null;

    return {
      'sessionId': session.sessionId,
      'date': session.date?.toIso8601String(),
      'hasFer': hasFer,
      'hasSpeech': hasSpeech,
      'hasDoctorNotes': hasDoctorNotes,
      'hasReport': hasReport,
      'hasTranscription': hasTranscription,
      'analysisType': _getAnalysisType(session),
      'completionPercentage': _calculateCompletionPercentage(session),
    };
  }

  /// Get analysis type for session (computed from session data)
  static String _getAnalysisType(Session session) {
    final hasDoctorNotes = session.doctorNotesImages?.isNotEmpty ?? false;
    final hasFer = session.featureData?['FER'] != null;
    final hasSpeech = session.featureData?['Speech'] != null;

    if (hasFer && hasDoctorNotes) return 'comprehensive_with_notes';
    if (hasSpeech && hasDoctorNotes) return 'speech_with_notes';
    if (hasFer) return 'comprehensive';
    if (hasSpeech) return 'speech_only';
    return 'basic';
  }

  /// Calculate session completion percentage
  static double _calculateCompletionPercentage(Session session) {
    int totalSteps = 4; // FER, Speech, Doctor Notes, Report
    int completedSteps = 0;

    if (session.featureData?['FER'] != null) completedSteps++;
    if (session.featureData?['Speech'] != null) completedSteps++;
    if (session.doctorNotesImages?.isNotEmpty ?? false) completedSteps++;
    if (session.report != null) completedSteps++;

    return (completedSteps / totalSteps) * 100;
  }
}
