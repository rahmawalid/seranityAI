import 'package:flutter/material.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/screens/DoctorModule/doctor_main_layout.dart';
import 'package:ui_screens_grad/services/patient_data_service.dart';
import 'package:ui_screens_grad/models/doctor_model.dart' as dr;
import 'package:ui_screens_grad/models/patient_model.dart' as pt;

class AddNewPatientStep2 extends StatefulWidget {
  final String fullName;
  final String dateOfBirth;
  final String occupation;
  final String email;
  final String gender;
  final String maritalStatus;

  const AddNewPatientStep2({
    Key? key,
    required this.fullName,
    required this.dateOfBirth,
    required this.occupation,
    required this.email,
    required this.gender,
    required this.maritalStatus,
  }) : super(key: key);

  @override
  State<AddNewPatientStep2> createState() => _AddNewPatientStep2State();
}

class _AddNewPatientStep2State extends State<AddNewPatientStep2> {
  final _reasonController = TextEditingController();
  final _prevDiagnosesController = TextEditingController();
  final _physicalConditionsController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _substanceUseController = TextEditingController();
  final _currentMedsController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _prevDiagnosesController.dispose();
    _physicalConditionsController.dispose();
    _familyHistoryController.dispose();
    _substanceUseController.dispose();
    _currentMedsController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    setState(() => _isSaving = true);

    final dr.Doctor? doctor = await getUserPreferencesInfo();
    if (!mounted) return;
    if (doctor == null || doctor.doctorID == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to retrieve doctor info.')),
      );
      return;
    }

    final pt.PersonalInfo personalInfo = pt.PersonalInfo(
      fullName: widget.fullName,
      dateOfBirth: widget.dateOfBirth,
      gender: widget.gender,
      occupation: widget.occupation,
      maritalStatus: widget.maritalStatus,
      location: null,
      contactInformation: pt.ContactInformation(
        email: widget.email,
        phoneNumber: null,
      ),
      healthInfo: pt.HealthInfo(
        currentMedications: _currentMedsController.text.trim(),
        familyHistoryOfMentalIllness: _familyHistoryController.text.trim(),
        physicalHealthConditions: _physicalConditionsController.text.trim(),
        previousDiagnoses: _prevDiagnosesController.text.trim(),
        substanceUse: _substanceUseController.text.trim(),
      ),
      therapyInfo: pt.TherapyInfo(
        reasonForTherapy: _reasonController.text.trim(),
      ),
    );

    final pt.Patient newPatient = pt.Patient(
      doctorID: doctor.doctorID!,
      personalInfo: personalInfo,
      registrationDate: DateTime.now(),
      status: 'active',
      sessions: [],
    );

    print('New Patient: ${newPatient.toJson()}');

    try {
      final String createdId =
          await PatientDataService.createPatient(newPatient);
      if (!mounted) return;
      setState(() => _isSaving = false);

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Patient added Successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('ID: $createdId'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                )
              ],
            ),
          ),
        ),
      );
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UnifiedDoctorLayout()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add patient: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFFF),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.blue, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add New Patient Data',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Stay informed with a complete overview of your patients, past sessions, and care history",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Container(
              height: 3,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.6,
                child: Container(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 40,
                  mainAxisSpacing: 20,
                  childAspectRatio: 3.5,
                  children: [
                    _buildTextField(
                      "Reason for Therapy",
                      controller: _reasonController,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      "Previous Diagnoses",
                      controller: _prevDiagnosesController,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      "Physical Health Conditions",
                      controller: _physicalConditionsController,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      "Family History of Mental Illness",
                      controller: _familyHistoryController,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      "Substance Use",
                      controller: _substanceUseController,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      "Current Medications",
                      controller: _currentMedsController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3C58),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Add", style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: "Enter $label",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}
