import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/doctor_model.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';
import 'confirmation_screen.dart';

class SignupProfessionalScreen extends StatefulWidget {
  final PersonalInfo personalInfo;

  const SignupProfessionalScreen({
    Key? key,
    required this.personalInfo,
  }) : super(key: key);

  @override
  State<SignupProfessionalScreen> createState() => _SignupProfessionalScreenState();
}

class _SignupProfessionalScreenState extends State<SignupProfessionalScreen> {
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rewriteController = TextEditingController();

  // Focus nodes to track when fields are focused
  final _passwordFocus = FocusNode();
  final _rewriteFocus = FocusNode();

  // Track if fields have been focused at least once
  bool _passwordHasBeenFocused = false;
  bool _rewriteHasBeenFocused = false;

  bool _passwordHasUpper = false;
  bool _passwordHasLower = false;
  bool _passwordHasDigit = false;
  bool _passwordHasSpecial = false;
  bool _passwordHasMinLength = false;
  
  bool _isSubmitting = false; // Loading state

  bool get _isPasswordValid =>
      _passwordHasUpper &&
      _passwordHasLower &&
      _passwordHasDigit &&
      _passwordHasSpecial &&
      _passwordHasMinLength;

  bool get _passwordsMatch =>
      _passwordController.text == _rewriteController.text &&
      _rewriteController.text.isNotEmpty;

  bool get _isFormValid {
    return _specializationController.text.trim().isNotEmpty &&
        _licenseController.text.trim().isNotEmpty &&
        _experienceController.text.trim().isNotEmpty &&
        _workplaceController.text.trim().isNotEmpty &&
        _isPasswordValid &&
        _passwordsMatch;
  }

  @override
  void initState() {
    super.initState();
    _specializationController.addListener(_updateState);
    _licenseController.addListener(_updateState);
    _experienceController.addListener(_updateState);
    _workplaceController.addListener(_updateState);
    _passwordController.addListener(_updatePasswordChecks);
    _rewriteController.addListener(_updateState);

    // Add focus listeners to track when fields have been focused
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() {
          _passwordHasBeenFocused = true;
        });
      }
    });

    _rewriteFocus.addListener(() {
      if (_rewriteFocus.hasFocus) {
        setState(() {
          _rewriteHasBeenFocused = true;
        });
      }
    });
  }

  void _updateState() => setState(() {});

  void _updatePasswordChecks() {
    final password = _passwordController.text;
    setState(() {
      _passwordHasUpper = password.contains(RegExp(r'[A-Z]'));
      _passwordHasLower = password.contains(RegExp(r'[a-z]'));
      _passwordHasDigit = password.contains(RegExp(r'[0-9]'));
      _passwordHasSpecial = password.contains(RegExp(r'[!@#\\$%^&*(),.?":{}|<>]'));
      _passwordHasMinLength = password.length >= 8; // Changed to 8 to match backend
    });
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _workplaceController.dispose();
    _passwordController.dispose();
    _rewriteController.dispose();
    _passwordFocus.dispose();
    _rewriteFocus.dispose();
    super.dispose();
  }

  Widget _passwordRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(met ? Icons.check_circle : Icons.cancel,
            color: met ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(color: met ? Colors.green : Colors.red, fontSize: 12)),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create updated PersonalInfo with specialization
      final updatedPersonalInfo = PersonalInfo(
        fullName: widget.personalInfo.fullName,
        dateOfBirth: widget.personalInfo.dateOfBirth,
        gender: widget.personalInfo.gender,
        email: widget.personalInfo.email,
        phoneNumber: widget.personalInfo.phoneNumber,
        specialization: _specializationController.text.trim(),
        profilePicture: widget.personalInfo.profilePicture,
      );

      // Create Doctor object
      final doctor = Doctor(
        personalInfo: updatedPersonalInfo,
        licenseNumber: _licenseController.text.trim(),
        workplace: _workplaceController.text.trim(),
        yearsOfExperience: _experienceController.text.trim(),
        password: _passwordController.text,
        patientIDs: [],
        emailVerified: false,
      );

      // Create doctor account
      final doctorService = DoctorService();
      final doctorId = await doctorService.createDoctor(doctor);
      
      // Resend verification email
      await doctorService.resendVerificationEmail(widget.personalInfo.email);

      // Navigate to confirmation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            email: widget.personalInfo.email,
            doctorId: doctorId,
          ),
        ),
      );

    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 960 ? 960.0 : screenWidth * 0.85;

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
          Positioned(
            top: 40,
            left: 60,
            child: Image.asset('assets/images/logo_white.png', width: 48, height: 48),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Image.asset('assets/images/five_lenses.png', width: 400),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 60),
              child: Image.asset('assets/images/two_lenses.png', width: 300),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Container(
                  width: containerWidth,
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
                              backgroundColor: Color(0xFF2F3C58),
                              child: Icon(Icons.arrow_back, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Professional Info',
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
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
                              flex: 5,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2F3C58),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Specialization',
                              'CBT, DBT, Psychodynamic Therapy etc...',
                              controller: _specializationController,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildField(
                              'License Number',
                              'Your license official number',
                              controller: _licenseController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Years of Experience',
                              'How many years of experience do you have?',
                              controller: _experienceController,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildField(
                              'Workplace',
                              'Clinic, Hospital, online etc.',
                              controller: _workplaceController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildField(
                                  'Create Password',
                                  'At least 8 characters, upper & lower case, & symbols',
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  obscureText: true,
                                ),
                                const SizedBox(height: 10),
                                // Only show password requirements if the field has been focused
                                if (_passwordHasBeenFocused) ...[
                                  _passwordRequirement("At least 8 characters", _passwordHasMinLength),
                                  _passwordRequirement("At least one uppercase letter", _passwordHasUpper),
                                  _passwordRequirement("At least one lowercase letter", _passwordHasLower),
                                  _passwordRequirement("At least one number", _passwordHasDigit),
                                  _passwordRequirement("At least one special character", _passwordHasSpecial),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildField(
                                  'Rewrite Password',
                                  'Rewrite your password you just created',
                                  controller: _rewriteController,
                                  focusNode: _rewriteFocus,
                                  obscureText: true,
                                ),
                                const SizedBox(height: 10),
                                // Only show password match indicator if the rewrite field has been focused
                                if (_rewriteHasBeenFocused) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        _passwordsMatch ? Icons.check_circle : Icons.cancel,
                                        color: _passwordsMatch ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _passwordsMatch
                                            ? "Passwords match"
                                            : "Passwords do not match",
                                        style: TextStyle(
                                          color: _passwordsMatch ? Colors.green : Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isFormValid ? const Color(0xFF2F3C58) : Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isFormValid && !_isSubmitting ? _submitForm : null,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Submit',
                                  style: TextStyle(
                                    color: _isFormValid ? Colors.white : Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
    FocusNode? focusNode,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }
}