import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';
import '../models/doctor_model.dart';
import '../models/patient_model.dart';

class DoctorService {
  // ================================
  // DOCTOR AUTHENTICATION
  // ================================

  /// Create a new doctor account
  Future<String> createDoctor(Doctor doctor) async {
    final uri = Uri.parse(ApiConstants.createDoctor);
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(doctor.toJson()),
    );

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data['doctor_ID'] as String;
    } else {
      try {
        final err = jsonDecode(resp.body);
        throw Exception(err['error'] ?? 'Unknown error creating doctor');
      } catch (_) {
        throw Exception('Server error (${resp.statusCode})');
      }
    }
  }

  /// Login doctor with email and password
  Future<Map<String, dynamic>> loginDoctor(
      String email, String password) async {
    final uri = Uri.parse(ApiConstants.loginDoctor);
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (resp.statusCode == 200) {
      // Backend returns 200 for login, not 201
      final data = jsonDecode(resp.body);
      return data;
    } else {
      try {
        final err = jsonDecode(resp.body);
        throw Exception(err['error'] ?? 'Unknown error during login');
      } catch (_) {
        throw Exception('Server error (${resp.statusCode})');
      }
    }
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    final uri = Uri.parse(ApiConstants.resendVerification);
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return resp.statusCode == 200;
  }

  /// Verify doctor email with token
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final uri = Uri.parse(ApiConstants.verifyEmail(token));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Email verification failed');
    }
  }

  /// Check token validity without verifying
  Future<Map<String, dynamic>> checkToken(String token) async {
    final uri = Uri.parse(ApiConstants.checkToken(token));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Failed to check token');
    }
  }

  // ================================
  // DOCTOR PROFILE MANAGEMENT
  // ================================

  /// Get doctor profile by ID
  Future<Doctor> getDoctor(String doctorId) async {
    final uri = Uri.parse(ApiConstants.getDoctor(doctorId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Doctor.fromJson(data);
    } else {
      throw Exception('Failed to load doctor profile');
    }
  }

  /// Update doctor information
  Future<Doctor> updateDoctorInfo(
      String doctorId, Map<String, dynamic> updateData) async {
    final uri = Uri.parse(ApiConstants.updateDoctorInfo(doctorId));
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return Doctor.fromJson(data);
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Failed to update doctor info');
    }
  }

  /// Update doctor password
  Future<bool> updateDoctorPassword(
      String doctorId, String currentPassword, String newPassword) async {
    final uri = Uri.parse(ApiConstants.updateDoctorPassword(doctorId));
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (resp.statusCode == 200) {
      return true;
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Failed to update password');
    }
  }

  /// Delete doctor account
  Future<bool> deleteDoctor(String doctorId) async {
    final uri = Uri.parse(ApiConstants.deleteDoctor(doctorId));
    final resp = await http.delete(uri);

    return resp.statusCode == 200;
  }

  // ================================
  // FILE UPLOADS
  // ================================

  /// Upload doctor file (profile picture or verification documents)
  Future<Map<String, dynamic>> uploadDoctorFile(
      String fileType, String doctorId, File file) async {
    final uri = Uri.parse(ApiConstants.uploadDoctorFile(fileType, doctorId));

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'File upload failed');
    }
  }

  /// Get verification file URL
  String getVerificationFileUrl(String fileType, String doctorId) {
    return ApiConstants.getVerificationFile(fileType, doctorId);
  }

  /// Get doctor profile picture URL
  String getDoctorProfilePictureUrl(String doctorId) {
    return ApiConstants.getDoctorProfilePicture(doctorId);
  }

  // ================================
  // PATIENT MANAGEMENT
  // ================================

  /// Get all patients for a doctor
  Future<List<Patient>> getPatientsForDoctor(String doctorId) async {
    final uri = Uri.parse(ApiConstants.doctorPatients(doctorId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      // Backend returns {patients: [...], doctor_ID: "", count: n}
      final List<dynamic> patientsList = data['patients'] as List<dynamic>;
      return patientsList
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load patients (${resp.statusCode}): ${resp.body}');
    }
  }

  /// Add a new patient for a doctor
  Future<Patient> addPatientForDoctor(String doctorId, Patient patient) async {
    final uri = Uri.parse(ApiConstants.addPatientForDoctor(doctorId));
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
      throw Exception(err['error'] ?? 'Error adding patient');
    }
  }

  // ================================
  // SESSION SCHEDULING
  // ================================

  /// Schedule a new session
  /// Schedule a new session
  Future<bool> scheduleSession({
    required String doctorId,
    required String patientId, // CHANGED: String instead of int
    required DateTime datetime,
    required String notes,
  }) async {
    final uri = Uri.parse(ApiConstants.scheduleSession(doctorId));
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientID': int.parse(patientId.replaceFirst('P', '')), // Convert "P1" to 1 for backend
        'datetime': datetime.toIso8601String(),
        'notes': notes,
      }),
    );

    if (resp.statusCode == 201) {
      return true;
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Failed to schedule session');
    }
  }

  /// Get all scheduled sessions for a doctor
  Future<List<ScheduledSession>> getScheduledSessions(String doctorId) async {
    final uri = Uri.parse(ApiConstants.getScheduledSessions(doctorId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      // Backend returns {sessions: [...], doctor_ID: "", count: n}
      final List<dynamic> sessionsList = data['sessions'] as List<dynamic>;
      return sessionsList
          .map((e) => ScheduledSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch sessions: ${resp.body}');
    }
  }

  // ================================
  // ANALYTICS
  // ================================

  /// Get doctor analytics
  Future<Map<String, dynamic>> getDoctorAnalytics(String doctorId) async {
    final uri = Uri.parse(ApiConstants.getDoctorAnalytics(doctorId));
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Failed to load analytics');
    }
  }

  // ================================
  // UTILITY METHODS
  // ================================

  /// Check if email is available (not in use)
  Future<bool> isEmailAvailable(String email) async {
    try {
      // Try to create a doctor with just email to test uniqueness
      // This is a simple check - you might want a dedicated endpoint
      final uri = Uri.parse(ApiConstants.createDoctor);
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personal_info': {'email': email},
          'license_number': 'test',
          'password': 'test'
        }),
      );

      // If we get a uniqueness error, email is taken
      if (resp.statusCode == 400) {
        final err = jsonDecode(resp.body);
        if (err['error'].toString().contains('email') ||
            err['error'].toString().contains('unique')) {
          return false;
        }
      }
      return true;
    } catch (e) {
      // If there's an error, assume email might be taken
      return false;
    }
  }

  /// Validate doctor data before submission
  Map<String, String> validateDoctorData(Doctor doctor) {
    final errors = <String, String>{};

    // Validate personal info
    if (doctor.personalInfo.fullName.trim().isEmpty) {
      errors['fullName'] = 'Full name is required';
    }

    if (doctor.personalInfo.email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(doctor.personalInfo.email)) {
      errors['email'] = 'Invalid email format';
    }

    if (doctor.personalInfo.phoneNumber.trim().isEmpty) {
      errors['phoneNumber'] = 'Phone number is required';
    }

    if (doctor.personalInfo.specialization.trim().isEmpty) {
      errors['specialization'] = 'Specialization is required';
    }

    if (doctor.licenseNumber.trim().isEmpty) {
      errors['licenseNumber'] = 'License number is required';
    }

    if (doctor.password.trim().isEmpty) {
      errors['password'] = 'Password is required';
    } else if (doctor.password.length < 8) {
      errors['password'] = 'Password must be at least 8 characters';
    }

    return errors;
  }

  /// Format doctor display name
  String getDisplayName(Doctor doctor) {
    return 'Dr. ${doctor.personalInfo.fullName}';
  }

  /// Get doctor specialization with formatting
  String getFormattedSpecialization(Doctor doctor) {
    return doctor.personalInfo.specialization.toUpperCase();
  }
}
