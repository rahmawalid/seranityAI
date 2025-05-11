import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/doctor.dart';

import 'signup_uploads_screen.dart';

class SignupProfessionalScreen extends StatefulWidget {
  final PersonalInfo personalInfo;

  const SignupProfessionalScreen({
    Key? key,
    required this.personalInfo,
  }) : super(key: key);

  @override
  _SignupProfessionalScreenState createState() =>
      _SignupProfessionalScreenState();
}

class _SignupProfessionalScreenState extends State<SignupProfessionalScreen> {
  final _licenseController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _experienceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rewriteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Container(
                  width: 900,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.arrow_back,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Professional Info',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const Expanded(flex: 3, child: SizedBox()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField('Specialization',
                                'CBT, DBT, Psychodynamic Therapy etc...',
                                controller: _licenseController),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildField('License Number',
                                'Your license official number',
                                controller: _experienceController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField('Years of Experience',
                                'How many years of experience?',
                                controller: _workplaceController),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildField(
                                'Workplace', 'Clinic, Hospital, online etc.',
                                controller: _passwordController,
                                obscureText: false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField('Create Password',
                                '12 chars, upper & lower case, symbols',
                                controller: _passwordController,
                                obscureText: true),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildField(
                                'Rewrite Password', 'Rewrite password',
                                controller: _rewriteController,
                                obscureText: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Write to provider
                            // final provider = context.read<DoctorProvider>();
                            // provider.setProfessional(
                            //   license: _licenseController.text,
                            //   work: _workplaceController.text,
                            //   years: _experienceController.text,
                            //   pass: _passwordController.text,
                            // );
                            // Navigate to upload screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SignupUploadsScreen(
                                  // personal info carried forward via widget.<…>
                                  personalInfo: widget.personalInfo,
                                  // professional info
                                  licenseNumber: _licenseController.text,
                                  workplace: _workplaceController.text,
                                  yearsOfExp: _experienceController.text,
                                  password: _passwordController.text,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F3C58),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint, {
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}
