import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/patient_model.dart'; // FIXED: Correct import
import 'package:ui_screens_grad/screens/DoctorModule/session_analysis_output.dart'; // FIXED: Use correct screen
import 'package:ui_screens_grad/screens/DoctorModule/view_transcription_screen.dart';
import 'package:ui_screens_grad/services/patient_service.dart'; // FIXED: Use PatientService
import 'package:ui_screens_grad/services/transcription_service.dart';

class PatientDetailsPage extends StatefulWidget {
  final Patient patient;
  const PatientDetailsPage({Key? key, required this.patient}) : super(key: key);

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  bool _isSaving = false; // ADDED: Save state

  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _occupationController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _gender, _maritalStatus;

  late TextEditingController _therapyReasonController;
  late TextEditingController _diagnosesController;
  late TextEditingController _conditionsController;
  late TextEditingController _familyHistoryController;
  late TextEditingController _substanceUseController;
  late TextEditingController _medicationsController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final info = widget.patient.personalInfo;
    final contact = info.contactInformation;
    final health = info.healthInfo;
    final therapy = info.therapyInfo;

    _nameController = TextEditingController(text: info.fullName);
    _dobController = TextEditingController(text: info.dateOfBirth);
    _occupationController = TextEditingController(text: info.occupation);
    _emailController = TextEditingController(text: contact?.email);
    _phoneController = TextEditingController(text: contact?.phoneNumber);
    _gender = info.gender;
    _maritalStatus = info.maritalStatus;

