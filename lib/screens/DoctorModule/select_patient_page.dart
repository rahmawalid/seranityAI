import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/patient_model.dart';  // FIXED: Use patient_model.dart
import 'package:ui_screens_grad/models/doctor_model.dart';
import 'package:ui_screens_grad/screens/DoctorModule/feature_selecton.dart';  // FIXED: Use feature_selection.dart
import 'package:ui_screens_grad/screens/DoctorModule/add_new_patient.dart';
import 'package:ui_screens_grad/services/patient_data_service.dart';
import 'package:ui_screens_grad/constants/functions.dart';

class SelectPatientPage extends StatefulWidget {
  const SelectPatientPage({Key? key}) : super(key: key);

  @override
  State<SelectPatientPage> createState() => _SelectPatientPageState();
}

class _SelectPatientPageState extends State<SelectPatientPage> {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String? _error;
  Doctor? _doctor;  // Added doctor context
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctorAndPatients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _patients
          .where((p) =>
              (p.personalInfo.fullName ?? '').toLowerCase().contains(query) ||
              (p.patientID?.toString() ?? '').toLowerCase().contains(query) ||
              (p.personalInfo.contactInformation?.email ?? '').toLowerCase().contains(query))
          .toList();
    });
  }

  // FIXED: Load doctor context and filter patients by doctor
  Future<void> _loadDoctorAndPatients() async {
    setState(() => _isLoading = true);
    try {
      // Get current doctor context
      _doctor = await getUserPreferencesInfo();
      
      // Load all patients and filter by doctor
      final all = await PatientDataService.listPatients();
      
      // FIXED: Filter patients by current doctor
      if (_doctor?.doctorID != null) {
        _patients = all.where((p) => p.doctorID == _doctor!.doctorID).toList();
      } else {
        _patients = all; // Fallback to all patients if no doctor context
      }
      
      _filteredPatients = _patients;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _patients = [];
      _filteredPatients = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadDoctorAndPatients,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // FIXED: Get display address from patient model
  String _getPatientAddress(Patient patient) {
    if (patient.personalInfo.location != null && 
        patient.personalInfo.location!.isNotEmpty) {
      return patient.personalInfo.location!;
    }
    return '-';
  }

  // FIXED: Get patient display ID in correct format
  String _getPatientDisplayId(Patient patient) {
    if (patient.patientID != null) {
      // Ensure proper format (P1, P2, etc.)
      return PatientDataService.formatPatientId(patient.patientID!);
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFFB7C6FF);
    const gradientEnd = Color(0xFFB9F0FF);
    const buttonColor = Color(0xFF2F3C58);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1200), // ADDED: Max width for better UX
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 30,
                  offset: Offset(0, 12),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          size: 28, color: Color(0xFF2F3C58)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Patient Selection",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddNewPatientScreen()),
                        ).then((_) {
                          // Reload patients after adding new one
                          _loadDoctorAndPatients();
                          _showSuccessSnackBar('Patient list refreshed');
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add New Patient"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                
                // ADDED: Doctor context display
                if (_doctor != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Showing patients for Dr. ${_doctor!.personalInfo.fullName}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_patients.length} patient(s)',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const Text(
                  "Please select the patient you're assisting, or add a new one if they're not listed.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // Search Bar with enhanced functionality
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by name, ID, or email...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              // _onSearchChanged will be called automatically
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Table Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text("Patient ID", 
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 4, child: Text("Name", 
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 4, child: Text("Contact", 
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text("Sessions", 
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text("Gender", 
                          style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),

                // Table Content with enhanced error handling
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading patients...'),
                            ],
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading patients:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadDoctorAndPatients,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: buttonColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _filteredPatients.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isEmpty
                                            ? "No patients found."
                                            : "No patients match your search.",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Add a new patient to get started.",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(14)),
                                  ),
                                  child: ListView.separated(
                                    itemCount: _filteredPatients.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final p = _filteredPatients[i];
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            // FIXED: Navigate to FeatureSelection with proper patient data
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    FeatureSelection(patient: p),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    _getPatientDisplayId(p),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 4,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        p.personalInfo.fullName ?? "-",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      if (p.personalInfo.dateOfBirth != null) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          'Age: ${PatientDataService.getAge(p) ?? "Unknown"}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 4,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        p.personalInfo.contactInformation?.email ?? 
                                                        _getPatientAddress(p),
                                                        style: const TextStyle(fontSize: 13),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (p.personalInfo.contactInformation?.phoneNumber != null) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          p.personalInfo.contactInformation!.phoneNumber!,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "${p.sessions.length}",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      if (p.sessions.isNotEmpty) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          "Last: ${PatientDataService.getLatestSession(p)?.date?.toString().split(' ')[0] ?? 'Unknown'}",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    p.personalInfo.gender ?? "-",
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),

                // ADDED: Bottom action bar with patient count
                if (!_isLoading && _error == null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Showing ${_filteredPatients.length} of ${_patients.length} patients',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (_searchController.text.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear Search'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}