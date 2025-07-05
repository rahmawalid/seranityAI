import 'dart:io';
import 'patient_model.dart'; // Import your corrected Patient model

/// Extension on your existing Session model for doctor notes functionality
extension SessionDoctorNotes on Session {
  /// Check if session has doctor notes
  bool get hasDoctorNotes => doctorNotesImages?.isNotEmpty ?? false;

  /// Get count of doctor notes
  int get doctorNotesCount => doctorNotesImages?.length ?? 0;

  /// Check if session is ready for enhanced analysis
  bool get isReadyForEnhancedAnalysis {
    final hasNotes = hasDoctorNotes;
    final hasFer = featureData?['FER'] != null;
    final hasSpeech = featureData?['Speech'] != null;
    return hasNotes && (hasFer || hasSpeech);
  }

  /// Get analysis type based on available data
  String get analysisType {
    final hasNotes = hasDoctorNotes;
    final hasFer = featureData?['FER'] != null;
    final hasSpeech = featureData?['Speech'] != null;

    if (hasFer && hasNotes) return 'comprehensive_with_notes';
    if (hasSpeech && hasNotes) return 'speech_with_notes';
    if (hasFer) return 'comprehensive';
    if (hasSpeech) return 'speech_only';
    return 'basic';
  }
}

/// Simple doctor note info (minimal metadata)
/// Matches what backend returns in notes_info array
class DoctorNoteInfo {
  final String fileId;
  final String filename;
  final DateTime uploadDate;
  final int sizeBytes;

  const DoctorNoteInfo({
    required this.fileId,
    required this.filename,
    required this.uploadDate,
    required this.sizeBytes,
  });

  factory DoctorNoteInfo.fromJson(Map<String, dynamic> json) {
    return DoctorNoteInfo(
      fileId: json['file_id'] as String,
      filename: json['filename'] as String,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      sizeBytes: json['length'] as int,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024)
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Generic API response wrapper (used by all endpoints)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }
}

/// Upload result - what GET upload endpoint returns
/// Backend returns different structure than expected
class UploadResult {
  final List<String> fileIds;
  final String patientId;
  final int sessionId;
  final int uploadedCount;
  final ValidationSummary? validationSummary; // Added - backend includes this

  const UploadResult({
    required this.fileIds,
    required this.patientId,
    required this.sessionId,
    required this.uploadedCount,
    this.validationSummary,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    // Backend returns data under 'data' key for uploads
    final data = json['data'] as Map<String, dynamic>;
    return UploadResult(
      fileIds: (data['file_ids'] as List).cast<String>(),
      patientId: data['patient_id'] as String, // Changed to String
      sessionId: data['session_id'] as int,
      uploadedCount: data['uploaded_files'] as int,
      validationSummary: data['validation_summary'] != null
          ? ValidationSummary.fromJson(data['validation_summary'])
          : null,
    );
  }
}

/// Validation summary from upload response
class ValidationSummary {
  final int totalFiles;
  final int validFiles;
  final int invalidFiles;

  const ValidationSummary({
    required this.totalFiles,
    required this.validFiles,
    required this.invalidFiles,
  });

  factory ValidationSummary.fromJson(Map<String, dynamic> json) {
    return ValidationSummary(
      totalFiles: json['total_files'] as int,
      validFiles: json['valid_files'] as int,
      invalidFiles: json['invalid_files'] as int,
    );
  }
}

/// Doctor notes list - what the GET endpoint returns
/// Matches backend response structure exactly
class DoctorNotesList {
  final String patientId;
  final int sessionId;
  final int notesCount;
  final bool hasNotes;
  final List<DoctorNoteInfo> notes;

  const DoctorNotesList({
    required this.patientId,
    required this.sessionId,
    required this.notesCount,
    required this.hasNotes,
    required this.notes,
  });

  factory DoctorNotesList.fromJson(Map<String, dynamic> json) {
    // Backend returns data under 'data' key
    final data = json['data'] as Map<String, dynamic>;
    return DoctorNotesList(
      patientId: data['patient_id'] as String, // Changed to String
      sessionId: data['session_id'] as int,
      notesCount: data['notes_count'] as int,
      hasNotes: data['has_notes'] as bool,
      notes: (data['notes'] as List)
          .map((note) => DoctorNoteInfo.fromJson(note))
          .toList(),
    );
  }
}

/// Analysis capabilities - what the analysis endpoint returns
/// Backend structure appears different than original model expected
class AnalysisInfo {
  final String analysisType;
  final String promptType;
  final bool hasFer;
  final bool hasSpeech;
  final bool hasDoctorNotes;
  final String recommendation;
  final int doctorNotesCount;
  final String analysisReadiness;

