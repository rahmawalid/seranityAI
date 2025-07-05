import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/doctor_model.dart';
import 'login.dart';
import 'signup_professional_screen.dart';

class SignupPersonalScreen extends StatefulWidget {
  const SignupPersonalScreen({Key? key}) : super(key: key);

  @override
  _SignupPersonalScreenState createState() => _SignupPersonalScreenState();
}

class _SignupPersonalScreenState extends State<SignupPersonalScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  bool _emailValid = true;

  String _gender = 'Male';
  DateTime? _dob;
  String selectedRole = 'Doctor';

  bool get _isFormValid {
    final now = DateTime.now();
    final emailPattern =
        RegExp(r'^\S+@\S+\.\S+$'); // More flexible email pattern

    _emailValid = emailPattern.hasMatch(_emailCtrl.text.trim());

    return _nameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.trim().isNotEmpty &&
        _emailValid &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _dob != null &&
        _dob!.isBefore(
            now.subtract(const Duration(days: 365 * 18))); // 18 years minimum
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));

    // Add listeners to text controllers to trigger rebuilds when text changes
    _nameCtrl.addListener(() => setState(() {}));
    _emailCtrl.addListener(() => setState(() {}));
    _phoneCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 60, top: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/images/logo_white.png',
                              width: 48),
                          const SizedBox(height: 60),
                          const Text('Sign Up to SerenityAI',
                              style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 16),
                          const SizedBox(
                            width: 400,
                            child: Text(
                              'Revolutionizing therapy with AI—detecting emotions in real time to deliver deeper mental health insights. A smarter, more compassionate way to heal.',
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
                                        builder: (_) => const LoginScreen())),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border:
                                          Border.all(color: Color(0xFF5A6BFF)),
                                      borderRadius: BorderRadius.circular(24)),
                                  child: const Text('Log In',
                                      style: TextStyle(
                                          color: Color(0xFF5A6BFF),
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                    color: Color(0xFF5A6BFF),
                                    borderRadius: BorderRadius.circular(24)),
                                child: const Text('Sign Up',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text('Sign up as',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.black)),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedRole = 'Doctor'),
                                  child: _roleCard('Doctor',
                                      isSelected: selectedRole == 'Doctor')),
                              const SizedBox(width: 20),
                              GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedRole = 'User'),
                                  child: _roleCard('User',
                                      isSelected: selectedRole == 'User')),
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
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12.withOpacity(0.15),
                                blurRadius: 35,
                                offset: const Offset(0, 5))
                          ]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sign Up',
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          _buildField(
                              'Full Name', 'Please enter your full name',
                              controller: _nameCtrl),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _gender,
                                  onChanged: (v) =>
                                      setState(() => _gender = v!),
                                  items: ['Male', 'Female']
                                      .map((g) => DropdownMenuItem(
                                          value: g, child: Text(g)))
                                      .toList(),
                                  decoration: InputDecoration(
                                      labelText: 'Gender',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: _dob == null
                                        ? ''
                                        : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                                  ),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now());
                                    if (d != null) setState(() => _dob = d);
                                  },
                                  decoration: InputDecoration(
                                      labelText: 'Date of Birth',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildField('Email', 'Valid email address',
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              errorText: !_emailValid && _emailFocus.hasFocus
                                  ? 'Please enter a valid email address'
                                  : null),
                          const SizedBox(height: 16),
                          _buildField('Phone Number', 'Enter your phone number',
                              controller: _phoneCtrl, focusNode: _phoneFocus),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isFormValid
                                  ? () {
                                      final info = PersonalInfo(
                                        fullName: _nameCtrl.text.trim(),
                                        gender: _gender,
                                        dateOfBirth:
                                            '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                                        email: _emailCtrl.text.trim(),
                                        phoneNumber: _phoneCtrl.text.trim(),
                                        specialization:
                                            '', // Will be filled in next screen
                                      );
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  SignupProfessionalScreen(
                                                      personalInfo: info)));
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2F3C58),
                                  disabledBackgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text('Next'),
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

  Widget _buildField(String label, String hint,
      {required TextEditingController controller,
      FocusNode? focusNode,
      String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
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
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black)),
        ],
      ),
    );
  }
}
