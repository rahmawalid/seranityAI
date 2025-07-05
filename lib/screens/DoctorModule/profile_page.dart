// import 'package:flutter/material.dart';
// import 'package:ui_screens_grad/constants/functions.dart';
// import 'package:ui_screens_grad/model/doctor.dart';
// import 'package:ui_screens_grad/services/doctor_service.dart';
// import 'package:ui_screens_grad/screens/DoctorModule/home.dart';
// import 'package:ui_screens_grad/screens/DoctorModule/patients_page.dart';
// import 'package:ui_screens_grad/screens/DoctorModule/calendar.dart';
// import 'package:ui_screens_grad/screens/DoctorModule/schedule_session.dart';
// import 'package:ui_screens_grad/screens/DoctorModule/feature_selection.dart';
// import 'package:ui_screens_grad/screens/DoctorModule/signup_personal_screen.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({Key? key}) : super(key: key);

//   @override
//   _ProfilePageState createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   bool isSidebarExpanded = true;
//   String currentTab = 'profile';
//   Doctor? doctor;

//   // Controllers for form fields
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _userNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _locationController = TextEditingController();
//   final _timeZoneController = TextEditingController();
//   final _currentPasswordController = TextEditingController();
//   final _newPasswordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadDoctor();
//   }

//   Future<void> _loadDoctor() async {
//     doctor = await getUserPreferencesInfo();
//     if (doctor != null) {
//       // Split full name
//       final parts = doctor!.personalInfo.fullName.split(' ');
//       _firstNameController.text = parts.first;
//       _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';

//       // Assumes Doctor model has username field
//       _userNameController.text = (doctor as dynamic).username ?? '';
//       _emailController.text = doctor!.personalInfo.email;
//       _phoneController.text = doctor!.personalInfo.phoneNumber;
//       _locationController.text = doctor!.personalInfo.location ?? '';
//       _timeZoneController.text = doctor!.personalInfo.timeZone ?? '';
//     }
//     setState(() {});
//   }

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _userNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _locationController.dispose();
//     _timeZoneController.dispose();
//     _currentPasswordController.dispose();
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     const primaryColor = Color(0xFF5A6BFF);
//     const sidebarBgColor = Color(0xFFF7F8FF);
//     const buttonColor = Color(0xFF2F3C58);

//     return Scaffold(
//       body: Row(
//         children: [
//           // Sidebar
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             width: isSidebarExpanded ? 240 : 70,
//             padding: const EdgeInsets.symmetric(vertical: 40),
//             decoration: BoxDecoration(
//               color: sidebarBgColor,
//               borderRadius: const BorderRadius.only(
//                 topRight: Radius.circular(24),
//                 bottomRight: Radius.circular(24),
//               ),
//             ),
//             child: Column(
//               children: [
//                 if (isSidebarExpanded) ...[
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 24),
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 16),
//                         Image.asset('assets/images/logo_white.png', width: 32),
//                         const SizedBox(width: 8),
//                         const Text('SerenityAI', style: TextStyle(fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                   ),
//                 ] else ...[
//                   CircleAvatar(
//                     radius: 24,
//                     backgroundColor: primaryColor,
//                     child: Text(
//                       doctor?.personalInfo.fullName.substring(0, 1).toUpperCase() ?? 'D',
//                       style: const TextStyle(color: Colors.white, fontSize: 20),
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 32),
//                 _SidebarItem(icon: Icons.home, label: 'Home', isSelected: false, showLabel: isSidebarExpanded, onTap: () {
//                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorHomePage()));
//                 }),
//                 _SidebarItem(icon: Icons.people, label: 'Patients', isSelected: false, showLabel: isSidebarExpanded, onTap: () {
//                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientsPage()));
//                 }),
//                 _SidebarItem(icon: Icons.calendar_today, label: 'Calendar', isSelected: false, showLabel: isSidebarExpanded, onTap: () {
//                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ScheduledSessionsPage(doctor: doctor)));
//                 }),
//                 _SidebarItem(icon: Icons.chat, label: 'Sessions', isSelected: false, showLabel: isSidebarExpanded, onTap: () {
//                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScheduleMeetingPage()));
//                 }),
//                 _SidebarItem(icon: Icons.person, label: 'Profile', isSelected: true, showLabel: isSidebarExpanded, onTap: () {}),
//                 _SidebarItem(icon: Icons.settings, label: 'Settings', isSelected: false, showLabel: isSidebarExpanded, onTap: () {}),
//                 const Spacer(),
//                 _SidebarItem(icon: Icons.help_outline, label: 'Help', isSelected: false, showLabel: isSidebarExpanded, onTap: () {}),
//                 _SidebarItem(icon: Icons.logout, label: 'Log out', isSelected: false, showLabel: isSidebarExpanded, onTap: () {
//                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupPersonalScreen()));
//                 }),
//                 const SizedBox(height: 20),
//                 IconButton(
//                   icon: Icon(isSidebarExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios),
//                   onPressed: () => setState(() => isSidebarExpanded = !isSidebarExpanded),
//                 ),
//               ],
//             ),
//           ),

