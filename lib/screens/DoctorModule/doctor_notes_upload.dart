import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_screens_grad/models/patient_model.dart';
import 'package:ui_screens_grad/services/patient_service.dart';
import 'package:ui_screens_grad/services/doctor_notes_service.dart';
import 'package:ui_screens_grad/models/doctor_notes_model.dart';
import 'package:ui_screens_grad/screens/DoctorModule/upload_session.dart';

class DoctorNotesOptionScreen extends StatefulWidget {
  final Patient patient;
  final bool fer;
  final bool tov;

  const DoctorNotesOptionScreen({
    Key? key,
    required this.patient,
    required this.fer,
    required this.tov,
  }) : super(key: key);

  @override
  State<DoctorNotesOptionScreen> createState() =>
      _DoctorNotesOptionScreenState();
}

class _DoctorNotesOptionScreenState extends State<DoctorNotesOptionScreen> {
  List<File> _selectedFiles = [];
  List<FileValidationResult> _validationResults = [];
  int? _sessionId;
  late DoctorNotesService _doctorNotesService;
  bool _isCreatingSession = false;
  
  // Supported formats from service
  SupportedFormats? _supportedFormats;

  @override
  void initState() {
    super.initState();
    _doctorNotesService = Provider.of<DoctorNotesService>(context, listen: false);
    _loadSupportedFormats();
  }

  void _loadSupportedFormats() {
    _supportedFormats = _doctorNotesService.doctorNotesSupportedFormats();
  }

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedFormats?.images ?? ['jpg', 'jpeg', 'png', 'bmp', 'tiff', 'webp'],
        allowMultiple: true,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final files = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      // Validate with service
      final validationResults = _doctorNotesService.validateFiles(files);

      setState(() {
        _selectedFiles = files;
        _validationResults = validationResults;
      });

