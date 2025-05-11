import 'package:flutter/material.dart';
import 'package:ui_screens_grad/screens/DoctorModule/login.dart';
import 'package:ui_screens_grad/services/doctor_service.dart';

import '/models/doctor.dart';

class SignupUploadsScreen extends StatefulWidget {
  final PersonalInfo personalInfo;
  final String licenseNumber, workplace, yearsOfExp, password;

  const SignupUploadsScreen({
    Key? key,
    required this.personalInfo,
    required this.licenseNumber,
    required this.workplace,
    required this.yearsOfExp,
    required this.password,
  }) : super(key: key);

  @override
  _SignupUploadsScreenState createState() => _SignupUploadsScreenState();
}

class _SignupUploadsScreenState extends State<SignupUploadsScreen> {
  String? medicalLicenseId;
  String? degreeCertId;
  String? specialCertId;
  String? syndicateId;
  String? nationalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFBEA9F9), Color(0xFFB4E5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Container(
                  width: 900,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.15),
                        blurRadius: 35,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.arrow_back,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Required Uploads for Verification',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius:
                                            BorderRadius.circular(2)))),
                            const Expanded(flex: 2, child: SizedBox()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Upload fields omitted details for brevity
                      // Assume methods pickFileAndUpload() returns a Future<String> ObjectId

                      ElevatedButton(
                        onPressed: () async {
                          // Set uploads in provider
                          // final provider = context.read<DoctorProvider>();
                          // provider.setUploads(
                          //   VerificationDocuments(
                          //     medicalLicense: medicalLicenseId ?? '',
                          //     degreeCertificate: degreeCertId ?? '',
                          //     specializationCertificate: specialCertId ?? '',
                          //     syndicateCard: syndicateId ?? '',
                          //     National_ID: nationalId ?? '',
                          //     nationalId: '',
                          //   ),
                          // );
                          VerificationDocuments verifiedDocuments =
                              VerificationDocuments(
                                  medicalLicense: medicalLicenseId ?? "",
                                  degreeCertificate: degreeCertId ?? '',
                                  specializationCertificate:
                                      specialCertId ?? '',
                                  syndicateCard: "syndicateCard",
                                  National_ID: nationalId ?? "");
                          Doctor docUser = Doctor(
                            personalInfo: widget.personalInfo,
                            licenseNumber: widget.licenseNumber,
                            workplace: widget.workplace,
                            yearsOfExperience: widget.yearsOfExp,
                            // verificationDocuments: verifiedDocuments,
                            password: widget.password,
                            patientIDs: [],
                          );
                          // Submit all data
                          try {
                            String docId =
                                await DoctorService().createDoctor(docUser);
                            print(docId);

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: \$e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F3C58),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
