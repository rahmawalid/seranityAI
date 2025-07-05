import 'package:flutter/material.dart';
import 'package:ui_screens_grad/models/patient_model.dart'; // FIXED: Correct import path
import 'package:ui_screens_grad/screens/DoctorModule/doctor_notes_upload.dart';

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
    const Color buttonColor = Color(0xFF2F3C58);

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
            constraints: const BoxConstraints(maxWidth: 1200), // ADDED: Consistent with other screens
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
                      icon: const Icon(Icons.arrow_back, 
                          size: 28, color: Color(0xFF2F3C58)), // ADDED: Consistent color
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Analysis Type Selection',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F3C58), // ADDED: Consistent color
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // ENHANCED: Patient info display with consistent styling
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient: ${widget.patient.personalInfo.fullName ?? "Unknown Patient"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                            // ADDED: Display patient ID in correct format
                            if (widget.patient.patientID != null)
                              Text(
                                'ID: P${widget.patient.patientID}',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Before starting, please select which technology you\'d like to use for this meeting. Choose what suits you and your patient best. For best results we recommend using both!',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 30),

                // Feature Cards - ENHANCED with better responsive design
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive layout for different screen sizes
                    if (constraints.maxWidth > 800) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _selectableCard(
                            image: 'assets/images/FER.png',
                            title: 'Face Emotion Analysis',
                            subtitle: 'Track emotional shifts using facial expression data.',
                            selected: ferSelected,
                            onTap: () => setState(() => ferSelected = !ferSelected),
                            width: 320,
                          ),
                          _selectableCard(
                            image: 'assets/images/TOV.png',
                            title: 'Tone of Voice Analysis',
                            subtitle: 'Track emotional tone through vocal patterns and speech cues.',
                            selected: tovSelected,
                            onTap: () => setState(() => tovSelected = !tovSelected),
                            width: 320,
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _selectableCard(
                            image: 'assets/images/FER.png',
                            title: 'Face Emotion Analysis',
                            subtitle: 'Track emotional shifts using facial expression data.',
                            selected: ferSelected,
                            onTap: () => setState(() => ferSelected = !ferSelected),
                            width: double.infinity,
                          ),
                          const SizedBox(height: 20),
                          _selectableCard(
                            image: 'assets/images/TOV.png',
                            title: 'Tone of Voice Analysis',
                            subtitle: 'Track emotional tone through vocal patterns and speech cues.',
                            selected: tovSelected,
                            onTap: () => setState(() => tovSelected = !tovSelected),
                            width: double.infinity,
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 30),

                // ENHANCED: Selection summary with better status indicators
                if (ferSelected || tovSelected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Selected Features: ${_getSelectedFeaturesText()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getAnalysisDescription(),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please select at least one analysis feature to continue',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Push "Next" to bottom
                const Spacer(),

                // ENHANCED: Next Button with better styling and navigation
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: (ferSelected || tovSelected)
                        ? () {
                            // FIXED: Navigate to Doctor Notes Option Screen
                            // Validate patient has required data before proceeding
                            if (widget.patient.patientID == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid patient data. Please go back and select a valid patient.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorNotesOptionScreen(
                                  patient: widget.patient,
                                  fer: ferSelected,
                                  tov: tovSelected,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (ferSelected || tovSelected)
                          ? buttonColor
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ENHANCED: More descriptive feature text
  String _getSelectedFeaturesText() {
    if (ferSelected && tovSelected) {
      return 'Comprehensive Analysis (FER + TOV)';
    } else if (ferSelected) {
      return 'Facial Expression Recognition Only';
    } else if (tovSelected) {
      return 'Tone of Voice Analysis Only';
    }
    return '';
  }

  // ADDED: Analysis description for better user understanding
  String _getAnalysisDescription() {
    if (ferSelected && tovSelected) {
      return 'Complete emotional analysis combining facial expressions and voice patterns for maximum insight accuracy.';
    } else if (ferSelected) {
      return 'Video-based analysis focusing on facial expressions and micro-expressions during the session.';
    } else if (tovSelected) {
      return 'Audio-based analysis focusing on vocal patterns, tone changes, and speech characteristics.';
    }
    return '';
  }

  // ENHANCED: Selectable card with responsive design
  Widget _selectableCard({
    required String image,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    double? width,
  }) {
    const Color buttonColor = Color(0xFF2F3C58);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDE6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: selected ? buttonColor : Colors.grey.shade300,
            width: selected ? 3 : 1, // ENHANCED: Thicker border when selected
          ),
        ),
        child: Column(
          children: [
            // ENHANCED: Image with better error handling and sizing
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  image,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          title.contains('Face') ? Icons.face : Icons.mic,
                          size: 40,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Image\nUnavailable',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: selected ? buttonColor : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            
            // ENHANCED: Better selection button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                ),
                label: Text(
                  selected ? 'Selected' : 'Select',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected ? buttonColor : Colors.grey.shade300,
                  foregroundColor: selected ? Colors.white : Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: selected ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}