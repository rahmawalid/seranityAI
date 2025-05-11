import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ui_screens_grad/models/patient.dart';

import '../constants/endpoints.dart';
import '../models/doctor.dart';

class DoctorService {
  Future<String> createDoctor(Doctor doctor) async {
    final uri = Uri.parse(ApiConstants.createDoctor);
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(doctor.toJson()),
    );
    print('Response: ${resp.body}');
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      print('Doctor ID: ${data['doctor_ID']}');
      return data['doctor_ID'] as String;
    } else {
      try {
        final err = jsonDecode(resp.body);
        print(err);
        throw Exception(err['error'] ?? 'Unknown error creating doctor');
      } catch (_) {
        throw Exception('Server error (${resp.statusCode})');
      }
    }
  }

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
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data;
    } else {
      try {
        final err = jsonDecode(resp.body);
        throw Exception(err['error'] ?? 'Unknown error creating doctor');
      } catch (_) {
        throw Exception('Server error (${resp.statusCode})');
      }
    }
  }

  Future<List<Patient>> getPatientsForDoctor(String doctorID) async {
    final uri = Uri.parse(ApiConstants.doctorPatients(doctorID));
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final List<dynamic> list = jsonDecode(resp.body) as List<dynamic>;
      return list
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load patients (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<Patient> addPatientForDoctor(String doctorID, Patient patient) async {
    final uri = Uri.parse(ApiConstants.doctorPatients(doctorID));
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patient.toJson()),
    );
    if (resp.statusCode == 201) {
      final Map<String, dynamic> data =
          jsonDecode(resp.body) as Map<String, dynamic>;
      return Patient.fromJson(data);
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Error adding patient');
    }
  }
}
