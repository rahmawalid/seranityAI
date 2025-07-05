import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/screens/DoctorModule/doctor_main_layout.dart';
import 'package:ui_screens_grad/screens/DoctorModule/signup_personal_screen.dart';
import 'package:ui_screens_grad/models/doctor_model.dart';
import 'package:ui_screens_grad/services/doctor_notes_service.dart'; // Add this import

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

    return MultiProvider(
      providers: [
        // Doctor Notes Service Provider
        ChangeNotifierProvider(
          create: (_) => DoctorNotesService(),
        ),
        // Add other providers here if you have them
        // Example:
        // ChangeNotifierProvider(create: (_) => SomeOtherService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: doctor != null
            ? const UnifiedDoctorLayout() // Updated to use the new unified layout
            : const SignupPersonalScreen(),
      ),
    );
  }
}