  const AnalysisInfo({
    required this.analysisType,
    required this.promptType,
    required this.hasFer,
    required this.hasSpeech,
    required this.hasDoctorNotes,
    required this.recommendation,
    required this.doctorNotesCount,
    required this.analysisReadiness,
  });

  factory AnalysisInfo.fromJson(Map<String, dynamic> json) {
    // Backend returns data under 'data' key
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final dataAvailability =
        data['data_availability'] as Map<String, dynamic>? ?? {};
    final analysisReadiness =
        data['analysis_readiness'] as Map<String, dynamic>? ?? {};

    return AnalysisInfo(
      analysisType: data['analysis_type'] as String? ?? 'basic',
      promptType: data['prompt_type'] as String? ?? 'standard',
      hasFer: dataAvailability['has_fer'] as bool? ?? false,
      hasSpeech: dataAvailability['has_speech'] as bool? ?? false,
      hasDoctorNotes: dataAvailability['has_doctor_notes'] as bool? ?? false,
      doctorNotesCount: dataAvailability['doctor_notes_count'] as int? ?? 0,
      recommendation:
          data['recommendation'] as String? ?? 'No recommendations available',
      analysisReadiness:
          analysisReadiness['level'] as String? ?? 'insufficient',
    );
  }

  String get analysisTypeDisplay {
    switch (analysisType) {
      case 'comprehensive_with_notes':
        return 'Full Analysis + Doctor Notes';
      case 'speech_with_notes':
        return 'Speech Analysis + Doctor Notes';
      case 'comprehensive':
        return 'Full Analysis';
      case 'speech_only':
        return 'Speech Only';
      default:
        return 'Basic Analysis';
    }
  }

  String get readinessDisplay {
    switch (analysisReadiness) {
      case 'excellent':
        return 'Ready for Comprehensive Analysis';
      case 'good':
        return 'Ready for Enhanced Analysis';
      case 'fair':
        return 'Basic Analysis Available';
      case 'basic':
        return 'Limited Analysis Available';
      default:
        return 'Insufficient Data';
    }
  }
}

/// Patient summary response for doctor notes statistics
class PatientDoctorNotesSummary {
  final String patientId;
  final int totalSessions;
  final int sessionsWithNotes;
  final int totalNotes;
  final double coveragePercentage;
  final Map<String, SessionNoteSummary> notesBySession;

  const PatientDoctorNotesSummary({
    required this.patientId,
    required this.totalSessions,
    required this.sessionsWithNotes,
    required this.totalNotes,
    required this.coveragePercentage,
    required this.notesBySession,
  });

  factory PatientDoctorNotesSummary.fromJson(Map<String, dynamic> json) {
    // Backend returns nested structure
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final overview = data['overview'] as Map<String, dynamic>? ?? {};
    final sessionCoverage =
        data['session_coverage'] as Map<String, dynamic>? ?? {};
    final notesById =
        overview['notes_by_session'] as Map<String, dynamic>? ?? {};

    return PatientDoctorNotesSummary(
      patientId: overview['patient_id'] as String? ?? '',
      totalSessions: overview['total_sessions'] as int? ?? 0,
      sessionsWithNotes: overview['sessions_with_notes'] as int? ?? 0,
      totalNotes: overview['total_notes'] as int? ?? 0,
      coveragePercentage:
          sessionCoverage['coverage_percentage'] as double? ?? 0.0,
      notesBySession: notesById.map((key, value) => MapEntry(
          key, SessionNoteSummary.fromJson(value as Map<String, dynamic>))),
    );
  }
}

/// Summary for individual session's notes
class SessionNoteSummary {
  final int sessionId;
  final int notesCount;
  final List<String> fileIds;
  final DateTime? sessionDate;
  final String? sessionType;

  const SessionNoteSummary({
    required this.sessionId,
    required this.notesCount,
    required this.fileIds,
    this.sessionDate,
    this.sessionType,
  });

  factory SessionNoteSummary.fromJson(Map<String, dynamic> json) {
    return SessionNoteSummary(
      sessionId: json['session_id'] as int? ?? 0,
      notesCount: json['count'] as int? ?? 0,
      fileIds: (json['file_ids'] as List?)?.cast<String>() ?? [],
      sessionDate: json['session_date'] != null
          ? DateTime.parse(json['session_date'] as String)
          : null,
      sessionType: json['session_type'] as String?,
    );
  }
}

/// File validation result (for upload feedback)
class FileValidationResult {
  final bool isValid;
  final String? error;
  final String filename;

