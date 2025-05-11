import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/patient.dart';
import 'package:ui_screens_grad/screens/DoctorModule/upload_session.dart';

class FeatureSelection extends StatefulWidget {
  final Patient patient;
  const FeatureSelection({super.key, required this.patient});

  @override
  State<FeatureSelection> createState() => _FeatureSelectionState();
}

class _FeatureSelectionState extends State<FeatureSelection> {
  bool ferSelected = false;
  bool tovSelected = false;

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
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Feature Selection",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Before starting please select which technology you’d like to use for this meeting. Choose what suits you and your patient best. For best results we recommend using both!",
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 30),

                // Feature Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _selectableCard(
                      image: 'assets/images/FER.png',
                      title: 'Face Emotion Recognition',
                      subtitle:
                          'Track emotional shifts using facial expression data.',
                      selected: ferSelected,
                      onTap: () => setState(() => ferSelected = !ferSelected),
                    ),
                    _selectableCard(
                      image: 'assets/images/TOV.png',
                      title: 'Tone of Voice',
                      subtitle:
                          'Track emotional tone through vocal patterns and speech cues.',
                      selected: tovSelected,
                      onTap: () => setState(() => tovSelected = !tovSelected),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Start Session Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => UploadSessionPage(
                                  patient: widget.patient,
                                  FER: ferSelected,
                                  TOV: tovSelected,
                                )),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3C58),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
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
        ),
      ),
    );
  }

  Widget _selectableCard({
    required String image,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDE6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: selected ? const Color(0xFF2F3C58) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(image, height: 100),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3C58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Select"),
            ),
          ],
        ),
      ),
    );
  }
}
