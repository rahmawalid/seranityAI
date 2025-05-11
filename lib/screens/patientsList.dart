import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/models/doctor.dart';
import 'package:ui_screens_grad/models/patient.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';
import 'package:ui_screens_grad/services/patient_service.dart';

class PatientslistPage extends StatefulWidget {
  const PatientslistPage({super.key});

  @override
  State<PatientslistPage> createState() => _PatientslistPageState();
}

class _PatientslistPageState extends State<PatientslistPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Patients List',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => const PatientslistPage(),
                      //   ),
                      // );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(patients[index].personalInfo.fullName!),
                        subtitle: Text(
                            'Age: ${patients[index].personalInfo.gender!}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['mp3', 'wav', 'mp4', 'mov'],
                              withData: true,
                            );
                            if (result == null || result.files.isEmpty) return;

                            final file = result.files.single;
                            final ext = file.extension!.toLowerCase();
                            final bytes = file.bytes!;
                            final filename = file.name;
                            int patientId = patients[index].patientID;
                            int sessionId =
                                patients[index].sessions.last.sessionId;

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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnack(BuildContext c, String text) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));
  }
}
