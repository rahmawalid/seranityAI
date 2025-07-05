import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/models/doctor_model.dart';
import 'package:ui_screens_grad/models/patient_model.dart';
import 'package:ui_screens_grad/screens/DoctorModule/schedule_session.dart';
import 'package:ui_screens_grad/screens/DoctorModule/login.dart';
import 'package:ui_screens_grad/screens/DoctorModule/select_patient_page.dart';
import 'package:ui_screens_grad/screens/DoctorModule/add_new_patient.dart';
import 'package:ui_screens_grad/screens/DoctorModule/patient_details_page.dart';
import 'package:ui_screens_grad/screens/DoctorModule/chat_with_patient.dart';
import 'package:ui_screens_grad/services/patient_data_service.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';


class UnifiedDoctorLayout extends StatefulWidget {
  final int initialPageIndex;

  const UnifiedDoctorLayout({Key? key, this.initialPageIndex = 0})
      : super(key: key);

  @override
  State<UnifiedDoctorLayout> createState() => _UnifiedDoctorLayoutState();
}

class _UnifiedDoctorLayoutState extends State<UnifiedDoctorLayout>
    with TickerProviderStateMixin {
  int currentPageIndex = 0;
  Doctor? doctor;
  bool _showChatBubble = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.initialPageIndex;
    getDoctorData();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start animation after a delay and auto-hide after some time
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _animationController.forward();
        // Auto-hide after 8 seconds
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _showChatBubble) {
            _hideChatBubble();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getDoctorData() async {
    try {
      doctor = await getUserPreferencesInfo();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading doctor data: $e');
      // Handle case where doctor data is not available
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _hideChatBubble() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showChatBubble = false;
        });
      }
    });
  }

  void _showPatientSelector() {
    // Hide chat bubble when clicked
    if (_showChatBubble) {
      _hideChatBubble();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PatientSelectorSheet(doctor: doctor),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color purpleColor = Color(0xFF7C5FFB);

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(purpleColor),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Home_Page_BG.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: _buildCurrentPage(),
            ),
          ),
        ],
      ),
      // Add floating action button with chat bubble
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main floating action button
          FloatingActionButton(
            onPressed: _showPatientSelector,
            backgroundColor: const Color(0xFF2F3C58),
            elevation: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/Sereni_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image fails to load
                    return const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 28,
                    );
                  },
                ),
              ),
            ),
          ),

          // Chat bubble tooltip
          if (_showChatBubble)
            Positioned(
              right: 70,
              top: -60,
              child: GestureDetector(
                onTap: _hideChatBubble,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 220),
                          clipBehavior: Clip.none,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Chat bubble
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7C5FFB),
                                      Color(0xFF9C7AFF)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF7C5FFB),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.psychology_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Hi! I\'m Sereni',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Your AI therapy assistant! Click me to chat about your patients.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.touch_app,
                                          color: Colors.white70,
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Tap to dismiss',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Chat bubble tail (pointing to the FAB)
                              Positioned(
                                right: -8,
                                top: 20,
                                child: CustomPaint(
                                  size: const Size(16, 16),
                                  painter: ChatBubbleTailPainter(),
                                ),
                              ),

                              // Close button
                              Positioned(
                                top: -4,
                                right: -4,
                                child: GestureDetector(
                                  onTap: _hideChatBubble,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Color(0xFF7C5FFB),
                                    ),
                                  ),
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
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCurrentPage() {
    switch (currentPageIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _PatientsPageContent(doctor: doctor);
      case 2:
        return _CalendarPageContent(doctor: doctor);
      case 3:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildSidebar(Color purpleColor) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Logo and SerenityAI name
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [purpleColor, purpleColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: purpleColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/logo_black.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'SerenityAI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Profile section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [purpleColor, purpleColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: purpleColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      doctor?.personalInfo.fullName.substring(0, 1) ?? 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dr. ${doctor?.personalInfo.fullName ?? 'Doctor'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Pro Plan',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Navigation items
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _CleanSidebarItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: currentPageIndex == 0,
                    showLabel: true,
                    purpleColor: purpleColor,
                    onTap: () => setState(() => currentPageIndex = 0),
                  ),
                  const SizedBox(height: 8),
                  _CleanSidebarItem(
                    icon: Icons.people_rounded,
                    label: 'Patients',
                    isSelected: currentPageIndex == 1,
                    showLabel: true,
                    purpleColor: purpleColor,
                    onTap: () => setState(() => currentPageIndex = 1),
                  ),
                  const SizedBox(height: 8),
                  _CleanSidebarItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Calendar',
                    isSelected: currentPageIndex == 2,
                    showLabel: true,
                    purpleColor: purpleColor,
                    onTap: () => setState(() => currentPageIndex = 2),
                  ),
                  const SizedBox(height: 8),
                  _CleanSidebarItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    isSelected: currentPageIndex == 3,
                    showLabel: true,
                    purpleColor: purpleColor,
                    onTap: () => setState(() => currentPageIndex = 3),
                  ),
                  const Spacer(),

                  // Logout
                  _CleanSidebarItem(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    isSelected: false,
                    showLabel: true,
                    purpleColor: purpleColor,
                    isLogout: true,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // HOME PAGE CONTENT
  Widget _buildHomePage() {
    const Color buttonColor = Color(0xFF2F3C58);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Welcome, ${doctor?.personalInfo.fullName.split(' ').first ?? 'Doctor'}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Together, we make space for healing, growth, and understanding!',
                style: TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _FeatureCard(
                        title: 'Schedule a session',
                        subtitle:
                            'Plan ahead with ease and flexibility, set sessions that work for you',
                        image: 'assets/images/schedule.png',
                        buttonText: 'Schedule',
                        buttonColor: buttonColor,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScheduleMeetingPage()),
                          );
                        },
                      ),
                      _FeatureCard(
                        title: 'Upload a pre-recorded session',
                        subtitle:
                            'Easily upload a pre-recorded video for analysis or review.',
                        image: 'assets/images/upload.png',
                        buttonText: 'Upload',
                        buttonColor: buttonColor,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SelectPatientPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SETTINGS PAGE CONTENT
  Widget _buildSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
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
          padding: const EdgeInsets.all(32),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Settings',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Manage your account settings and preferences',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Text(
                    'Settings page coming soon...',
                    style: TextStyle(fontSize: 18, color: Colors.black38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Patient Selector Bottom Sheet
class _PatientSelectorSheet extends StatefulWidget {
  final Doctor? doctor;

  const _PatientSelectorSheet({this.doctor});

  @override
  State<_PatientSelectorSheet> createState() => _PatientSelectorSheetState();
}

class _PatientSelectorSheetState extends State<_PatientSelectorSheet> {
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final all = await PatientDataService.listPatients();
      if (widget.doctor?.doctorID != null) {
        _patients =
            all.where((p) => p.doctorID == widget.doctor!.doctorID).toList();
      }
    } catch (e) {
      print('Error loading patients: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3C58).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/images/Sereni_logo.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.psychology_rounded,
                      color: Color(0xFF2F3C58),
                      size: 24,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Chat Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Select a patient to start chatting',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Patient list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No patients found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Add patients to start chatting',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF7C5FFB).withOpacity(0.1),
                                child: Text(
                                  patient.personalInfo.fullName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'P',
                                  style: const TextStyle(
                                    color: Color(0xFF7C5FFB),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient.personalInfo.fullName ??
                                    'Unknown Patient',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                patient.personalInfo.contactInformation
                                        ?.email ??
                                    'No email',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF2F3C58),
                              ),
                              // onTap: () {
                              //   Navigator.pop(context);
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (_) => ChatWithPatientPage(
                              //         patient: patient,
                              //         chatMode: ChatMode.patientSession,
                              //       ),
                              //     ),
                              //   );
                              // },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CleanSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showLabel;
  final Color purpleColor;
  final VoidCallback onTap;
  final bool isLogout;

  const _CleanSidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.showLabel,
    required this.purpleColor,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  State<_CleanSidebarItem> createState() => _CleanSidebarItemState();
}

class _CleanSidebarItemState extends State<_CleanSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isSelected;
    final Color iconColor = isSelected
        ? Colors.white
        : widget.isLogout
            ? Colors.red.shade400
            : Colors.grey.shade600;
    final Color textColor = isSelected
        ? Colors.white
        : widget.isLogout
            ? Colors.red.shade400
            : Colors.grey.shade700;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.purpleColor
                  : widget.isLogout
                      ? (_isHovered ? Colors.red.shade50 : Colors.transparent)
                      : (_isHovered
                          ? Colors.grey.shade100
                          : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: widget.purpleColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: iconColor,
                  size: 22,
                ),
                if (widget.showLabel) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
                if (isSelected && widget.showLabel) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
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

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              image,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

// PATIENTS PAGE CONTENT WIDGET
class _PatientsPageContent extends StatefulWidget {
  final Doctor? doctor;

  const _PatientsPageContent({this.doctor});

  @override
  State<_PatientsPageContent> createState() => _PatientsPageContentState();
}

class _PatientsPageContentState extends State<_PatientsPageContent> {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
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
              (p.personalInfo.fullName ?? '').toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final all = await PatientDataService.listPatients();
      if (widget.doctor?.doctorID != null) {
        _patients =
            all.where((p) => p.doctorID == widget.doctor!.doctorID).toList();
      }
      _filteredPatients = _patients;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color buttonColor = Color(0xFF2F3C58);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
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
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Patients List',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Stay informed with a complete overview of your patients, past sessions, and care history',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
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
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddNewPatientScreen()),
                    ).then((_) => _loadPatients()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('+ Add New Patient Data'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey[100],
                child: const Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('ID',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 4,
                        child: Text('Name',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 4,
                        child: Text('Email',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 4,
                        child: Text('Phone Number',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text('Gender',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildPatientsContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_filteredPatients.isEmpty) {
      return const Center(
        child: Text('No Patients Found',
            style: TextStyle(fontSize: 18, color: Colors.black38)),
      );
    }
    return ListView.separated(
      itemCount: _filteredPatients.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = _filteredPatients[i];
        return ListTile(
          title: Row(
            children: [
              Expanded(flex: 2, child: Text(p.patientID.toString())),
              Expanded(flex: 4, child: Text(p.personalInfo.fullName ?? '-')),
              Expanded(
                  flex: 4,
                  child: Text(p.personalInfo.contactInformation?.email ?? '-')),
              Expanded(
                  flex: 4,
                  child: Text(
                      p.personalInfo.contactInformation?.phoneNumber ?? '-')),
              Expanded(flex: 2, child: Text(p.personalInfo.gender ?? '-')),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PatientDetailsPage(patient: p)),
              );
            },
          ),
        );
      },
    );
  }
}

// CALENDAR PAGE CONTENT WIDGET
class _CalendarPageContent extends StatefulWidget {
  final Doctor? doctor;

  const _CalendarPageContent({this.doctor});

  @override
  State<_CalendarPageContent> createState() => _CalendarPageContentState();
}

class _CalendarPageContentState extends State<_CalendarPageContent> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ScheduledSession>> _sessionsByDay = {};
  List<ScheduledSession> _selectedSessions = [];
  Map<int, Patient> _patientsCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.doctor?.doctorID != null) {
      _fetchScheduledSessions();
    }
  }

  Future<void> _fetchScheduledSessions() async {
    if (widget.doctor?.doctorID == null) return;

    try {
      // Use instance method instead of static
      final doctorService = DoctorService();
      final sessions = await doctorService.getScheduledSessions(widget.doctor!.doctorID!);
      
      Map<DateTime, List<ScheduledSession>> sessionsMap = {};

      // Ensure patientID is properly handled
      Set<int> patientIds = sessions
          .where((s) => s.patientID != null)
          .map((s) => s.patientID!)
          .toSet();
      
      await _preloadPatientData(patientIds);

      for (var session in sessions) {
        final date = DateTime(session.datetime.year, session.datetime.month,
            session.datetime.day);
        sessionsMap[date] = [...(sessionsMap[date] ?? []), session];
      }
      if (mounted) {
        setState(() => _sessionsByDay = sessionsMap);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sessions: $e')),
        );
      }
    }
  }

  Future<void> _preloadPatientData(Set<int> patientIds) async {
    for (int patientId in patientIds) {
      try {
        if (!_patientsCache.containsKey(patientId)) {
          // Convert int to string format for service call
          final patientIdStr = PatientDataService.formatPatientId(patientId);
          final patient = await PatientDataService.getPatientById(patientIdStr);
          _patientsCache[patientId] = patient;
        }
      } catch (e) {
        print('Error loading patient $patientId: $e');
      }
    }
  }

  Patient? _getPatientForSession(ScheduledSession session) {
    if (session.patientID != null) {
      return _patientsCache[session.patientID!];
    }
    return null;
  }

  List<ScheduledSession> _getSessionsForDay(DateTime day) {
    return _sessionsByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedSessions = _getSessionsForDay(selectedDay);
    });
  }

  String _getSessionDisplayName(ScheduledSession session) {
    final patient = _getPatientForSession(session);

    if (patient?.personalInfo.fullName != null &&
        patient!.personalInfo.fullName!.isNotEmpty) {
      return patient.personalInfo.fullName!;
    }

    if (session.patientName != null &&
        session.patientName!.isNotEmpty &&
        session.patientName != 'Unknown') {
      return session.patientName!;
    }

    if (session.patientID != null) {
      return 'Patient #${session.patientID}';
    }

    return 'Therapy Session';
  }

  String _getPatientEmail(ScheduledSession session) {
    final patient = _getPatientForSession(session);

    if (patient?.personalInfo.contactInformation?.email != null &&
        patient!.personalInfo.contactInformation!.email!.isNotEmpty) {
      return patient.personalInfo.contactInformation!.email!;
    }

    if (session.patientEmail != null &&
        session.patientEmail!.isNotEmpty &&
        session.patientEmail != 'N/A') {
      return session.patientEmail!;
    }

    return 'Email not available';
  }

  @override
  Widget build(BuildContext context) {
    const Color purpleColor = Color(0xFF7C5FFB);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
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
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Calendar",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  "A clear view of what's ahead — so you can focus on what matters most in each moment.",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12.withOpacity(0.1),
                                blurRadius: 10)
                          ],
                        ),
                        child: TableCalendar<ScheduledSession>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: _onDaySelected,
                          eventLoader: _getSessionsForDay,
                          calendarFormat: CalendarFormat.month,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          calendarStyle: const CalendarStyle(
                            todayDecoration: BoxDecoration(
                                color: Color(0xFFB4E5F9),
                                shape: BoxShape.circle),
                            selectedDecoration: BoxDecoration(
                                color: Color(0xFF2F3C58),
                                shape: BoxShape.circle),
                            markerDecoration: BoxDecoration(
                                color: Color(0xFF7C5FFB),
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12.withOpacity(0.1),
                                blurRadius: 10)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDay != null
                                  ? DateFormat('MMMM dd, yyyy')
                                      .format(_selectedDay!)
                                  : 'Select a date',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _selectedSessions.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.event_available,
                                              size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text("No sessions scheduled",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16)),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _selectedSessions.length,
                                      itemBuilder: (context, index) {
                                        final session =
                                            _selectedSessions[index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(16),
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  purpleColor.withOpacity(0.1),
                                              child: Icon(Icons.person,
                                                  color: purpleColor),
                                            ),
                                            title: Text(
                                              _getSessionDisplayName(session),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.access_time,
                                                        size: 16,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(DateFormat('hh:mm a')
                                                        .format(
                                                            session.datetime)),
                                                  ],
                                                ),
                                                if (session.notes != null &&
                                                    session
                                                        .notes!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.notes,
                                                          size: 16,
                                                          color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          session.notes!,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                  Icons.info_outline,
                                                  color: Color(0xFF5A6BFF)),
                                              onPressed: () =>
                                                  _showSessionDetails(
                                                      context, session),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, ScheduledSession session) {
    final patient = _getPatientForSession(session);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.event, color: Color(0xFF7C5FFB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Session Details",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(
                  Icons.person, "Patient", _getSessionDisplayName(session)),
              _detailRow(Icons.calendar_today, "Date",
                  DateFormat.yMMMd().format(session.datetime)),
              _detailRow(Icons.access_time, "Time",
                  DateFormat.jm().format(session.datetime)),
              _detailRow(Icons.email, "Email", _getPatientEmail(session)),
              if (patient != null) ...[
                if (patient.personalInfo.contactInformation?.phoneNumber !=
                        null &&
                    patient.personalInfo.contactInformation!.phoneNumber!
                        .isNotEmpty)
                  _detailRow(Icons.phone, "Phone",
                      patient.personalInfo.contactInformation!.phoneNumber!),
                if (patient.personalInfo.gender != null &&
                    patient.personalInfo.gender!.isNotEmpty)
                  _detailRow(Icons.person_outline, "Gender",
                      patient.personalInfo.gender!),
                if (patient.personalInfo.occupation != null &&
                    patient.personalInfo.occupation!.isNotEmpty)
                  _detailRow(Icons.work, "Occupation",
                      patient.personalInfo.occupation!),
              ],
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Notes:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(session.notes ?? "No notes"),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

// Custom painter for the chat bubble tail
class ChatBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Create gradient
    final gradient = const LinearGradient(
      colors: [Color(0xFF7C5FFB), Color(0xFF9C7AFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    paint.style = PaintingStyle.fill;

    // Create the tail path
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}