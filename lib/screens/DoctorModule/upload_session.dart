// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:ui_screens_grad/models/patient_model.dart';
import 'package:ui_screens_grad/services/patient_data_service.dart';
import 'package:ui_screens_grad/services/patient_service.dart';
import 'package:ui_screens_grad/services/doctor_notes_service.dart';
import 'package:ui_screens_grad/services/transcription_service.dart';
import 'package:ui_screens_grad/services/report_service.dart'; // ADDED: New report service
import 'package:ui_screens_grad/models/doctor_notes_model.dart';
import 'package:ui_screens_grad/constants/endpoints.dart';
import 'package:ui_screens_grad/screens/DoctorModule/analysis_complete.dart';

class UploadSessionPage extends StatefulWidget {
  final Patient patient;
  final bool fer;
  final bool tov;
  final bool hasDoctorNotes; // Flag indicating if doctor notes were uploaded
  final int? sessionId; // Session ID if doctor notes were already uploaded

  const UploadSessionPage({
    Key? key,
    required this.patient,
    required this.fer,
    required this.tov,
    this.hasDoctorNotes = false,
    this.sessionId,
  }) : super(key: key);

  @override
  State<UploadSessionPage> createState() => _UploadSessionPageState();
}

class _UploadSessionPageState extends State<UploadSessionPage> {
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  late DoctorNotesService _doctorNotesService;
  AnalysisInfo? _analysisCapabilities;

