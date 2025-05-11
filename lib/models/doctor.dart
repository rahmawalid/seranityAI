class PersonalInfo {
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String email;
  final String phoneNumber;
  final String specialization;
  final String? profilePicture;

  PersonalInfo({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.email,
    required this.phoneNumber,
    required this.specialization,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'email': email,
        'phone_number': phoneNumber,
        'specialization': specialization,
        'profile_picture': profilePicture,
      };

  factory PersonalInfo.fromJson(dynamic json) {
    return PersonalInfo(
      fullName: json['full_name'] as String,
      dateOfBirth: json['date_of_birth'] as String,
      gender: json['gender'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      specialization: json['specialization'] as String,
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

class VerificationDocuments {
  final String medicalLicense;
  final String degreeCertificate;
  final String syndicateCard;
  final String specializationCertificate;
  final String National_ID;

  VerificationDocuments({
    required this.medicalLicense,
    required this.degreeCertificate,
    required this.syndicateCard,
    required this.specializationCertificate,
    required this.National_ID,
  });

  Map<String, dynamic> toJson() => {
        'medical_license': medicalLicense,
        'degree_certificate': degreeCertificate,
        'syndicate_card': syndicateCard,
        'specialization_certificate': specializationCertificate,
        'National_ID': National_ID,
      };

  factory VerificationDocuments.fromJson(dynamic json) {
    return VerificationDocuments(
      medicalLicense: json['medical_license'] as String,
      degreeCertificate: json['degree_certificate'] as String,
      syndicateCard: json['syndicate_card'] as String,
      specializationCertificate: json['specialization_certificate'] as String,
      National_ID: json['National_ID'] as String,
    );
  }
}

class Doctor {
  final PersonalInfo personalInfo;
  final String licenseNumber;
  final String? workplace;
  final String? yearsOfExperience;
  final String password;
  final List<int>? patientIDs;
  final String? doctorID;

  Doctor({
    required this.personalInfo,
    required this.licenseNumber,
    this.workplace,
    this.yearsOfExperience,
    required this.password,
    this.patientIDs,
    this.doctorID,
  });

  Map<String, dynamic> toJson() => {
        'personal_info': personalInfo.toJson(),
        'license_number': licenseNumber,
        'workplace': workplace,
        'years_of_experience': yearsOfExperience,
        'password': password,
        'patientIDs': patientIDs,
        'doctor_ID': doctorID,
      };

  factory Doctor.fromJson(dynamic json) {
    return Doctor(
      personalInfo: PersonalInfo.fromJson(json['personal_info']),
      licenseNumber: json['license_number'] as String,
      workplace: json['workplace'] as String?,
      yearsOfExperience: json['years_of_experience'] as String?,
      password: json['password'] as String,
      patientIDs:
          (json['patientIDs'] as List<dynamic>?)?.map((e) => e as int).toList(),
      doctorID: json['doctor_ID'] as String?,
    );
  }
}
