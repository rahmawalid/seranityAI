import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/models/doctor_model.dart';
import 'package:ui_screens_grad/models/patient_model.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';
import 'package:ui_screens_grad/services/patient_service.dart'; // FIXED: Use PatientService
import 'package:ui_screens_grad/screens/DoctorModule/doctor_main_layout.dart';


class ScheduleMeetingPage extends StatefulWidget {
  const ScheduleMeetingPage({Key? key}) : super(key: key);

  @override
  State<ScheduleMeetingPage> createState() => _ScheduleMeetingPageState();
}

class _ScheduleMeetingPageState extends State<ScheduleMeetingPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay _selectedTime = TimeOfDay.now();

  Doctor? _doctor;
  List<Patient> _patients = [];
  bool _isLoading = true;
  bool _isScheduling = false; // ADDED: Scheduling state
  String? _error;
  Patient? _selectedPatient;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ADDED: Form validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadDoctorAndPatients();
  }

  Future<void> _loadDoctorAndPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await getUserPreferencesInfo();
      if (!mounted) return;
      
      _doctor = doc;
      if (doc?.doctorID != null) {
        // FIXED: Use PatientService.listPatientsByDoctor for better filtering
        try {
          final allPatients = await PatientService.listPatientsByDoctor(doc!.doctorID!);
          _patients = allPatients;
        } catch (e) {
          // Fallback to listing all patients and filtering
          print('Failed to get patients by doctor, falling back to all patients: $e');
          final allPatients = await PatientService.listPatients();
          _patients = allPatients.where((p) => p.doctorID == doc!.doctorID).toList();
        }
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading doctor and patients: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ADDED: Input validation
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ADDED: Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ENHANCED: Better date/time validation
  bool _isValidScheduleTime() {
    if (_selectedDay == null) return false;
    
    final scheduledDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // Can't schedule in the past
    return scheduledDateTime.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    const Color buttonColor = Color(0xFF2F3C58);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
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
              constraints: const BoxConstraints(maxWidth: 900), // ENHANCED: Wider for better UX
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form( // ADDED: Form wrapper for validation
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button & title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, 
                              size: 28, color: Color(0xFF2F3C58)),
                          onPressed: _isScheduling ? null : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Schedule Meeting',
                                style: TextStyle(
                                  fontSize: 26, 
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2F3C58),
                                ),
                                textAlign: TextAlign.left,
                              ),
                              // ADDED: Doctor info display
                              if (_doctor != null)
                                Text(
                                  'Dr. ${_doctor!.personalInfo.fullName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stay in control of your schedule by setting sessions that work for both you and your clients — supporting smooth, timely, and thoughtful care!',
                      style: TextStyle(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // ENHANCED: Better error display
                    if (_error != null) ...[
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
                                'Error loading data: $_error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadDoctorAndPatients,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calendar & Time picker
                        Column(
                          children: [
                            Container(
                              width: 320, // ENHANCED: Slightly wider
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TableCalendar(
                                firstDay: DateTime.now(), // FIXED: Can't schedule in the past
                                lastDay: DateTime.now().add(const Duration(days: 365)),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (d) =>
                                    isSameDay(_selectedDay, d),
                                onDaySelected: (d, f) {
                                  setState(() {
                                    _selectedDay = d;
                                    _focusedDay = f;
                                  });
                                },
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                calendarStyle: CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    color: buttonColor.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: const BoxDecoration(
                                    color: buttonColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // ENHANCED: Time picker with validation
                            Column(
                              children: [
                                const Text(
                                  'Select Time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _isScheduling ? null : () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _selectedTime,
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedTime = picked);
                                    }
                                  },
                                  icon: const Icon(Icons.access_time, size: 18),
                                  label: Text(_selectedTime.format(context)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                
                                // ADDED: Time validation warning
                                if (_selectedDay != null && !_isValidScheduleTime())
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Cannot schedule in the past',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                        
                        // Patient & details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Patient selection
                              const Text(
                                'Patient Name *',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              _isLoading
                                  ? Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : DropdownButtonFormField<Patient>(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.red),
                                        ),
                                      ),
                                      hint: Text('Select patient (${_patients.length} available)'),
                                      items: _patients
                                          .map((p) => DropdownMenuItem(
                                                value: p,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        p.personalInfo.fullName ?? 'Unknown Patient',
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (p.patientID != null)
                                                      Text(
                                                        ' (${PatientService.formatPatientId(p.patientID!)})',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                      value: _selectedPatient,
                                      onChanged: _isScheduling ? null : (p) {
                                        setState(() {
                                          _selectedPatient = p;
                                          _emailController.text = p
                                                  ?.personalInfo
                                                  .contactInformation
                                                  ?.email ??
                                              '';
                                        });
                                      },
                                      validator: (value) => value == null ? 'Please select a patient' : null,
                                    ),
                              const SizedBox(height: 16),
                              
                              // Patient email
                              const Text(
                                'Patient Email *',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                enabled: !_isScheduling,
                                decoration: InputDecoration(
                                  hintText: 'Patient email address',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red),
                                  ),
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 16),
                              
                              // Meeting notes
                              const Text(
                                'Meeting Description/Notes',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _notesController,
                                enabled: !_isScheduling,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Enter notes for the meeting (optional)',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  alignLabelWithHint: true,
                                ),
                                maxLength: 500,
                              ),
                              
                              // ADDED: Schedule summary
                              if (_selectedPatient != null && _selectedDay != null && _isValidScheduleTime())
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Schedule Summary:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '• Patient: ${_selectedPatient!.personalInfo.fullName}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        '• Date: ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        '• Time: ${_selectedTime.format(context)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // ENHANCED: Schedule button with better states
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: (_selectedPatient == null || 
                                   _selectedDay == null || 
                                   !_isValidScheduleTime() ||
                                   _isScheduling)
                            ? null
                            : _onSchedulePressed,
                        icon: _isScheduling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.event_available),
                        label: Text(_isScheduling ? 'Scheduling...' : 'Schedule Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: buttonColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSchedulePressed() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatient == null || _selectedDay == null || _doctor == null) {
      return;
    }

    if (!_isValidScheduleTime()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot schedule meetings in the past'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isScheduling = true);

    final scheduledDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      // FIXED: Use DoctorService with correct parameters
      final doctorService = DoctorService();
      await doctorService.scheduleSession(
        doctorId: _doctor!.doctorID!,
        patientId: _selectedPatient!.patientID!,
        datetime: scheduledDateTime,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _ScheduleConfirmationScreen(
              patientName: _selectedPatient!.personalInfo.fullName ?? 'Patient',
              scheduledTime: scheduledDateTime,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isScheduling = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule session: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _onSchedulePressed,
            ),
          ),
        );
      }
    }
  }
}

// ENHANCED: Confirmation screen with better info display
class _ScheduleConfirmationScreen extends StatefulWidget {
  final String patientName;
  final DateTime scheduledTime;
  
  const _ScheduleConfirmationScreen({
    Key? key,
    required this.patientName,
    required this.scheduledTime,
  }) : super(key: key);

  @override
  State<_ScheduleConfirmationScreen> createState() =>
      _ScheduleConfirmationScreenState();
}

class _ScheduleConfirmationScreenState
    extends State<_ScheduleConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UnifiedDoctorLayout()),
          (route) => false,
        );
      }
    });
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
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success message
                const Text(
                  'Session Scheduled Successfully!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F3C58),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Session details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Patient:', widget.patientName),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Date:', 
                        '${widget.scheduledTime.day}/${widget.scheduledTime.month}/${widget.scheduledTime.year}'
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Time:', 
                        TimeOfDay.fromDateTime(widget.scheduledTime).format(context)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Auto-redirect info
                const Text(
                  'Redirecting to home in 5 seconds...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Manual navigation button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const UnifiedDoctorLayout()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F3C58),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}