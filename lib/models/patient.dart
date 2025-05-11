import 'dart:io';

class EmergencyContact {
  final String? name;
  final String? phone;
  final String? relation;

  EmergencyContact({
    this.name,
    this.phone,
    this.relation,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      relation: json['relation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relation': relation,
      };
}

class ContactInformation {
  final String? email;
  final String? phoneNumber;
  final EmergencyContact? emergencyContact;

  ContactInformation({
    this.email,
    this.phoneNumber,
    this.emergencyContact,
  });

  factory ContactInformation.fromJson(Map<String, dynamic> json) {
    return ContactInformation(
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      emergencyContact: json['emergency_contact'] != null
          ? EmergencyContact.fromJson(
              json['emergency_contact'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'phone_number': phoneNumber,
        'emergency_contact': emergencyContact?.toJson(),
      };
}

class HealthInfo {
  final String? currentMedications;
  final String? familyHistoryOfMentalIllness;
  final String? physicalHealthConditions;
  final String? previousDiagnoses;
  final String? substanceUse;

  HealthInfo({
    this.currentMedications,
    this.familyHistoryOfMentalIllness,
    this.physicalHealthConditions,
    this.previousDiagnoses,
    this.substanceUse,
  });

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      currentMedications: json['current_medications'] as String?,
      familyHistoryOfMentalIllness:
          json['family_history_of_mental_illness'] as String?,
      physicalHealthConditions: json['physical_health_conditions'] as String?,
      previousDiagnoses: json['previous_diagnoses'] as String?,
      substanceUse: json['substance_use'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'current_medications': currentMedications,
        'family_history_of_mental_illness': familyHistoryOfMentalIllness,
        'physical_health_conditions': physicalHealthConditions,
        'previous_diagnoses': previousDiagnoses,
        'substance_use': substanceUse,
      };
}

class TherapyInfo {
  final String? reasonForTherapy;

  TherapyInfo({this.reasonForTherapy});

  factory TherapyInfo.fromJson(Map<String, dynamic> json) {
    return TherapyInfo(
      reasonForTherapy: json['reason_for_therapy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'reason_for_therapy': reasonForTherapy,
      };
}

class PersonalInfo {
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? occupation;
  final String? maritalStatus;
  final String? location;
  final ContactInformation? contactInformation;
  final HealthInfo? healthInfo;
  final TherapyInfo? therapyInfo;

  PersonalInfo({
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.occupation,
    this.maritalStatus,
    this.location,
    this.contactInformation,
    this.healthInfo,
    this.therapyInfo,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      fullName: json['fullName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      occupation: json['occupation'] as String?,
      maritalStatus: json['marital_status'] as String?,
      location: json['location'] as String?,
      contactInformation: json['contact_information'] != null
          ? ContactInformation.fromJson(
              json['contact_information'] as Map<String, dynamic>)
          : null,
      healthInfo: json['health_info'] != null
          ? HealthInfo.fromJson(json['health_info'] as Map<String, dynamic>)
          : null,
      therapyInfo: json['therapy_info'] != null
          ? TherapyInfo.fromJson(json['therapy_info'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'occupation': occupation,
        'marital_status': maritalStatus,
        'location': location,
        'contact_information': contactInformation?.toJson(),
        'health_info': healthInfo?.toJson(),
        'therapy_info': therapyInfo?.toJson(),
      };
}

class Session {
  final int sessionId;
  final String? featureType;
  final DateTime? date;
  final String? time;
  final String? duration;
  final String? sessionType;
  final String? text;
  final String? report;
  final String? doctorNotes;
  final Map<String, dynamic>? featureData;
  final String? audioFiles;
  final String? videoFiles;
  final Map<String, String>? modelFiles;

  Session({
    required this.sessionId,
    this.featureType,
    this.date,
    this.time,
    this.duration,
    this.sessionType,
    this.text,
    this.report,
    this.doctorNotes,
    this.featureData,
    this.audioFiles,
    this.videoFiles,
    this.modelFiles,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['session_id'] as int,
      featureType: json['featureType'] as String?,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      time: json['time'] as String?,
      duration: json['duration'] as String?,
      sessionType: json['sessionType'] as String?,
      text: json['text'] as String?,
      report: json['report'] as String?,
      doctorNotes: json['doctorNotes'] as String?,
      featureData: json['featureData'] as Map<String, dynamic>?,
      audioFiles: json['audioFiles'] as String?,
      videoFiles: json['videoFiles'] as String?,
      modelFiles: (json['model_files'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'featureType': featureType,
        'date': date?.toIso8601String(),
        'time': time,
        'duration': duration,
        'sessionType': sessionType,
        'text': text,
        'report': report,
        'doctorNotes': doctorNotes,
        'featureData': featureData,
        'audioFiles': audioFiles,
        'videoFiles': videoFiles,
        'model_files': modelFiles,
      };
}

class Patient {
  final int patientID;
  final String? doctorID;
  final PersonalInfo personalInfo;
  final DateTime? registrationDate;
  final String? status;
  final List<Session> sessions;

  Patient({
    required this.patientID,
    required this.personalInfo,
    this.registrationDate,
    this.status,
    this.sessions = const [],
    this.doctorID,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? input) {
      if (input == null) return null;
      try {
        return DateTime.parse(input);
      } catch (_) {
        // fallback for RFC-1123 strings like "Thu, 01 May 2025 09:00:00 GMT"
        try {
          return HttpDate.parse(input);
        } catch (_) {
          return null;
        }
      }
    }

    return Patient(
      patientID: json['patientID'] as int,
      doctorID: json['doctorID'] as String,
      personalInfo:
          PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>),
      registrationDate: parseDate(json['registration_date'] as String?),
      status: json['status'] as String?,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => Session.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'patientID': patientID,
        'doctorID': doctorID,
        'personalInfo': personalInfo.toJson(),
        'registration_date': registrationDate?.toIso8601String(),
        'status': status,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };
}
