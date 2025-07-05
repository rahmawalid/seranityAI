// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/models/doctor_model.dart';
import 'package:ui_screens_grad/screens/DoctorModule/signup_personal_screen.dart';
import 'package:ui_screens_grad/screens/DoctorModule/doctor_main_layout.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = "Doctor";
  final _passController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isButtonEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, _) {
            return Row(
              children: [
                // LEFT SIDE
                Expanded(
                  flex: 3,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 60, top: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/logo_white.png',
                            width: 48,
                          ),
                          const SizedBox(height: 60),
                          const Text.rich(
                            TextSpan(
                              text: 'Login to ',
                              style: TextStyle(
                                  fontSize: 38,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: 'SerenityAI',
                                  style: TextStyle(
                                      fontSize: 38,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(
                            width: 400,
                            child: Text(
                              'Securely access SerenityAI to monitor sessions, manage patients, and gain AI-driven insights.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupPersonalScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Color(0xFF5A6BFF)),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                        color: Color(0xFF5A6BFF), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF5A6BFF),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Login as',
                              style: TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => selectedRole = "Doctor"),
                                child: _roleCard("Doctor", isSelected: selectedRole == "Doctor"),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () => setState(() => selectedRole = "User"),
                                child: _roleCard("User", isSelected: selectedRole == "User"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Container(
                      width: 540,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.15),
                            blurRadius: 35,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Welcome to ',
                                  children: [
                                    TextSpan(
                                      text: 'SerenityAI',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text("Don't have an Account?", style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text("Contact Us", style: TextStyle(fontSize: 12, color: Colors.blue)),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text("Login", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          inputField('Email Address', 'Enter your email', controller: _emailController),
                          inputField('Password', 'Enter your password', controller: _passController, obscureText: true),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A6BFF),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isButtonEnabled
                                  ? () async {
                                      setState(() => _isButtonEnabled = false);
                                      try {
                                        var resp = await DoctorService().loginDoctor(
                                          _emailController.text,
                                          _passController.text,
                                        );
                                        final doc = Doctor.fromJson(resp['doctor_info'] as Map<String, dynamic>);

                                        if (!doc.emailVerified) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Email Not Verified"),
                                              content: const Text("Please verify your email before logging in."),
                                              actions: [
                                                TextButton(
                                                  child: const Text("Resend Email"),
                                                  onPressed: () async {
                                                    await DoctorService().resendVerificationEmail(doc.personalInfo.email);
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                                TextButton(
                                                  child: const Text("OK"),
                                                  onPressed: () => Navigator.pop(context),
                                                ),
                                              ],
                                            ),
                                          );
                                          setState(() => _isButtonEnabled = true);
                                          return;
                                        }

                                        savePreferencesInfo(doc);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const UnifiedDoctorLayout(),
                                          ),
                                        );
                                      } catch (e) {
                                        setState(() => _isButtonEnabled = true);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Login failed: $e")),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text("Login", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _roleCard(String label, {bool isSelected = false}) {
    return Container(
      width: 110,
      height: 120,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFCEC7F2) : const Color(0xFFE9E1F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE0D9F8),
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget inputField(String label, String hint,
      {required TextEditingController controller, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}