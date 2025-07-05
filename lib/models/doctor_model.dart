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

class ScheduledSession {
  final int patientID;
  final DateTime datetime;
  final String? notes;
  final String? patientName; // This is added by backend controller
  final String? patientEmail; // This is added by backend controller

  ScheduledSession({
    required this.patientID,
    required this.datetime,
    this.notes,
    this.patientName,
    this.patientEmail,
  });

  factory ScheduledSession.fromJson(Map<String, dynamic> json) {
    return ScheduledSession(
      patientID: json['patientID'] as int,
      datetime: DateTime.parse(json['datetime'] as String),
      notes: json['notes'] as String?,
      patientName: json['patientName'] as String?,
      patientEmail: json['patientEmail'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'patientID': patientID,
        'datetime': datetime.toIso8601String(),
        'notes': notes,
        'patientName': patientName,
        'patientEmail': patientEmail,
      };
}

class Doctor {
  final PersonalInfo personalInfo;
  final String licenseNumber;
  final String? workplace;
  final String? yearsOfExperience;
  final String password;
  final List<int>? patientIDs;
  final String? doctorID; // Maps to backend's doctor_ID
  final List<ScheduledSession>? scheduledSessions;
  final bool emailVerified;
  final String? verificationToken;
  final DateTime? tokenCreatedAt;

  Doctor({
    required this.personalInfo,
    required this.licenseNumber,
    this.workplace,
    this.yearsOfExperience,
    required this.password,
    this.patientIDs,
    this.doctorID,
    this.scheduledSessions,
    required this.emailVerified,
    this.verificationToken,
    this.tokenCreatedAt,
  });

  factory Doctor.fromJson(dynamic json) {
    // Parse scheduledSessions if present
    List<ScheduledSession>? sessions;
    if (json['scheduledSessions'] != null) {
      sessions = (json['scheduledSessions'] as List)
          .map((e) => ScheduledSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Doctor(
      personalInfo: PersonalInfo.fromJson(json['personal_info']),
      licenseNumber: json['license_number'] as String,
      workplace: json['workplace'] as String?,
      yearsOfExperience: json['years_of_experience'] as String?,
      password: json['password'] as String? ??
          '', // Backend removes password in responses
      patientIDs:
          (json['patientIDs'] as List<dynamic>?)?.map((e) => e as int).toList(),
      doctorID: json['doctor_ID'] as String?, // Backend uses doctor_ID
      scheduledSessions: sessions,
      emailVerified: json['email_verified'] as bool? ?? false,
      verificationToken: json['verification_token'] as String?,
      tokenCreatedAt: json['token_created_at'] != null
          ? DateTime.parse(json['token_created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'personal_info': personalInfo.toJson(),
      'license_number': licenseNumber,
      'workplace': workplace,
      'years_of_experience': yearsOfExperience,
      'password': password,
      'patientIDs': patientIDs,
      'doctor_ID': doctorID, // Backend expects doctor_ID
      'email_verified': emailVerified,
      'verification_token': verificationToken,
      'token_created_at': tokenCreatedAt?.toIso8601String(),
    };

    if (scheduledSessions != null) {
      map['scheduledSessions'] =
          scheduledSessions!.map((s) => s.toJson()).toList();
    }

    return map;
  }
}