      if (_doctorNotesService.hasValidationErrors(validationResults)) {
        final errors = _doctorNotesService.getValidationErrors(validationResults);
        _showSnack('File validation issues: ${errors.first}', isError: true);
      } else {
        _showSnack('${files.length} file(s) selected successfully');
      }
    } catch (e) {
      _showSnack('Error selecting files: ${e.toString()}', isError: true);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _validationResults.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      _selectedFiles.clear();
      _validationResults.clear();
    });
  }

  void _skipDoctorNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadSessionPage(
          patient: widget.patient,
          fer: widget.fer,
          tov: widget.tov,
          hasDoctorNotes: false,
        ),
      ),
    );
  }

  Future<void> _proceedWithNotes() async {
    if (_selectedFiles.isEmpty) {
      _skipDoctorNotes();
      return;
    }

    if (_doctorNotesService.hasValidationErrors(_validationResults)) {
      _showSnack('Please fix file validation errors before proceeding', isError: true);
      return;
    }

    setState(() => _isCreatingSession = true);

    try {
      // Validate patient ID
      if (widget.patient.patientID == null) {
        throw Exception('Invalid patient data - missing patient ID');
      }

      // Create session using PatientService
      final sessionData = {
        'featureType': widget.fer && widget.tov
            ? 'fer_tov'
            : widget.fer
                ? 'fer'
                : 'tov',
        'date': DateTime.now().toIso8601String(),
        'time': DateTime.now().toIso8601String(),
        'sessionType': 'recorded',
      };

      final session = await PatientService.createSession(
          PatientService.formatPatientId(widget.patient.patientID!), sessionData);
      
      if (session.sessionId == null) {
        throw Exception('Failed to create session - no session ID returned');
      }
      
      _sessionId = session.sessionId!;

      setState(() => _isCreatingSession = false);

      // Upload doctor notes using the service
      final result = await _doctorNotesService.uploadDoctorNotes(
        patientId: PatientService.formatPatientId(widget.patient.patientID!),
        sessionId: _sessionId!,
        files: _selectedFiles,
      );

      if (result.success && result.data != null) {
        final uploadResult = result.data!;
        _showSnack('✅ Successfully uploaded ${uploadResult.uploadedCount} clinical note(s)');

        // Navigate to upload session with doctor notes
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UploadSessionPage(
                patient: widget.patient,
                fer: widget.fer,
                tov: widget.tov,
                hasDoctorNotes: true,
                sessionId: _sessionId,
              ),
            ),
          );
        }
      } else {
        _showSnack('❌ Upload failed: ${result.error}', isError: true);
      }
    } catch (e) {
      print('Doctor notes upload error: $e');
      _showSnack('❌ Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isCreatingSession = false);
      }
    }
  }

  // Get analysis readiness level
  String _getAnalysisReadinessLevel() {
    final hasNotes = _selectedFiles.isNotEmpty;
    final hasFer = widget.fer;
    final hasTov = widget.tov;

    if (hasNotes && hasFer && hasTov) {
      return 'excellent';
    } else if (hasNotes && (hasFer || hasTov)) {
      return 'good';
    } else if (hasFer || hasTov) {
      return 'fair';
    } else if (hasNotes) {
      return 'basic';
    } else {
      return 'insufficient';
    }
  }

  // Get analysis readiness description
  String _getAnalysisReadinessDescription() {
    final level = _getAnalysisReadinessLevel();
    switch (level) {
      case 'excellent':
        return 'All analysis types available - clinical notes with FER and TOV data';
      case 'good':
        return 'Enhanced analysis available - clinical notes with either FER or TOV data';
      case 'fair':
        return 'Standard analysis available - FER or TOV data present';
      case 'basic':
        return 'Limited analysis available - only clinical notes present';
      case 'insufficient':
        return 'No analysis data available - upload files to begin analysis';
      default:
        return 'Unknown readiness level';
    }
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
            constraints: const BoxConstraints(maxWidth: 1200),
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
                final isOperationInProgress = _isCreatingSession || service.isUploading || service.isLoading;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, 
                              size: 28, color: Color(0xFF2F3C58)),
                          onPressed: isOperationInProgress ? null : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Clinical Notes (Optional)',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F3C58),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Patient info display
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
                                  ),
                                ),
                                if (widget.patient.patientID != null)
                                  Text(
                                    'ID: ${PatientService.formatPatientId(widget.patient.patientID!)}',
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
                      'Upload clinical notes for enhanced AI analysis with professional insights.',
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Analysis readiness info
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
                              const Icon(Icons.analytics, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Analysis Type: ${_getAnalysisTypeText()}',
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
                            'Readiness Level: ${_getAnalysisReadinessLevel().toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getAnalysisReadinessDescription(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Supported formats info
                    if (_supportedFormats != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Supported Formats:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Extensions: ${_supportedFormats!.extensionsFormatted}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              '• Max size: ${_supportedFormats!.maxFileSizeFormatted} per file',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              '• Max files: ${_supportedFormats!.maxFilesPerUpload} per upload',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // File validation summary
                    if (_validationResults.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: service.hasValidationErrors(_validationResults)
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: service.hasValidationErrors(_validationResults)
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              service.hasValidationErrors(_validationResults)
                                  ? Icons.warning
                                  : Icons.check_circle,
                              color: service.hasValidationErrors(_validationResults)
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service.getFileCountSummary(_validationResults),
                                style: TextStyle(
                                  color: service.hasValidationErrors(_validationResults)
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // File picker area
                    Expanded(
                      child: GestureDetector(
                        onTap: isOperationInProgress ? null : _pickFiles,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isOperationInProgress
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
                          child: _selectedFiles.isEmpty
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.note_add,
                                        size: 60, color: Colors.blueAccent),
                                    SizedBox(height: 16),
                                    Text(
                                      'Click here to select clinical notes',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Supports: JPG, PNG, JPEG, BMP, TIFF, WEBP (Max 10MB each)',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Or skip this step to proceed without notes',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_selectedFiles.length} file(s) selected',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (!isOperationInProgress) ...[
                                            Row(
                                              children: [
                                                TextButton.icon(
                                                  onPressed: _pickFiles,
                                                  icon: const Icon(Icons.add, size: 16),
                                                  label: const Text('Add More'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.blue,
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: _clearAllFiles,
                                                  icon: const Icon(Icons.clear_all, size: 16),
                                                  label: const Text('Clear All'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: _selectedFiles.length,
                                          itemBuilder: (context, index) {
                                            final file = _selectedFiles[index];
                                            final validation = index < _validationResults.length
                                                ? _validationResults[index]
                                                : null;
                                            final fileName = file.path.split('/').last;
                                            final fileSize = file.lengthSync();

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: validation?.isValid == false
                                                    ? Colors.red.shade50
                                                    : Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: validation?.isValid == false
                                                      ? Colors.red.shade300
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getFileIcon(fileName),
                                                    size: 24,
                                                    color: validation?.isValid == false
                                                        ? Colors.red
                                                        : _getFileColor(fileName),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          fileName,
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w500),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        Text(
                                                          '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                        if (validation?.error != null) ...[
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            validation!.error!,
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.red,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  if (!isOperationInProgress)
                                                    IconButton(
                                                      icon: const Icon(Icons.close, color: Colors.red),
                                                      onPressed: () => _removeFile(index),
                                                      tooltip: 'Remove file',
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Progress indicators
                    if (_isCreatingSession) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Creating session...',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (service.isUploading) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Uploading clinical notes... ${service.uploadProgressPercent}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: service.uploadProgress,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Error display
                    if (service.error != null) ...[
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
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Skip button
                        TextButton(
                          onPressed: isOperationInProgress ? null : _skipDoctorNotes,
                          child: const Text(
                            'Skip This Step',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),

                        // Continue button
                        ElevatedButton.icon(
                          onPressed: (isOperationInProgress ||
                                  (service.hasValidationErrors(_validationResults) &&
                                      _selectedFiles.isNotEmpty))
                              ? null
                              : _proceedWithNotes,
                          icon: isOperationInProgress
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(_selectedFiles.isEmpty 
                                  ? Icons.arrow_forward 
                                  : Icons.upload),
                          label: Text(
                            _isCreatingSession
                                ? 'Creating Session...'
                                : service.isUploading
                                    ? 'Uploading...'
                                    : _selectedFiles.isEmpty
                                        ? 'Continue'
                                        : 'Upload & Continue',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: buttonColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getAnalysisTypeText() {
    if (widget.fer && widget.tov) {
      return 'Comprehensive Analysis (FER + TOV + Clinical Notes)';
    } else if (widget.fer) {
      return 'Facial Expression Recognition + Clinical Notes';
    } else if (widget.tov) {
      return 'Tone of Voice Analysis + Clinical Notes';
    }
    return 'Clinical Notes Integration';
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'bmp':
      case 'tiff':
      case 'webp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'bmp':
      case 'tiff':
      case 'webp':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}