  const FileValidationResult({
    required this.isValid,
    this.error,
    required this.filename,
  });

  static FileValidationResult validate(File file) {
    final filename = file.path.split('/').last;
    final extension = filename.toLowerCase().split('.').last;

    // Updated to match backend supported formats exactly
    const supportedExtensions = ['jpg', 'jpeg', 'png', 'bmp', 'tiff', 'webp'];

    if (!supportedExtensions.contains(extension)) {
      return FileValidationResult(
        isValid: false,
        error:
            'Unsupported file type: .$extension. Supported: ${supportedExtensions.join(', ')}',
        filename: filename,
      );
    }

    final sizeBytes = file.lengthSync();
    const maxSizeBytes = 10 * 1024 * 1024; // 10MB - matches backend

    if (sizeBytes > maxSizeBytes) {
      return FileValidationResult(
        isValid: false,
        error:
            'File too large: ${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB (max 10MB)',
        filename: filename,
      );
    }

    return FileValidationResult(
      isValid: true,
      filename: filename,
    );
  }
}

/// Supported formats info from backend
/// Supported formats info from backend
class SupportedFormats {
  final List<String> images;
  final int maxFileSizeMb;
  final int maxFilesPerUpload;
  final List<String> recommendedFormats;

  const SupportedFormats({
    required this.images,
    required this.maxFileSizeMb,
    required this.maxFilesPerUpload,
    required this.recommendedFormats,
  });

  factory SupportedFormats.fromJson(Map<String, dynamic> json) {
    final supportedFormats = json['supported_formats'] as Map<String, dynamic>;
    return SupportedFormats(
      images: (supportedFormats['images'] as List).cast<String>(),
      maxFileSizeMb: supportedFormats['max_file_size_mb'] as int,
      maxFilesPerUpload: supportedFormats['max_files_per_upload'] as int,
      recommendedFormats:
          (supportedFormats['recommended_formats'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supported_formats': {
        'images': images,
        'max_file_size_mb': maxFileSizeMb,
        'max_files_per_upload': maxFilesPerUpload,
        'recommended_formats': recommendedFormats,
      }
    };
  }

  /// Get supported extensions (alias for images property)
  List<String> get extensions => images;

  /// Check if a file extension is supported
  bool isExtensionSupported(String extension) {
    return images.contains(extension.toLowerCase());
  }

  /// Get formatted file size limit
  String get maxFileSizeFormatted => '${maxFileSizeMb}MB';

  /// Get supported extensions as a formatted string
  String get extensionsFormatted => images.join(', ');

  /// Check if file extension is supported by filename
  bool isFileSupported(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return images.contains(extension);
  }

  /// Get max file size in bytes
  int get maxFileSizeBytes => maxFileSizeMb * 1024 * 1024;
}

/// Enhancement readiness response
class EnhancementReadiness {
  final bool readyForEnhancement;
  final String enhancementType;
  final int notesCount;
  final bool canEnhanceFer;
  final bool canEnhanceSpeech;
  final String recommendation;

  const EnhancementReadiness({
    required this.readyForEnhancement,
    required this.enhancementType,
    required this.notesCount,
    required this.canEnhanceFer,
    required this.canEnhanceSpeech,
    required this.recommendation,
  });

  factory EnhancementReadiness.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final enhancementStatus =
        data['enhancement_status'] as Map<String, dynamic>? ?? {};

    return EnhancementReadiness(
      readyForEnhancement: data['ready_for_enhancement'] as bool? ?? false,
      enhancementType:
          enhancementStatus['enhancement_type'] as String? ?? 'none',
      notesCount: enhancementStatus['notes_count'] as int? ?? 0,
      canEnhanceFer: enhancementStatus['can_enhance_fer'] as bool? ?? false,
      canEnhanceSpeech:
          enhancementStatus['can_enhance_speech'] as bool? ?? false,
      recommendation: data['recommendation'] as String? ?? '',
    );
  }

  String get enhancementTypeDisplay {
    switch (enhancementType) {
      case 'comprehensive_with_notes':
        return 'Full Enhancement Available';
      case 'speech_with_notes':
        return 'Speech Enhancement Available';
      case 'notes_only':
        return 'Notes Only Enhancement';
      default:
        return 'No Enhancement Available';
    }
  }
}

/// Enhanced report generation result
class EnhancedReportResult {
  final String reportId;
  final String analysisType;
  final int doctorNotesCount;
  final String promptUsed;
  final bool imagesIncluded;
  final ReportFeatures featuresIncluded;