  // Analysis progress tracking
  String _currentStep = '';
  double _analysisProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _doctorNotesService =
        Provider.of<DoctorNotesService>(context, listen: false);
    // Use WidgetsBinding to call after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalysisCapabilities();
    });
  }

  void _showSnack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _loadAnalysisCapabilities() async {
    if (widget.sessionId != null) {
      try {
        final result = await _doctorNotesService.getAnalysisCapabilities(
          patientId: widget.patient.patientID!.toString(),
          sessionId: widget.sessionId!,
          forceRefresh: false,
        );

        if (result.success && result.data != null && mounted) {
          setState(() {
            _analysisCapabilities = result.data;
          });
        } else {
          print('Analysis capabilities failed: ${result.error}');
        }
      } catch (e) {
        print('Failed to load analysis capabilities: $e');
      }
    }
  }

  String _getExpectedAnalysisType() {
    if (widget.fer && widget.tov && widget.hasDoctorNotes) {
      return 'comprehensive_with_notes';
    } else if (widget.tov && widget.hasDoctorNotes) {
      return 'speech_with_notes';
    } else if (widget.fer && widget.tov) {
      return 'comprehensive';
    } else if (widget.tov) {
      return 'speech_only';
    }
    return 'basic';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          widget.fer ? ['mp4', 'mov'] : ['mp3', 'wav', 'mp4', 'mov'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.single);
  }

  void _updateProgress(String step, double progress) {
    setState(() {
      _currentStep = step;
      _analysisProgress = progress;
    });
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null) return;
    setState(() => _isUploading = true);

    final file = _pickedFile!;
    final ext = file.extension!.toLowerCase();
    final bytes = file.bytes!;
    final filename = file.name;
    final pid = widget.patient.patientID;
    String reportId = '';

    try {
      int sessionId;

      _updateProgress('Setting up session...', 0.1);

      // Use existing session if doctor notes were uploaded, otherwise create new session
      if (widget.sessionId != null) {
        sessionId = widget.sessionId!;
        _showSnack('Using existing session with clinical notes');
      } else {
        final session = await PatientDataService.createSession(pid!, {
          'featureType': _getFeatureTypeString(),
          'date': DateTime.now().toIso8601String(),
          'time': DateTime.now().toIso8601String(),
          'sessionType': 'recorded',
        });
        sessionId = session.sessionId!;
      }

      _updateProgress('Uploading media file...', 0.2);

      late String fileId;

      // Upload media file
      if (ext == 'mp3' || ext == 'wav') {
        fileId = await PatientService.uploadAudio(
          patientId: pid!,
          sessionId: sessionId,
          bytes: bytes,
          filename: filename,
        );
        _showSnack('Audio uploaded successfully');
      } else {
        fileId = await PatientService.uploadVideo(
          patientId: pid!,
          sessionId: sessionId,
          bytes: bytes,
          filename: filename,
        );
        _showSnack('Video uploaded successfully');
      }

      _updateProgress('Running analysis...', 0.4);

      // UPDATED: Run analysis based on selected features using correct service methods
      if (widget.fer && widget.tov) {
        // Both FER and TOV selected
        _updateProgress('Running comprehensive analysis...', 0.5);

        // For FER analysis - using the correct endpoint
        final numericPatientId = int.parse(pid!.replaceFirst('P', ''));

        // Step 1: Run FER analysis if video file
        if (ext == 'mp4' || ext == 'mov') {
          final ferUrl = ApiConstants.ferAnalyzeAndSave(
              fileId, numericPatientId, sessionId);
          final ferResponse = await http.get(Uri.parse(ferUrl));
          if (ferResponse.statusCode != 200) {
            throw Exception('FER analysis failed: ${ferResponse.body}');
          }
          _showSnack('FER analysis completed');
        }

        _updateProgress('Running speech and TOV analysis...', 0.7);

        // Step 2: Run Speech/TOV analysis
        final result = await PatientDataService.analyzeSpeechAndTov(
            fileId, pid!, sessionId);
        reportId = result['report_id'] ?? '';
        _showSnack('Speech/TOV analysis completed');
      } else if (widget.fer) {
        // FER only - must be video file
        _updateProgress('Running FER analysis...', 0.6);
        final numericPatientId = int.parse(pid!.replaceFirst('P', ''));
        final ferUrl =
            ApiConstants.ferAnalyzeAndSave(fileId, numericPatientId, sessionId);
        final ferResponse = await http.get(Uri.parse(ferUrl));
        if (ferResponse.statusCode != 200) {
          throw Exception('FER analysis failed: ${ferResponse.body}');
        }
        _showSnack('FER analysis completed');
      } else if (widget.tov) {
        // TOV only
        _updateProgress('Running speech and TOV analysis...', 0.6);
        final result = await PatientDataService.analyzeSpeechAndTov(
            fileId, pid!, sessionId);
        reportId = result['report_id'] ?? '';
        _showSnack('Speech/TOV analysis completed');
      }

      // Generate speech transcription (always happens with TOV)
      if (widget.tov) {
        try {
          _updateProgress('Generating speech transcription...', 0.75);

          // Use TranscriptionService for speech-to-text transcription
          await TranscriptionService.analyzeTranscription(
            fileId: fileId,
            patientId: pid!,
            sessionId: sessionId,
          );

          _showSnack('Speech transcription generated');
        } catch (e) {
          print('Transcription generation failed: $e');
          _showSnack(
              '⚠️ Transcription generation failed but analysis continues');
        }
      }

      // UPDATED: Generate report using new ReportService
      _updateProgress('Generating analysis report...', 0.85);
      try {
        Map<String, dynamic> reportResult;
        
        if (widget.hasDoctorNotes) {
          // Generate enhanced report with doctor notes
          _updateProgress('Generating enhanced report with clinical notes...', 0.87);
          reportResult = await ReportService.generateReportWithDoctorNotes(
            patientId: pid!,
            sessionId: sessionId,
          );
          _showSnack('✅ Enhanced report with clinical notes generated');
        } else if (widget.fer && widget.tov) {
          // Generate comprehensive report (FER + TOV)
          _updateProgress('Generating comprehensive FER+TOV report...', 0.87);
          reportResult = await ReportService.generateComprehensiveReport(
            patientId: pid!,
            sessionId: sessionId,
          );
          _showSnack('✅ Comprehensive analysis report generated');
        } else if (widget.tov) {
          // Generate TOV-only report
          _updateProgress('Generating TOV analysis report...', 0.87);
          reportResult = await ReportService.generateTovOnlyReport(
            patientId: pid!,
            sessionId: sessionId,
          );
          _showSnack('✅ TOV analysis report generated');
        } else {
          // Generate automatic report (fallback)
          _updateProgress('Generating analysis report...', 0.87);
          reportResult = await ReportService.generateAnalysisReport(
            patientId: pid!,
            sessionId: sessionId,
          );
          _showSnack('✅ Analysis report generated');
        }

        // Extract report ID from result
        if (reportResult['success'] == true && reportResult['report_id'] != null) {
          reportId = reportResult['report_id'];
          
          // Log analysis type for debugging
          final analysisType = reportResult['analysis_type'] ?? 'unknown';
          print('🔍 Generated report type: $analysisType');
          
          // Show specific success message based on analysis type
          if (reportResult.containsKey('analysis_type')) {
            final description = ReportService.getAnalysisTypeDescription(analysisType);
            print('📊 Analysis description: $description');
          }
        } else {
          print('⚠️ Report generation succeeded but no report ID returned');
        }

      } catch (e) {
        print('❌ New report generation failed, trying legacy method: $e');
        
        // Fallback to legacy report generation
        try {
          final numericPatientId = int.parse(pid!.replaceFirst('P', ''));
          final reportUrl = ApiConstants.generateReport(numericPatientId, sessionId);
          final reportResponse = await http.post(Uri.parse(reportUrl));

          if (reportResponse.statusCode == 200) {
            final reportData = jsonDecode(reportResponse.body);
            if (reportId.isEmpty) {
              reportId = reportData['report_id'] ?? '';
            }
            _showSnack('⚠️ Legacy report generated (new system unavailable)');
          }
        } catch (legacyError) {
          print('❌ Legacy report generation also failed: $legacyError');
          _showSnack('⚠️ Report generation issues - analysis data saved', isError: true);
        }
      }

      _updateProgress('Complete!', 1.0);

      setState(() => _pickedFile = null);

      // Navigate to completion screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisCompleteScreen(
            patient: widget.patient,
            sessionId: sessionId,
            report_id: reportId.isNotEmpty ? reportId : 'generated',
            hasEnhancedReport: widget.hasDoctorNotes,
          ),
        ),
      );
    } catch (e) {
      _showSnack('❌ Upload or analysis failed: $e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
        _currentStep = '';
        _analysisProgress = 0.0;
      });
    }
  }

  String _getFeatureTypeString() {
    if (widget.fer && widget.tov) {
      return 'fer_tov';
    } else if (widget.fer) {
      return 'fer';
    } else if (widget.tov) {
      return 'tov';
    }
    return 'unknown';
  }

  String _getAnalysisTypeDescription() {
    if (_analysisCapabilities != null) {
      return _analysisCapabilities!.analysisTypeDisplay;
    }

    // Fallback to manual calculation
    if (widget.fer && widget.tov && widget.hasDoctorNotes) {
      return 'Comprehensive Analysis + Clinical Notes';
    } else if (widget.fer && widget.hasDoctorNotes) {
      return 'FER Analysis + Clinical Notes';
    } else if (widget.tov && widget.hasDoctorNotes) {
      return 'TOV Analysis + Clinical Notes';
    } else if (widget.fer && widget.tov) {
      return 'Comprehensive Analysis (FER + TOV)';
    } else if (widget.fer) {
      return 'Facial Expression Recognition';
    } else if (widget.tov) {
      return 'Tone of Voice Analysis';
    }
    return 'Standard Analysis';
  }

  String _getAnalysisTypeSubtext() {
    final expectedType = _getExpectedAnalysisType();

    switch (expectedType) {
      case 'comprehensive_with_notes':
        return 'Complete analysis with facial expressions, voice tone, speech transcription, and clinical notes for maximum insights using enhanced AI prompts.';
      case 'speech_with_notes':
        return 'Voice tone analysis with speech transcription enhanced with clinical notes using specialized TOV+Notes AI prompts.';
      case 'comprehensive':
        return 'Combined facial expression and voice tone analysis with speech transcription using comprehensive AI prompts.';
      case 'speech_only':
        return 'Voice tone and speech pattern analysis with automatic transcription using TOV-specific AI prompts.';
      default:
        return 'Standard analysis with selected features and automatic transcription using appropriate AI prompts.';
    }
  }

  // ADDED: Method to get expected prompt type for display
  String _getExpectedPromptType() {
    if (widget.fer && widget.tov && widget.hasDoctorNotes) {
      return 'Enhanced Comprehensive + Clinical Notes Prompt';
    } else if (widget.tov && widget.hasDoctorNotes) {
      return 'Enhanced TOV + Clinical Notes Prompt';
    } else if (widget.fer && widget.tov) {
      return 'Comprehensive FER+TOV Prompt (full_without_doctornotes_Apis.ipynb)';
    } else if (widget.tov) {
      return 'TOV-Only Prompt (tov_wirhout_notes.ipynb)';
    }
    return 'Standard Analysis Prompt';
  }

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
            child: Consumer<DoctorNotesService>(
              builder: (context, service, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 28),
                          onPressed: _isUploading
                              ? null
                              : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Upload Session for Analysis',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload past interactions to uncover emotional shifts and voice tone patterns using advanced AI analysis.',
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 24),

                    // Enhanced analysis type indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.hasDoctorNotes
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.hasDoctorNotes
                              ? Colors.green.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.hasDoctorNotes
                                    ? Icons.note_alt
                                    : Icons.analytics,
                                color: widget.hasDoctorNotes
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getAnalysisTypeDescription(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: widget.hasDoctorNotes
                                        ? Colors.green.shade700
                                        : Colors.blue.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getAnalysisTypeSubtext(),
                            style: TextStyle(
                              color: widget.hasDoctorNotes
                                  ? Colors.green.shade600
                                  : Colors.blue.shade600,
                              fontSize: 13,
                            ),
                          ),

                          // ADDED: Show expected prompt type
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: widget.hasDoctorNotes
                                    ? Colors.green.shade300
                                    : Colors.blue.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  size: 16,
                                  color: widget.hasDoctorNotes
                                      ? Colors.green.shade600
                                      : Colors.blue.shade600,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'AI Prompt: ${_getExpectedPromptType()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: widget.hasDoctorNotes
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Show analysis capabilities if available
                          if (_analysisCapabilities != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Session Data Available:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      if (_analysisCapabilities!.hasFer)
                                        const Chip(
                                          label: Text('FER',
                                              style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.blue,
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (_analysisCapabilities!.hasSpeech)
                                        const Chip(
                                          label: Text('Speech',
                                              style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.orange,
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (_analysisCapabilities!.hasDoctorNotes)
                                        const Chip(
                                          label: Text('Clinical Notes',
                                              style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.green,
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      // Always show transcription for TOV
                                      if (widget.tov)
                                        const Chip(
                                          label: Text('Transcription',
                                              style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.purple,
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // File upload area
                    GestureDetector(
                      onTap: _isUploading ? null : _pickFile,
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: _isUploading
                              ? Colors.grey.shade100
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isUploading
                                ? Colors.grey.shade300
                                : Colors.grey.shade400,
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
                        child: _pickedFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.fer
                                        ? Icons.videocam
                                        : Icons.audiotrack,
                                    size: 50,
                                    color: _isUploading
                                        ? Colors.grey
                                        : Colors.blueAccent,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.fer
                                        ? 'Click here to select video file'
                                        : 'Click here to select audio/video file',
                                    style: TextStyle(
                                      color: _isUploading
                                          ? Colors.grey
                                          : Colors.blue,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.fer
                                        ? 'Supports: MP4, MOV'
                                        : 'Supports: MP3, WAV, MP4, MOV',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getFileIcon(_pickedFile!.extension),
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _pickedFile!.name,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_isUploading)
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () =>
                                            setState(() => _pickedFile = null),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Upload button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: (_pickedFile == null || _isUploading)
                            ? null
                            : _uploadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: buttonColor.withOpacity(0.5),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _getUploadButtonText(),
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ),

                    // Enhanced upload progress
                    if (_isUploading) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _currentStep.isEmpty
                                        ? 'Processing...'
                                        : _currentStep,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(_analysisProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _analysisProgress,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getProgressDescription(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Service error display
                    if (service.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: service.clearError,
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getUploadButtonText() {
    if (widget.hasDoctorNotes) {
      return 'Upload & Generate Enhanced Report';
    } else if (widget.fer && widget.tov) {
      return 'Upload & Generate Comprehensive Report';
    } else if (widget.tov) {
      return 'Upload & Generate TOV Report';
    } else {
      return 'Upload & Analyze';
    }
  }

  String _getProgressDescription() {
    if (widget.hasDoctorNotes) {
      return 'Enhanced analysis includes clinical notes integration, FER/TOV analysis, speech transcription, and comprehensive AI-driven reporting using specialized prompts.';
    } else if (widget.fer && widget.tov) {
      return 'Running comprehensive analysis with FER, TOV, speech transcription, and report generation using combined analysis AI prompts.';
    } else if (widget.tov) {
      return 'Running TOV analysis with speech transcription and report generation using specialized TOV-only AI prompts.';
    } else {
      return 'Running FER analysis and generating report using appropriate AI analysis prompts.';
    }
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'mp4':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }
}