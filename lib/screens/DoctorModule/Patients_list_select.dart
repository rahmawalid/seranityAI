import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/models/doctor.dart';
import 'package:ui_screens_grad/models/patient.dart';
import 'package:ui_screens_grad/screens/DoctorModule/feature_selecton.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';
import 'package:ui_screens_grad/services/patient_service.dart';

class Patients_list_select extends StatefulWidget {
  const Patients_list_select({super.key});

  @override
  State<Patients_list_select> createState() => _Patients_list_selectState();
}

class _Patients_list_selectState extends State<Patients_list_select> {
  Doctor? doctor;
  List<Patient> patients = [];

  @override
  void initState() {
    super.initState();
    getDoctorData();
  }

  Future<void> getDoctorData() async {
    doctor = await getUserPreferencesInfo();
    if (doctor != null) {
      patients = await DoctorService().getPatientsForDoctor(doctor!.doctorID!);
    }
    setState(() {});
  }

  void _showSnack(BuildContext c, String text) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB7C6FF), Color(0xFFB9F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Container(
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
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back, color: Colors.black)),
                    const SizedBox(width: 10),
                    const Text(
                      "Patients Selection",
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: "Search",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please select the patient you're assisting, or add a new one if they're not listed.",
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 24),

                // Filters
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.filter_list),
                      label: const Text("Filter By"),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: 'Date',
                      items: const [
                        DropdownMenuItem(
                          value: 'Date',
                          child: Text('Date'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: 'Order Type',
                      items: const [
                        DropdownMenuItem(
                          value: 'Order Type',
                          child: Text('Order Type'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: 'Order Status',
                      items: const [
                        DropdownMenuItem(
                          value: 'Order Status',
                          child: Text('Order Status'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Reset Filter",
                          style: TextStyle(color: Colors.red)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F3C58),
                      ),
                      onPressed: () {
                        // TODO: Add new patient logic
                      },
                      child: const Text("+ Add New Patient Data"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Patients Table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("ID")),
                          DataColumn(label: Text("NAME")),
                          DataColumn(label: Text("ADDRESS")),
                          DataColumn(label: Text("SESSIONS")),
                          DataColumn(label: Text("GENDER")),
                          DataColumn(label: Text("")),
                        ],
                        rows: patients.map((patient) {
                          return DataRow(
                            // Make the entire row selectable
                            onSelectChanged: (selected) {
                              if (selected == true) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => FeatureSelection(
                                            patient: patient,
                                          )),
                                );
                              }
                            },
                            cells: [
                              DataCell(Text(patient.patientID.toString())),
                              DataCell(
                                  Text(patient.personalInfo.fullName ?? "-")),
                              DataCell(Text(patient.personalInfo.location ??
                                  "Not provided")),
                              DataCell(
                                  Text(patient.sessions.length.toString())),
                              DataCell(
                                  Text(patient.personalInfo.gender ?? "-")),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.upload),
                                  onPressed: () async {
                                    
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'mp3',
                                        'wav',
                                        'mp4',
                                        'mov'
                                      ],
                                      withData: true,
                                    );
                                    if (result == null || result.files.isEmpty)
                                      return;

                                    final file = result.files.single;
                                    final ext = file.extension!.toLowerCase();
                                    final bytes = file.bytes!;
                                    final filename = file.name;
                                    final int patientId = patient.patientID;
                                    final int? sessionId =
                                        patient.sessions.isNotEmpty
                                            ? patient.sessions.last.sessionId
                                            : null;

                                    if (sessionId == null) {
                                      _showSnack(
                                          context, "No session available yet");
                                      return;
                                    }

                                    try {
                                      if (ext == 'mp3' || ext == 'wav') {
                                        await PatientService.uploadAudio(
                                          patientId: patientId,
                                          sessionId: sessionId,
                                          bytes: bytes,
                                          filename: filename,
                                        );
                                        _showSnack(context, 'Audio uploaded');
                                      } else if (ext == 'mp4' || ext == 'mov') {
                                        await PatientService.uploadVideo(
                                          patientId: patientId,
                                          sessionId: sessionId,
                                          bytes: bytes,
                                          filename: filename,
                                        );
                                        _showSnack(context, 'Video uploaded');
                                      } else {
                                        _showSnack(context, 'Unsupported file');
                                      }
                                    } catch (e) {
                                      _showSnack(context, 'Upload failed: $e');
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
