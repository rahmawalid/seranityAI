import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/patient.dart';
import 'package:ui_screens_grad/services/patient_service.dart';

class UploadSessionPage extends StatefulWidget {
  final Patient patient;
  final bool FER;
  final bool TOV;

  const UploadSessionPage(
      {super.key, required this.patient, required this.FER, required this.TOV});

  @override
  State<UploadSessionPage> createState() => _UploadSessionPageState();
}

class _UploadSessionPageState extends State<UploadSessionPage> {
  String? selectedFileName;

  void _showSnack(BuildContext c, String text) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickFile() async {
    var result;
    if (widget.FER == true) {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov'],
        withData: true,
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'mp4', 'mov'],
        withData: true,
      );
    }

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final ext = file.extension!.toLowerCase();
    final bytes = file.bytes!;
    final filename = file.name;
    final int patientId = widget.patient.patientID;
    final int? sessionId = widget.patient.sessions.isNotEmpty
        ? widget.patient.sessions.last.sessionId
        : null;

    if (sessionId == null) {
      _showSnack(context, "No session available yet");
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
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () {
                        Navigator.pop(context); // Go back to home
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Upload Session for Analysis",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Upload past interactions to uncover emotional shifts and voice tone patterns that may not be visible in the moment.",
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 30),

                // Upload Area
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload,
                            size: 50, color: Colors.blueAccent),
                        const SizedBox(height: 12),
                        const Text(
                          "Click here to upload or drop media here",
                          style: TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        if (selectedFileName != null)
                          Text(
                            "Selected: $selectedFileName",
                            style: const TextStyle(color: Colors.black87),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Upload Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Handle actual upload or submission
                      if (selectedFileName != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Uploading "$selectedFileName"...')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3C58),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Upload"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
