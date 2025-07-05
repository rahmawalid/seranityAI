import 'package:flutter/material.dart';
import 'package:ui_screens_grad/screens/DoctorModule/add_new_patient_2.dart';

class AddNewPatientScreen extends StatefulWidget {
  const AddNewPatientScreen({super.key});

  @override
  State<AddNewPatientScreen> createState() => _AddNewPatientScreenState();
}

class _AddNewPatientScreenState extends State<AddNewPatientScreen> {
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _occupationController = TextEditingController();
  final _emailController = TextEditingController();
  String _gender = 'Male';
  String _maritalStatus = 'Single';

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _occupationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _fullNameController.text.isNotEmpty &&
        _dobController.text.isNotEmpty &&
        _occupationController.text.isNotEmpty &&
        _emailController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7EAFB),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Add New Patient Data",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Stay informed with a complete overview of your patients, past sessions, and care history",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: 0.33,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
            ),
            const SizedBox(height: 30),

            // Form
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Full Name'),
                          _buildInput(_fullNameController, 'Enter full name'),
                          const SizedBox(height: 20),
                          _buildLabel('Occupation'),
                          _buildInput(_occupationController, 'Enter occupation'),
                          const SizedBox(height: 20),
                          _buildLabel('Email'),
                          _buildInput(_emailController, 'Enter email'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),

                    // Right column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Date of Birth'),
                          _buildInput(_dobController, 'YYYY-MM-DD'),
                          const SizedBox(height: 20),
                          _buildLabel('Gender'),
                          _buildDropdown(['Male', 'Female'], _gender,
                              (val) => setState(() => _gender = val)),
                          const SizedBox(height: 20),
                          _buildLabel('Marital Status'),
                          _buildDropdown(
                            ['Single', 'Married', 'Divorced'],
                            _maritalStatus,
                            (val) => setState(() => _maritalStatus = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Next button
            Center(
              child: ElevatedButton(
                onPressed: _isFormValid
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddNewPatientStep2(
                              fullName: _fullNameController.text.trim(),
                              dateOfBirth: _dobController.text.trim(),
                              occupation: _occupationController.text.trim(),
                              email: _emailController.text.trim(),
                              gender: _gender,
                              maritalStatus: _maritalStatus,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isFormValid ? const Color(0xFF2F3C58) : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Next"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w500));
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (val) => onChanged(val!),
      ),
    );
  }
}

// Ensure your AddNewPatientStep2 widget supports these parameters:
// class AddNewPatientStep2 extends StatelessWidget {
//   final String fullName;
//   final String dateOfBirth;
//   final String occupation;
//   final String email;
//   final String gender;
//   final String maritalStatus;
//
//   const AddNewPatientStep2({
//     Key? key,
//     required this.fullName,
//     required this.dateOfBirth,
//     required this.occupation,
//     required this.email,
//     required this.gender,
//     required this.maritalStatus,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) { ... }
// }
