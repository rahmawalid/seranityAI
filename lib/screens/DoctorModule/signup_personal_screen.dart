import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/doctor.dart';
import 'package:ui_screens_grad/screens/DoctorModule/login.dart';

import 'signup_professional_screen.dart';

class SignupPersonalScreen extends StatefulWidget {
  const SignupPersonalScreen({Key? key}) : super(key: key);

  @override
  _SignupPersonalScreenState createState() => _SignupPersonalScreenState();
}

class _SignupPersonalScreenState extends State<SignupPersonalScreen> {
  bool isSignup = true;
  String selectedRole = 'Doctor';
  String selectedGender = 'Male';
  DateTime? selectedDate;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

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
                    // ... existing decorative layout ...
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
                            'Revolutionizing therapy with AI',
                            style: TextStyle(fontSize: 22, color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: 400,
                            child: Text(
                              'Detecting emotions in real time to deliver deeper mental health insights. A smarter, more compassionate way to heal.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          SizedBox(height: 30),
                          // Toggle code here if needed
                        ],
                      ),
                    ),
                    const Positioned(
                      bottom: 40,
                      left: 60,
                      child: Row(
                        children: [
                          Text('Signup as',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                          SizedBox(width: 20),
                          // role cards...
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT SIDE FORM
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
                        // Header and toggle omitted for brevity
                        const Text('Sign Up',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        inputField('Full Name', 'Enter your full name',
                            controller: _nameController),
                        Row(
                          children: [
                            Expanded(child: _genderDropdown()),
                            const SizedBox(width: 10),
                            Expanded(child: _datePicker(context)),
                          ],
                        ),
                        inputField('Enter your Email', 'Email',
                            controller: _emailController),
                        inputField('Phone Number', 'Phone',
                            controller: _phoneController),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F3C58),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final selectedDateString = selectedDate == null
                                  ? ''
                                  : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';

                              // Write to provider
                              // final provider = context.read<DoctorProvider>();
                              // provider.setPersonal(
                              //   PersonalInfo(
                              //     fullName: _nameController.text,
                              //     dateOfBirth: selectedDateString,
                              //     gender: selectedGender,
                              //     email: _emailController.text,
                              //     phoneNumber: _phoneController.text,
                              //   ),
                              // );

                              PersonalInfo docInfo = PersonalInfo(
                                  fullName: _nameController.text,
                                  dateOfBirth: selectedDateString,
                                  gender: selectedGender,
                                  email: _emailController.text,
                                  phoneNumber: _phoneController.text,
                                  specialization: "");
                              // Navigate to professional screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignupProfessionalScreen(
                                      personalInfo: docInfo),
                                ),
                              );
                            },
                            child: const Text('Next'),
                          ),
                        ),
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
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text("Log In"),
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
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      onChanged: (value) => setState(() => selectedGender = value!),
      items: ['Male', 'Female']
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      decoration: const InputDecoration(
          border: OutlineInputBorder(), labelText: 'Gender'),
    );
  }

  Widget _datePicker(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(
          text: selectedDate == null
              ? ''
              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => selectedDate = date);
      },
      decoration: const InputDecoration(
          border: OutlineInputBorder(), labelText: 'Date Of Birth'),
    );
  }
}

Widget inputField(String label, String hint,
    {required TextEditingController controller}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    ),
  );
}
