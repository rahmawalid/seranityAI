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
          ? EmergencyContact.fromJson(json['emergency_contact'] as Map<String, dynamic>)
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

  factory PersonalInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PersonalInfo();
    }
    
    return PersonalInfo(
      fullName: json['fullName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      occupation: json['occupation'] as String?,
      maritalStatus: json['marital_status'] as String?,
      location: json['location'] as String?,
      contactInformation: json['contact_information'] != null
          ? ContactInformation.fromJson(json['contact_information'] as Map<String, dynamic>)
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
  final int? sessionId;
  final String? featureType;
  final DateTime? date;
  final String? time;
  final String? duration;
  final String? sessionType;
  final String? text;
  final String? report;
  final String? transcription;
  final List<String>? doctorNotesImages;
  final Map<String, dynamic>? featureData;
  final String? audioFiles;
  final String? videoFiles;
  final Map<String, String>? modelFiles;

  Session({
    this.sessionId,
    this.featureType,
    this.date,
    this.time,
    this.duration,
    this.sessionType,
    this.text,
    this.report,
    this.transcription,
    this.doctorNotesImages,
    this.featureData,
    this.audioFiles,
    this.videoFiles,
    this.modelFiles,
  });

  // Safe helper methods
  static String? _safeParseObjectId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map && value.containsKey(r'$oid')) {
      final oid = value[r'$oid'];
      return oid is String && oid.isNotEmpty ? oid : null;
    }
    return value.toString().isEmpty ? null : value.toString();
  }

  static List<String>? _safeParseStringList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    
    final result = <String>[];
    for (final item in value) {
      final parsed = _safeParseObjectId(item);
      if (parsed != null && parsed.isNotEmpty) {
        result.add(parsed);
      }
    }
    return result.isEmpty ? null : result;
  }

  static DateTime? _safeParseDate(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    if (value.isEmpty) return null;
    
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static Map<String, String>? _safeParseStringMap(dynamic value) {
    if (value == null) return null;
    if (value is! Map) return null;
    
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key is String) {
        final parsedValue = _safeParseObjectId(entry.value);
        if (parsedValue != null) {
          result[entry.key as String] = parsedValue;
        }
      }
    }
    return result.isEmpty ? null : result;
  }

  factory Session.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Session();
    }

    return Session(
      sessionId: json['session_id'] as int?,
      featureType: json['featureType'] as String?,
      date: _safeParseDate(json['date']),
      time: json['time'] as String?,
      duration: json['duration'] as String?,
      sessionType: json['sessionType'] as String?,
      text: json['text'] as String?,
      report: _safeParseObjectId(json['report']),
      transcription: _safeParseObjectId(json['transcription']),
      doctorNotesImages: _safeParseStringList(json['doctorNotesImages']) ?? 
                        _safeParseStringList(json['doctor_notes_images']),
      featureData: json['featureData'] as Map<String, dynamic>?,
      audioFiles: _safeParseObjectId(json['audioFiles']),
      videoFiles: _safeParseObjectId(json['videoFiles']),
      modelFiles: _safeParseStringMap(json['model_files']),
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
        'transcription': transcription,
        'doctorNotesImages': doctorNotesImages,
        'featureData': featureData,
        'audioFiles': audioFiles,
        'videoFiles': videoFiles,
        'model_files': modelFiles,
      };
}

class Patient {
  final String? patientID;
  final String? doctorID;
  final PersonalInfo personalInfo;
  final DateTime? registrationDate;
  final String? status;
  final List<Session> sessions;

  Patient({
    this.patientID,
    this.doctorID,
    required this.personalInfo,
    this.registrationDate,
    this.status,
    this.sessions = const [],
  });

  // Safe helper methods for Patient
  static DateTime? _safeParseDate(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    if (value.isEmpty) return null;
    
    try {
      return DateTime.parse(value);
    } catch (_) {
      try {
        return HttpDate.parse(value);
      } catch (_) {
        return null;
      }
    }
  }

  static List<Session> _safeParseSessions(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    
    final result = <Session>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(Session.fromJson(item));
        } catch (e) {
          // Skip invalid session, don't fail the entire patient parsing
          print('Warning: Failed to parse session: $e');
        }
      }
    }
    return result;
  }

  factory Patient.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Patient JSON cannot be null');
    }

    return Patient(
      patientID: json['patientID'] as String?,
      doctorID: json['doctorID'] as String?,
      personalInfo: PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>?),
      registrationDate: _safeParseDate(json['registration_date']),
      status: json['status'] as String?,
      sessions: _safeParseSessions(json['sessions']),
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