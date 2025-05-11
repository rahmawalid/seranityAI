import 'package:flutter/material.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/screens/DoctorModule/home.dart';

import 'screens/DoctorModule/signup_personal_screen.dart';
import 'models/doctor.dart';

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Doctor? doctor;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    final stored = await getUserPreferencesInfo();

    setState(() {
      doctor = stored;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: doctor != null
          ? const DoctorHomePage()
          : const SignupPersonalScreen(),
    );
  }
}
