import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_screens_grad/models/doctor_model.dart';

Future<void> savePreferencesInfo(Doctor doctorInfo) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final userPreferencesInfoJson = json.encode(doctorInfo.toJson());
  await prefs.setString('doctorInfo', userPreferencesInfoJson);
}

Future<Doctor?> getUserPreferencesInfo() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final doctorInfo = prefs.getString('doctorInfo');

  if (doctorInfo != null) {
    final userPreference = Doctor.fromJson(json.decode(doctorInfo));
    return userPreference;
  }
  return null;
}
