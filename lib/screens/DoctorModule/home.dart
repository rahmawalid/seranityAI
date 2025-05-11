import 'package:flutter/material.dart';
import 'package:ui_screens_grad/constants/functions.dart';
import 'package:ui_screens_grad/models/doctor.dart';
import 'package:ui_screens_grad/screens/DoctorModule/Patients_list_select.dart';
import 'package:ui_screens_grad/screens/DoctorModule/schedule_session.dart';
import 'package:ui_screens_grad/screens/DoctorModule/signup_personal_screen.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  bool isSidebarExpanded = true;

  Doctor? doctor;

  @override
  void initState() {
    super.initState();

    getDoctorData();
  }

  Future<void> getDoctorData() async {
    doctor = await getUserPreferencesInfo();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
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
                    color: Colors.white.withOpacity(0.9),
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
                      Text(
                        "Welcome, ${doctor?.personalInfo.fullName}",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Together, we make space for healing, growth, and understanding!",
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FeatureCard(
                            title: "Start an instant session",
                            subtitle:
                                "Start a session now to listen, guide, and make a difference!",
                            image: 'assets/images/chat.png',
                            buttonText: "Start now",
                            onPressed: () {
                              Navigator.pushNamed(context, '/features');
                            },
                          ),
                          _FeatureCard(
                            title: "Schedule a session",
                            subtitle:
                                "Plan ahead with ease and flexibility, set sessions that work for you",
                            image: 'assets/images/schedule.png',
                            buttonText: "Schedule",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ScheduleMeetingPage(),
                                ),
                              );
                            },
                          ),
                          _FeatureCard(
                            title: "Upload a pre-recorded session",
                            subtitle:
                                "Easily upload a pre-recorded video for analysis or review.",
                            image: 'assets/images/upload.png',
                            buttonText: "Upload",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const Patients_list_select(),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSidebarExpanded ? 240 : 70,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FF),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF5A6BFF),
            child:
                Text("R", style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          const SizedBox(height: 8),
          if (isSidebarExpanded) ...[
            Text("Dr. ${doctor?.personalInfo.fullName}",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Free plan", style: TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 40),
          _SidebarItem(
            icon: Icons.home,
            label: "Home",
            isSelected: true,
            showLabel: isSidebarExpanded,
            onTap: () => Navigator.pushNamed(context, '/home'),
          ),
          _SidebarItem(
            icon: Icons.people,
            label: "Patients",
            showLabel: isSidebarExpanded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Patients_list_select(),
              ),
            ),
          ),
          _SidebarItem(
            icon: Icons.calendar_today,
            label: "Calendar",
            showLabel: isSidebarExpanded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScheduleMeetingPage(),
              ),
            ),
          ),
          _SidebarItem(
              icon: Icons.settings,
              label: "Settings",
              showLabel: isSidebarExpanded),
          const Spacer(),
          _SidebarItem(
              icon: Icons.help_outline,
              label: "Help",
              showLabel: isSidebarExpanded),
          _SidebarItem(
            icon: Icons.logout,
            label: "Log out",
            showLabel: isSidebarExpanded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignupPersonalScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(isSidebarExpanded
                ? Icons.arrow_back_ios
                : Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                isSidebarExpanded = !isSidebarExpanded;
              });
            },
          )
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.showLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          Icon(icon, color: isSelected ? const Color(0xFF5A6BFF) : Colors.grey),
      title: showLabel
          ? Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF5A6BFF) : Colors.black,
              ),
            )
          : null,
      selected: isSelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final String buttonText;
  final VoidCallback onPressed;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.buttonText,
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
            child: Image.asset(image, height: 100, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3C58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(buttonText),
          )
        ],
      ),
    );
  }
}
