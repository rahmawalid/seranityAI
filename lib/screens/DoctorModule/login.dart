// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/models/doctor.dart';
import 'package:ui_screens_grad/screens/DoctorModule/signup_personal_screen.dart';
import 'package:ui_screens_grad/screens/DoctorModule/home.dart'; // home.dart = DoctorHomePage
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // LEFT SIDE
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFBEA9F9), Color(0xFFB4E5F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 80,
                      left: 60,
                      child: Image.asset('assets/images/five_lenses.png',
                          width: 460),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Image.asset('assets/images/two_lenses.png',
                          width: 300),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 60, top: 160),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign Up to',
                            style: TextStyle(
                              fontSize: 38,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Lorem Ipsum is simply',
                            style: TextStyle(fontSize: 22, color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: 400,
                            child: Text(
                              'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry’s standard dummy text ever since the 1500s.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 60,
                      child: Row(
                        children: [
                          const Text('Login as',
                              style:
                              TextStyle(fontSize: 18, color: Colors.white)),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () =>
                                setState(() => selectedRole = "Doctor"),
                            child: _roleCard("Doctor",
                                isSelected: selectedRole == "Doctor"),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => setState(() => selectedRole = "User"),
                            child: _roleCard("User",
                                isSelected: selectedRole == "User"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT SIDE
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
                          spreadRadius: 0,
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
                                    text: 'LOREM',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text("Don't have an Account?",
                                    style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  "Contact Us",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blue),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Login",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        inputField('Email Address', 'Enter your email',
                            controller: _emailController),
                        inputField('Password', 'Enter your password',
                            controller: _passController),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F3C58),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              var loginResponse = await DoctorService()
                                  .loginDoctor(_emailController.text,
                                  _passController.text);
                              String docId =
                              loginResponse['doctor_ID'].toString();
                              final Map<String, dynamic> doctorMap =
                              loginResponse['doctor_info']
                              as Map<String, dynamic>;

                              if (docId != "error") {
                                final Doctor doctor =
                                Doctor.fromJson(doctorMap);
                                savePreferencesInfo(doctor);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const DoctorHomePage(), // ✅ fixed
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Invalid credentials"),
                                  ),
                                );
                              }
                            },
                            child: const Text("Login"), // 🔄 optional fix
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
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
}
