import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';
import '../models/patient_model.dart';

class PatientDataService {
  // ================================
  // PATIENT CRUD OPERATIONS
  // ================================

  static Future<String> createPatient(Patient patient) async {
    final url = Uri.parse(ApiConstants.createPatient);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patient.toJson()),
    );
    
    print('Create Patient Response Status: ${response.statusCode}');
    print('Create Patient Response Body: ${response.body}');
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('Parsed response data: $data');
      
      // Handle different response formats
      if (data is Map<String, dynamic>) {
        return data['patientID'] as String? ?? data['patient_id'] as String? ?? 'Unknown';
      } else if (data is String) {
        return data;
      } else {
        throw Exception('Unexpected response format: $data');
      }
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to create patient: ${response.body}');
      } catch (e) {
        throw Exception('Failed to create patient: ${response.body}');
      }
    }
  }

  static Future<Patient> getPatientById(String patientId) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.getPatientById(numericId));
    final response = await http.get(url);

    print('Get Patient Response Status: ${response.statusCode}');
    print('Get Patient Response Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        print('Parsed patient data: $data');
        
        // Handle different response formats
        Map<String, dynamic> patientData;
        if (data is Map<String, dynamic>) {
          // If the response has a 'patient' key, use that
          if (data.containsKey('patient')) {
            patientData = data['patient'] as Map<String, dynamic>;
          } else {
            patientData = data;
          }
        } else {
          throw Exception('Invalid response format: expected Map, got ${data.runtimeType}');
        }
        
        final patient = Patient.fromJson(patientData);
        return patient;
      } catch (e) {
        print('Error parsing patient data: $e');
        throw Exception('Failed to parse patient data: $e');
      }
    } else {
      throw Exception('Patient not found: ${response.body}');
    }
  }

  static Future<Patient> updatePatient(String patientId, Map<String, dynamic> updates) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.updatePatient(numericId));
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
    
    print('Update Patient Response Status: ${response.statusCode}');
    print('Update Patient Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        Map<String, dynamic> patientData;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('patient')) {
            patientData = data['patient'] as Map<String, dynamic>;
          } else {
            patientData = data;
          }
        } else {
          throw Exception('Invalid response format: expected Map, got ${data.runtimeType}');
        }
        
        return Patient.fromJson(patientData);
      } catch (e) {
        print('Error parsing updated patient data: $e');
        throw Exception('Failed to parse updated patient data: $e');
      }
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to update patient: ${response.body}');
      } catch (e) {
        throw Exception('Failed to update patient: ${response.body}');
      }
    }
  }

  static Future<void> deletePatient(String patientId) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.deletePatient(numericId));
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to delete patient: ${response.body}');
      } catch (e) {
        throw Exception('Failed to delete patient: ${response.body}');
      }
    }
  }

  static Future<List<Patient>> listPatients() async {
    final url = Uri.parse(ApiConstants.listPatients);
    final response = await http.get(url);

    print('List Patients Response Status: ${response.statusCode}');
    print('List Patients Response Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        List<dynamic> patientsData;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('patients')) {
            patientsData = data['patients'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            patientsData = data['data'] as List<dynamic>;
          } else {
            throw Exception('No patients array found in response');
          }
        } else if (data is List<dynamic>) {
          patientsData = data;
        } else {
          throw Exception('Invalid response format: expected Map or List, got ${data.runtimeType}');
        }
        
        final patients = <Patient>[];
        for (final item in patientsData) {
          if (item is Map<String, dynamic>) {
            try {
              patients.add(Patient.fromJson(item));
            } catch (e) {
              print('Warning: Failed to parse patient: $e');
              // Skip invalid patients instead of failing completely
            }
          }
        }
        
        return patients;
      } catch (e) {
        print('Error parsing patients list: $e');
        throw Exception('Failed to parse patients list: $e');
      }
    } else {
      throw Exception('Failed to load patients: ${response.body}');
    }
  }

  // ================================
  // UTILITY METHODS
  // ================================
  
  static String formatPatientId(dynamic patientId) {
    if (patientId is String && patientId.startsWith('P')) return patientId;
    return 'P$patientId';
  }

  static int getNumericPatientId(String patientId) {
    return int.parse(patientId.replaceFirst('P', ''));
  }

  static Future<List<Patient>> listPatientsByDoctor(String doctorId) async {
    final url = Uri.parse(ApiConstants.listPatientsByDoctor(doctorId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> patientsList = data['patients'] as List<dynamic>;
      return patientsList.map((json) => Patient.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch patients for doctor: ${response.body}');
    }
  }

  // ================================
  // SESSION MANAGEMENT
  // ================================

  static Future<Session> createSession(String patientId, Map<String, dynamic> sessionData) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.createSession(numericId));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sessionData),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Session.fromJson(data['session'] as Map<String, dynamic>);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to create session: ${response.body}');
    }
  }

  static Future<Session> getSessionById(String patientId, int sessionId) async {
    final numericId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.getSessionById(numericId, sessionId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Session.fromJson(data);
    } else {
      throw Exception('Failed to get session: ${response.body}');
    }
  }

  // ================================
  // ANALYSIS OPERATIONS
  // ================================

  static Future<Map<String, dynamic>> analyzeFerAndSave(String fileId, String patientId, int sessionId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.ferAnalyzeAndSave(fileId, numericPatientId, sessionId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('FER analysis failed: ${response.body}');
    }
  }

  static Future<String> analyzeTOVAndSave(String fileId, String patientId, int sessionId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.analyzeSpeechAndTov(fileId, numericPatientId, sessionId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['report_id']?.toString() ?? '';
    } else {
      throw Exception('Speech/TOV analysis failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> analyzeSpeechAndTov(String fileId, String patientId, int sessionId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.analyzeSpeechAndTov(fileId, numericPatientId, sessionId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Speech/TOV analysis failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getSpeechStatus(String patientId, int sessionId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.getSpeechStatus(numericPatientId, sessionId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get speech status: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getSpeechResults(String patientId, int sessionId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.getSpeechResults(numericPatientId, sessionId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get speech results: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> generateReport(String patientId, int sessionId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.generateReport(numericPatientId, sessionId));
    final response = await http.post(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to generate report: ${response.body}');
    }
  }

  static Future<List<int>> downloadReport(String reportId) async {
    final url = Uri.parse(ApiConstants.downloadReport(reportId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download report: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getReportMetadata(String patientId, int sessionId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.getReportMetadata(numericPatientId, sessionId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get report metadata: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getTranscriptionsSummary(String patientId) async {
    final numericPatientId = int.parse(patientId.replaceFirst('P', ''));
    final url = Uri.parse(ApiConstants.getTranscriptionsSummary(numericPatientId));
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get transcriptions summary: ${response.body}');
    }
  }

  // ================================
  // UTILITY METHODS
  // ================================


  static Map<String, String> validatePatientData(Patient patient) {
    final errors = <String, String>{};
    if (patient.personalInfo.fullName == null || patient.personalInfo.fullName!.trim().isEmpty) {
      errors['fullName'] = 'Full name is required';
    }
    final email = patient.personalInfo.contactInformation?.email;
    if (email != null && email.isNotEmpty &&
        !RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors['email'] = 'Invalid email format';
    }
    return errors;
  }

  static String getDisplayName(Patient patient) {
    return patient.personalInfo.fullName ?? 'Unknown Patient';
  }

  static int? getAge(Patient patient) {
    if (patient.personalInfo.dateOfBirth == null) return null;
    try {
      final dob = DateTime.parse(patient.personalInfo.dateOfBirth!);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  static bool hasSessions(Patient patient) {
    return patient.sessions.isNotEmpty;
  }

  static Session? getLatestSession(Patient patient) {
    if (patient.sessions.isEmpty) return null;
    final sorted = List<Session>.from(patient.sessions)
      ..sort((a, b) => (b.sessionId ?? 0).compareTo(a.sessionId ?? 0));
    return sorted.first;
  }

  static int countSessionsWithFeature(Patient patient, String featureType) {
    return patient.sessions.where((s) => s.featureData?[featureType] != null).length;
  }

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

  static double _calculateCompletionPercentage(Session session) {
    int total = 4;
    int completed = 0;
    if (session.featureData?['FER'] != null) completed++;
    if (session.featureData?['Speech'] != null) completed++;
    if (session.doctorNotesImages?.isNotEmpty ?? false) completed++;
    if (session.report != null) completed++;
    return (completed / total) * 100;
  }
}