//           // Main Content
//           Expanded(
//             child: Container(
//               decoration: const BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage('assets/images/Home_Page_BG.png'),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(40),
//                 child: SingleChildScrollView(
//                   child: Container(
//                     padding: const EdgeInsets.all(32),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.9),
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10)),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Profile Header
//                         Row(
//                           children: [
//                             CircleAvatar(
//                               radius: 36,
//                               backgroundImage: doctor?.profileUrl != null
//                                   ? NetworkImage(doctor!.profileUrl!)
//                                   : null,
//                               child: doctor?.profileUrl == null ? const Icon(Icons.person, size: 36) : null,
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     doctor?.personalInfo.fullName ?? '',
//                                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     doctor?.role ?? 'Therapist',
//                                     style: const TextStyle(color: Colors.black54),
//                                   ),
//                                   const SizedBox(height: 2),
//                                   Text(
//                                     doctor?.personalInfo.timeZone ?? '',
//                                     style: const TextStyle(color: Colors.black54, fontSize: 12),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             ElevatedButton(
//                               onPressed: () {
//                                 // TODO: implement photo upload
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: buttonColor,
//                                 foregroundColor: Colors.white,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               ),
//                               child: const Text('Upload New Photo'),
//                             ),
//                             const SizedBox(width: 12),
//                             OutlinedButton(
//                               onPressed: () {
//                                 // TODO: implement delete photo
//                               },
//                               child: const Text('Delete'),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 24),

//                         // Form Fields
//                         Wrap(
//                           spacing: 20,
//                           runSpacing: 20,
//                           children: [
//                             SizedBox(
//                               width: 300,
//                               child: _buildField('First Name', 'eg. Alaa', controller: _firstNameController),
//                             ),
//                             SizedBox(
//                               width: 300,
//                               child: _buildField('Last Name', 'eg. Mohamed', controller: _lastNameController),
//                             ),
//                             SizedBox(
//                               width: 620,
//                               child: _buildField('User Name', 'eg. alaa.mohamed', controller: _userNameController),
//                             ),
//                             SizedBox(
//                               width: 300,
//                               child: _buildField('Email Address', 'eg. you@domain.com', controller: _emailController),
//                             ),
//                             SizedBox(
//                               width: 300,
//                               child: _buildField('Phone Number', 'eg. +123456789', controller: _phoneController),
//                             ),
//                             SizedBox(
//                               width: 620,
//                               child: _buildField('Location', 'eg. Cairo, Egypt', controller: _locationController),
//                             ),
//                             SizedBox(
//                               width: 300,
//                               child: _buildField('Time Zone', 'eg. UTC +3', controller: _timeZoneController),
//                             ),
//                             SizedBox(
//                               width: 300,
//                               child: _buildField('Current Password', '', controller: _currentPasswordController, obscureText: true),
//                             ),
//                             SizedBox(
//                               width: 300,
//                               child: _buildField('New Password', '', controller: _newPasswordController, obscureText: true),
//                             ),
//                             SizedBox(
//                               width: 620,
//                               child: _buildField('Confirm New Password', '', controller: _confirmPasswordController, obscureText: true),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 30),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             OutlinedButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                             const SizedBox(width: 16),
//                             ElevatedButton(
//                               onPressed: () async {
//                                 // TODO: implement saving updated profile
//                                 // gather fields and call DoctorService.updateProfile(...)
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: buttonColor,
//                                 foregroundColor: Colors.white,
//                                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                               ),
//                               child: const Text('Save Changes'),
//                             ),
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildField(String label, String hint,
//       {required TextEditingController controller, bool obscureText = false}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//         const SizedBox(height: 6),
//         TextField(
//           controller: controller,
//           obscureText: obscureText,
//           decoration: InputDecoration(
//             hintText: hint,
//             border:
//                 OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _SidebarItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isSelected;
//   final bool showLabel;
//   final VoidCallback onTap;

//   const _SidebarItem({
//     required this.icon,
//     required this.label,
//     required this.isSelected,
//     required this.showLabel,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final bg = isSelected ? const Color(0xFFECEBFF) : Colors.transparent;
//     final iconColor = isSelected ? const Color(0xFF5A6BFF) : Colors.grey;
//     final textColor = isSelected ? const Color(0xFF5A6BFF) : Colors.black;
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: iconColor),
//         title: showLabel
//             ? Text(label,
//                 style: TextStyle(
//                     fontWeight: FontWeight.w500, color: textColor))
//             : null,
//         onTap: onTap,
//       ),
//     );
//   }
// }