  const EnhancedReportResult({
    required this.reportId,
    required this.analysisType,
    required this.doctorNotesCount,
    required this.promptUsed,
    required this.imagesIncluded,
    required this.featuresIncluded,
  });

  factory EnhancedReportResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final features = data['features_included'] as Map<String, dynamic>? ?? {};

    return EnhancedReportResult(
      reportId: data['report_id'] as String? ?? '',
      analysisType: data['analysis_type'] as String? ?? '',
      doctorNotesCount: data['doctor_notes_count'] as int? ?? 0,
      promptUsed: data['prompt_used'] as String? ?? '',
      imagesIncluded: data['images_included'] as bool? ?? false,
      featuresIncluded: ReportFeatures.fromJson(features),
    );
  }

  /// Check if this is an enhanced report with doctor notes
  bool get isEnhancedReport => doctorNotesCount > 0 && promptUsed.contains('Doctor Notes');
  
  /// Check if analysis type includes doctor notes
  bool get usesNotesPrompt => analysisType.contains('_with_notes');
  
  /// Check if the correct doctor notes endpoint was used
  bool get isValidDoctorNotesReport {
    return usesNotesPrompt && 
           isEnhancedReport && 
           featuresIncluded.doctorNotes && 
           imagesIncluded;
  }
  
  /// Get verification status for debugging
  String get verificationStatus {
    final checks = <String>[];
    
    if (usesNotesPrompt) {
      checks.add('✅ Analysis type includes notes');
    } else {
      checks.add('❌ Analysis type missing notes: $analysisType');
    }
    
    if (isEnhancedReport) {
      checks.add('✅ Enhanced report confirmed');
    } else {
      checks.add('❌ Not enhanced report: prompt=$promptUsed, count=$doctorNotesCount');
    }
    
    if (featuresIncluded.doctorNotes) {
      checks.add('✅ Doctor notes feature enabled');
    } else {
      checks.add('❌ Doctor notes feature disabled');
    }
    
    if (imagesIncluded) {
      checks.add('✅ Images included in report');
    } else {
      checks.add('❌ Images not included');
    }
    
    return checks.join('\n');
  }
}


/// Report features included
class ReportFeatures {
  final bool doctorNotes;
  final bool ferAnalysis;
  final bool speechAnalysis;
  final bool mismatchAnalysis;

  const ReportFeatures({
    required this.doctorNotes,
    required this.ferAnalysis,
    required this.speechAnalysis,
    required this.mismatchAnalysis,
  });

  factory ReportFeatures.fromJson(Map<String, dynamic> json) {
    return ReportFeatures(
      doctorNotes: json['doctor_notes'] as bool? ?? false,
      ferAnalysis: json['fer_analysis'] as bool? ?? false,
      speechAnalysis: json['speech_analysis'] as bool? ?? false,
      mismatchAnalysis: json['mismatch_analysis'] as bool? ?? false,
    );
  }
}

/// Validation details from backend
class ValidationDetails {
  final List<ValidFileInfo> validFiles;
  final List<InvalidFileInfo> invalidFiles;
  final List<String> errors;

  const ValidationDetails({
    required this.validFiles,
    required this.invalidFiles,
    required this.errors,
  });

  factory ValidationDetails.fromJson(Map<String, dynamic> json) {
    return ValidationDetails(
      validFiles: (json['valid_files'] as List?)
              ?.map((file) => ValidFileInfo.fromJson(file))
              .toList() ??
          [],
      invalidFiles: (json['invalid_files'] as List?)
              ?.map((file) => InvalidFileInfo.fromJson(file))
              .toList() ??
          [],
      errors: (json['errors'] as List?)?.cast<String>() ?? [],
    );
  }
}

class ValidFileInfo {
  final int index;
  final String filename;
  final String status;

  const ValidFileInfo({
    required this.index,
    required this.filename,
    required this.status,
  });

  factory ValidFileInfo.fromJson(Map<String, dynamic> json) {
    return ValidFileInfo(
      index: json['index'] as int,
      filename: json['filename'] as String,
      status: json['status'] as String,
    );
  }
}

class InvalidFileInfo {
  final int index;
  final String filename;
  final String error;

  const InvalidFileInfo({
    required this.index,
    required this.filename,
    required this.error,
  });

  factory InvalidFileInfo.fromJson(Map<String, dynamic> json) {
    return InvalidFileInfo(
      index: json['index'] as int,
      filename: json['filename'] as String? ?? 'Unknown',
      error: json['error'] as String,
    );
  }
}