    _therapyReasonController =
        TextEditingController(text: therapy?.reasonForTherapy);
    _diagnosesController =
        TextEditingController(text: health?.previousDiagnoses);
    _conditionsController =
        TextEditingController(text: health?.physicalHealthConditions);
    _familyHistoryController =
        TextEditingController(text: health?.familyHistoryOfMentalIllness);
    _substanceUseController = TextEditingController(text: health?.substanceUse);
    _medicationsController =
        TextEditingController(text: health?.currentMedications);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _occupationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _therapyReasonController.dispose();
    _diagnosesController.dispose();
    _conditionsController.dispose();
    _familyHistoryController.dispose();
    _substanceUseController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  // ADDED: Save patient data using PatientService
  Future<void> _savePatientData() async {
    if (!_isEditing) return;

    setState(() => _isSaving = true);

    try {
      // FIXED: Use PatientService for validation and updating
      final updatedData = {
        'personal_info': {
          'full_name': _nameController.text.trim(),
          'date_of_birth': _dobController.text.trim(),
          'gender': _gender,
          'occupation': _occupationController.text.trim(),
          'marital_status': _maritalStatus,
          'contact_information': {
            'email': _emailController.text.trim(),
            'phone_number': _phoneController.text.trim(),
          },
          'health_info': {
            'current_medications': _medicationsController.text.trim(),
            'family_history_of_mental_illness': _familyHistoryController.text.trim(),
            'physical_health_conditions': _conditionsController.text.trim(),
            'previous_diagnoses': _diagnosesController.text.trim(),
            'substance_use': _substanceUseController.text.trim(),
          },
          'therapy_info': {
            'reason_for_therapy': _therapyReasonController.text.trim(),
          },
        },
      };

      // FIXED: Validate data before updating
      final tempPatient = Patient(
        patientID: widget.patient.patientID,
        doctorID: widget.patient.doctorID,
        personalInfo: PersonalInfo(
          fullName: _nameController.text.trim(),
          contactInformation: ContactInformation(
            email: _emailController.text.trim(),
          ),
        ),
        registrationDate: widget.patient.registrationDate,
        status: widget.patient.status,
        sessions: widget.patient.sessions,
      );

      final validationErrors = PatientService.validatePatientData(tempPatient);
      if (validationErrors.isNotEmpty) {
        throw Exception('Validation failed: ${validationErrors.values.first}');
      }

      // FIXED: Use proper patient ID format
      final patientId = PatientService.formatPatientId(widget.patient.patientID!);
      await PatientService.updatePatient(patientId, updatedData);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient information updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ADDED: Delete patient functionality
  Future<void> _deletePatient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
          'Are you sure you want to delete ${widget.patient.personalInfo.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final patientId = PatientService.formatPatientId(widget.patient.patientID!);
        await PatientService.deletePatient(patientId);
        
        if (mounted) {
          Navigator.pop(context); // Go back to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete patient: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FF),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000), // ADDED: Consistent max width
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5A6BFF),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.personalInfo.fullName ?? "Patient",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // ADDED: Display patient ID
                          if (widget.patient.patientID != null)
                            Text(
                              'ID: ${PatientService.formatPatientId(widget.patient.patientID!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // REMOVED: Chat button and related functionality
                    TextButton(
                      onPressed: _deletePatient, // FIXED: Connected to delete function
                      child: const Text(
                        "Delete Patient",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    indicator: BoxDecoration(
                      color: const Color(0xFF5A6BFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(text: "Personal Info"),
                      Tab(text: "Medical Info"),
                      Tab(text: "Sessions"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPersonalInfoTab(),
                      _buildMedicalInfoTab(),
                      _buildSessionsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool enabled = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: _isEditing && enabled,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      ValueSetter<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: _isEditing ? onChanged : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: items
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
      ),
    );
  }

  Widget _buildPersonalInfoTab() => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              _buildTextField(_nameController, "Full Name", enabled: true),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_dobController, "Date of Birth",
                        enabled: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(_occupationController, "Occupation",
                        enabled: true),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_emailController, "Email",
                        enabled: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown("Gender", _gender, ["Male", "Female"],
                        (val) => setState(() => _gender = val)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                        "Marital Status",
                        _maritalStatus,
                        ["Single", "Married", "Divorced"],
                        (val) => setState(() => _maritalStatus = val)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => setState(() => _isEditing = !_isEditing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3C58),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _isEditing ? "Cancel" : "Edit",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: (_isEditing && !_isSaving) ? _savePatientData : null, // FIXED: Connected to save function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditing ? const Color(0xFF4CAF50) : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Save", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildMedicalInfoTab() => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        _therapyReasonController, "Reason for Therapy",
                        enabled: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                        _diagnosesController, "Previous Diagnoses",
                        enabled: true),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        _conditionsController, "Physical Health Conditions",
                        enabled: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(_familyHistoryController,
                        "Family History of Mental Illness",
                        enabled: true),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        _substanceUseController, "Substance Use",
                        enabled: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                        _medicationsController, "Current Medications",
                        enabled: true),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => setState(() => _isEditing = !_isEditing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3C58),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _isEditing ? "Cancel" : "Edit",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: (_isEditing && !_isSaving) ? _savePatientData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditing ? const Color(0xFF4CAF50) : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Save", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSessionsTab() {
    final sessions = widget.patient.sessions;

    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No sessions available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Sessions will appear here once therapy sessions are conducted',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sessions (${sessions.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F3C58),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 1,
                          child: Text("ID",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Date",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Type",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Duration",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 1,
                          child: Text("Report",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 1,
                          child: Text("Transcript",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Actions",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),

                // Data rows
                ...sessions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final session = entry.value;

                  final hasReport = session.report != null;
                  // FIXED: Check transcription properly
                  final hasTranscription = session.transcription != null;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: index == sessions.length - 1
                              ? Colors.transparent
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Session ID
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F3C58),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${session.sessionId}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Date
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              session.date != null
                                  ? session.date!
                                      .toIso8601String()
                                      .split('T')[0]
                                  : "N/A",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),

                        // Feature Type
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    _getFeatureTypeColor(session.featureType),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getFeatureTypeDisplay(session.featureType), // ENHANCED: Better display
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        // Duration
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              session.duration ?? "N/A",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),

                        // Report status
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              hasReport
                                  ? Icons.description
                                  : Icons.description_outlined,
                              color: hasReport ? Colors.green : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),

                        // Transcription status  
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              hasTranscription
                                  ? Icons.text_snippet
                                  : Icons.text_snippet_outlined,
                              color: hasTranscription ? Colors.blue : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),

                        // Actions - REMOVED: Chat button functionality
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // FIXED: View analysis report button
                              Tooltip(
                                message: hasReport
                                    ? 'View analysis report'
                                    : 'No analysis report available',
                                child: InkWell(
                                  onTap: hasReport
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SessionAnalysisOutputScreen( // FIXED: Use correct screen
                                                patient: widget.patient,
                                                sessionId: session.sessionId!,
                                                report_id: session.report!,
                                              ),
                                            ),
                                          );
                                        }
                                      : () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "No analysis report available for this session"),
                                            ),
                                          );
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          hasReport ? Colors.blue : Colors.grey,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.visibility,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // FIXED: View transcription button
                              Tooltip(
                                message: hasTranscription
                                    ? 'View session transcription'
                                    : 'No transcription available',
                                child: InkWell(
                                  onTap: hasTranscription
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ViewTranscriptionScreen(
                                                transcriptionId: session.transcription!, // FIXED: Use transcription field
                                                patientName: widget
                                                        .patient
                                                        .personalInfo
                                                        .fullName ??
                                                    "Patient",
                                                sessionId: session.sessionId!,
                                              ),
                                            ),
                                          );
                                        }
                                      : () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "No transcription available for this session"),
                                            ),
                                          );
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: hasTranscription
                                          ? Colors.green
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.description,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getFeatureTypeColor(String? featureType) {
    switch (featureType?.toLowerCase()) {
      case 'fer':
        return Colors.purple;
      case 'tov':
      case 'speech':
        return Colors.orange;
      case 'fer_tov':
      case 'combined':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ADDED: Better feature type display
  String _getFeatureTypeDisplay(String? featureType) {
    switch (featureType?.toLowerCase()) {
      case 'fer':
        return 'FER';
      case 'tov':
        return 'TOV';
      case 'speech':
        return 'Speech';
      case 'fer_tov':
        return 'FER + TOV';
      case 'combined':
        return 'Combined';
      default:
        return featureType ?? 'Unknown';
    }
  }
}