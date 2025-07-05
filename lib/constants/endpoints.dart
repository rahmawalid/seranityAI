class ApiConstants {
  static const String baseUrl = 'http://127.0.0.1:5001';

  // ================================
  // DOCTOR MANAGEMENT ENDPOINTS
  // ================================

  // Authentication
  static const String createDoctor = '$baseUrl/create-doctor';
  static const String loginDoctor = '$baseUrl/login-doctor';
  static const String resendVerification = '$baseUrl/resend-verification';

  // Email Verification
  static String verifyEmail(String token) => '$baseUrl/verify-email/$token';
  static String checkToken(String token) => '$baseUrl/check-token/$token';

  // Doctor Profile
  static String getDoctor(String doctorId) => '$baseUrl/get-doctor/$doctorId';
  static String updateDoctorInfo(String doctorId) => '$baseUrl/update-doctor-info/$doctorId';
  static String updateDoctorPassword(String doctorId) => '$baseUrl/update-doctor-password/$doctorId';
  static String deleteDoctor(String doctorId) => '$baseUrl/delete-doctor/$doctorId';

  // File Uploads for Doctor
  static String uploadDoctorFile(String fileType, String doctorId) =>
      '$baseUrl/upload-doctor-file/$fileType/$doctorId';
  static String getVerificationFile(String fileType, String doctorId) =>
      '$baseUrl/get-verification-file/$fileType/$doctorId';
  static String getDoctorProfilePicture(String doctorId) =>
      '$baseUrl/get-profile-picture/$doctorId';

  // Doctor-Patient Management
  static String doctorPatients(String doctorId) => '$baseUrl/$doctorId/patients';
  static String addPatientForDoctor(String doctorId) => '$baseUrl/$doctorId/patients';

  // Session Scheduling
  static String scheduleSession(String doctorId) => '$baseUrl/schedule-session/$doctorId';
  static String getScheduledSessions(String doctorId) =>
      '$baseUrl/schedule-session/$doctorId/sessions';

  // Doctor Analytics
  static String getDoctorAnalytics(String doctorId) =>
      '$baseUrl/$doctorId/analytics/patients';

  // ================================
  // PATIENT MANAGEMENT ENDPOINTS
  // ================================

  static const String createPatient = '$baseUrl/create-patient';
  static String getPatientById(int patientId) => '$baseUrl/get-patient/$patientId';
  static String updatePatient(int patientId) => '$baseUrl/update-patient/$patientId';
  static String deletePatient(int patientId) => '$baseUrl/delete-patient/$patientId';
  static const String listPatients = '$baseUrl/list-patients';
  static String listPatientsByDoctor(String doctorId) => '$baseUrl/$doctorId/patients';

  // Session Management
  static String createSession(int patientId) => '$baseUrl/$patientId/sessions';
  static String getSessionById(int patientId, int sessionId) =>
      '$baseUrl/get-session/$patientId/$sessionId';

  // File Uploads for Patients
  static String uploadAudio(int patientId, int sessionId) =>
      '$baseUrl/upload-audio/$patientId/$sessionId';
  static String uploadVideo(int patientId, int sessionId) =>
      '$baseUrl/upload-video/$patientId/$sessionId';
  static String uploadReport(int patientId, int sessionId) =>
      '$baseUrl/upload-report/$patientId/$sessionId';

  // ================================
  // FER ANALYSIS ENDPOINTS
  // ================================

  static String ferAnalyzeAndSave(String fileId, int patientId, int sessionId) =>
      '$baseUrl/fer/analyze/$fileId/$patientId/$sessionId';
  static String ferResults(int patientId, int sessionId) =>
      '$baseUrl/fer/results/$patientId/$sessionId';
  static String ferStatus(int patientId, int sessionId) =>
      '$baseUrl/fer/status/$patientId/$sessionId';

  // ================================
  // SPEECH ANALYSIS ENDPOINTS
  // ================================

  static String uploadSpeechVideo(int patientId, int sessionId) =>
      '$baseUrl/upload-video/$patientId/$sessionId';
  
  static String analyzeSpeechAndTov(String fileId, int patientId, int sessionId) =>
      '$baseUrl/analyze/$fileId/$patientId/$sessionId';
  static String getSpeechStatus(int patientId, int sessionId) =>
      '$baseUrl/status/$patientId/$sessionId';
  static String getSpeechResults(int patientId, int sessionId) =>
      '$baseUrl/results/$patientId/$sessionId';

  // Speech Utilities
  static String validateSpeechFile(String fileId) => '$baseUrl/validate-file/$fileId';
  static String getSpeechCapabilities(int patientId, int sessionId) =>
      '$baseUrl/session-capabilities/$patientId/$sessionId';
  static const String speechHealth = '$baseUrl/health';
  static const String speechFormats = '$baseUrl/supported-formats';
  static String downloadSpeechReport(String reportId) =>
      '$baseUrl/download-report/$reportId';

  // ================================
  // TRANSCRIPTION ANALYSIS ENDPOINTS
  // ================================

  static String uploadTranscriptionVideo(int patientId, int sessionId) =>
      '$baseUrl/patients/$patientId/sessions/$sessionId/upload-transcription-video';
  static String analyzeTranscription(String fileId, int patientId, int sessionId) =>
      '$baseUrl/transcription/analyze/$fileId/$patientId/$sessionId';
  static String transcriptionStatus(int patientId, int sessionId) =>
      '$baseUrl/patients/$patientId/sessions/$sessionId/transcription-status';
  static String getTranscriptionsSummary(int patientId) =>
      '$baseUrl/patients/$patientId/transcriptions/summary';
  static String downloadTranscription(String transcriptionId) =>
      '$baseUrl/transcription/download/$transcriptionId';
  static String viewTranscription(String transcriptionId) =>
      '$baseUrl/transcription/view/$transcriptionId';
  static String validateTranscriptionFile(String fileId) =>
      '$baseUrl/transcription/validate-file/$fileId';
  static String getTranscriptionCapabilities(int patientId, int sessionId) =>
      '$baseUrl/transcription/session-capabilities/$patientId/$sessionId';
  static const String transcriptionHealth = '$baseUrl/transcription/health';
  static const String transcriptionFormats = '$baseUrl/transcription/formats';

  // ================================
  // UPDATED REPORT GENERATION ENDPOINTS
  // ================================

  // NEW: Advanced Report Generation (Using ReportService)
  static String generateAnalysisReport(int patientId, int sessionId) =>
      '$baseUrl/reports/generate/$patientId/$sessionId';
  static String getReportMetadata(int patientId, int sessionId) =>
      '$baseUrl/reports/metadata/$patientId/$sessionId';
  static String downloadSessionReport(int patientId, int sessionId) =>
      '$baseUrl/reports/download/$patientId/$sessionId';
  static String forceRegenerateReport(int patientId, int sessionId) =>
      '$baseUrl/reports/force-regenerate/$patientId/$sessionId';

  // NEW: Specific Analysis Types
  static String generateTovOnlyReport(int patientId, int sessionId) =>
      '$baseUrl/reports/tov-only/$patientId/$sessionId';
  static String generateComprehensiveReport(int patientId, int sessionId) =>
      '$baseUrl/reports/comprehensive/$patientId/$sessionId';

  // NEW: Report Management & Status
  static String getAnalysisCapabilities(int patientId, int sessionId) =>
      '$baseUrl/reports/capabilities/$patientId/$sessionId';
  static String getReportStatus(int patientId, int sessionId) =>
      '$baseUrl/reports/status/$patientId/$sessionId';

  // NEW: Enhanced Reports with Doctor Notes
  static String generateReportWithDoctorNotes(int patientId, int sessionId) =>
      '$baseUrl/reports/with-doctor-notes/$patientId/$sessionId';

  // LEGACY: Backward Compatibility (Deprecated but maintained)
  static String generateReport(int patientId, int sessionId) =>
      '$baseUrl/report/generate/$patientId/$sessionId';  // DEPRECATED
  static String downloadReport(String reportId) =>
      '$baseUrl/report/download/$reportId';  // Still used for direct report ID downloads
  static String viewReport(String fileId) => '$baseUrl/view-report/$fileId';
  static String getReportMetadataLegacy(int patientId, int sessionId) =>
      '$baseUrl/report/metadata/$patientId/$sessionId';  // DEPRECATED

  // NEW: Debug & Testing Endpoints
  static String debugReportData(int patientId, int sessionId) =>
      '$baseUrl/reports/debug/$patientId/$sessionId';
  static const String testReportPrompts = '$baseUrl/reports/test-prompts';

  // ================================
  // DOCTOR NOTES ENDPOINTS
  // ================================

  static String uploadDoctorNotes(int patientId, int sessionId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/doctor-notes/upload';
  static String getDoctorNotes(int patientId, int sessionId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/doctor-notes';
  static String getPatientDoctorNotesSummary(int patientId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/doctor-notes/summary';
  static String deleteDoctorNote(int patientId, int sessionId, String fileId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/doctor-notes/$fileId';
  static String clearAllDoctorNotes(int patientId, int sessionId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/doctor-notes/clear';
  static String downloadDoctorNote(String fileId) =>
      '$baseUrl/api/doctor-notes/doctor-notes/download/$fileId';
  static String getDoctorNotesAnalysisCapabilities(int patientId, int sessionId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/analysis-capabilities';
  static String prepareAnalysisData(int patientId, int sessionId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/prepare-analysis';
  static String checkEnhancementReadiness(int patientId, int sessionId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/enhancement-readiness';
  static String generateEnhancedReport(int patientId, int sessionId) =>
      '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/generate-enhanced-report';
  static const String doctorNotesHealth = '$baseUrl/api/doctor-notes/doctor-notes/health';

  static String uploadSingleDoctorNote(int patientId, int sessionId) =>
    '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/doctor-notes/upload-single';

  static const String validateDoctorNotesFiles = '$baseUrl/api/doctor-notes/doctor-notes/validate-files';

  static String integrateWithExistingReport(int patientId, int sessionId) =>
    '$baseUrl/api/doctor-notes/patient/$patientId/session/$sessionId/integrate-with-existing-report';
  
  static const String doctorNotesSupportedFormats = '$baseUrl/api/doctor-notes/doctor-notes/supported-formats';

  // ================================
  // AI CHAT & RAG ENDPOINTS
  // ================================

  static String chatWithPatient(int patientId) => '$baseUrl/chat/$patientId';
  static String rebuildKnowledgeBase(int patientId) => '$baseUrl/chat/$patientId/rebuild-kb';
  static String getKnowledgeBaseStatus(int patientId) => '$baseUrl/chat/$patientId/status';
  static String clearKnowledgeBase(int patientId) => '$baseUrl/chat/$patientId/clear-kb';
  static String getChatCapabilities(int patientId) => '$baseUrl/chat/$patientId/capabilities';
  static String getContextPreview(int patientId) => '$baseUrl/chat/$patientId/context-preview';
  static const String chatHealth = '$baseUrl/chat/health';
  static const String rebuildAllKnowledgeBases = '$baseUrl/chat/batch/rebuild-all';
  static const String clearAllKnowledgeBases = '$baseUrl/chat/batch/clear-all';

  // ================================
  // COMPREHENSIVE ANALYSIS WORKFLOW
  // ================================

  static String startComprehensiveAnalysis(int patientId, int sessionId) =>
      '$baseUrl/comprehensive/start/$patientId/$sessionId';
  static String getComprehensiveStatus(int patientId, int sessionId) =>
      '$baseUrl/comprehensive/status/$patientId/$sessionId';
  static String getComprehensiveResults(int patientId, int sessionId) =>
      '$baseUrl/comprehensive/results/$patientId/$sessionId';

  // ================================
  // FILE MANAGEMENT ENDPOINTS
  // ================================

  static String downloadFile(String fileId) => '$baseUrl/file/download/$fileId';
  static String viewFile(String fileId) => '$baseUrl/file/view/$fileId';
  static String getFileMetadata(String fileId) => '$baseUrl/file/metadata/$fileId';
  static const String uploadFile = '$baseUrl/file/upload';
  static String deleteFile(String fileId) => '$baseUrl/file/$fileId';
  static String downloadExcelFile(String fileId) => '$baseUrl/file/excel/$fileId';
  static String checkFileExists(String fileId) => '$baseUrl/file/exists/$fileId';
  static String getFileSize(String fileId) => '$baseUrl/file/size/$fileId';
  static const String supportedExtensions = '$baseUrl/file/supported-extensions';
  static const String fileList = '$baseUrl/file/list';
  static const String fileHealth = '$baseUrl/file/health';

  // ================================
  // SYSTEM HEALTH ENDPOINTS
  // ================================

  static const String healthCheck = '$baseUrl/health';
  static const String detailedStatus = '$baseUrl/status';

  // ================================
  // REPORT GENERATION HELPER METHODS
  // ================================

  /// Get the recommended endpoint based on available data
  static String getRecommendedReportEndpoint(int patientId, int sessionId, {
    bool hasFerData = false,
    bool hasSpeechData = false,
    bool hasDoctorNotes = false,
  }) {
    if (hasDoctorNotes) {
      return generateReportWithDoctorNotes(patientId, sessionId);
    } else if (hasFerData && hasSpeechData) {
      return generateComprehensiveReport(patientId, sessionId);
    } else if (hasSpeechData) {
      return generateTovOnlyReport(patientId, sessionId);
    } else {
      return generateAnalysisReport(patientId, sessionId); // Auto-detect
    }
  }

  /// Get analysis type description
  static String getAnalysisTypeDescription(String analysisType) {
    switch (analysisType) {
      case 'tov_only':
        return 'Text tone analysis with DSM-5/ICD-11 diagnostic insights';
      case 'comprehensive':
        return 'Combined facial expression and text tone analysis with mismatch detection';
      case 'enhanced_with_notes':
        return 'Enhanced analysis including doctor notes integration';
      default:
        return 'Automatic analysis based on available data';
    }
  }

  /// Check if endpoint is deprecated
  static bool isDeprecatedEndpoint(String endpoint) {
    return endpoint.contains('/report/generate/') || 
           endpoint.contains('/report/metadata/');
  }

  /// Get the new endpoint for a deprecated one
  static String getMigratedEndpoint(String deprecatedEndpoint) {
    if (deprecatedEndpoint.contains('/report/generate/')) {
      return deprecatedEndpoint.replaceAll('/report/generate/', '/reports/generate/');
    } else if (deprecatedEndpoint.contains('/report/metadata/')) {
      return deprecatedEndpoint.replaceAll('/report/metadata/', '/reports/metadata/');
    }
    return deprecatedEndpoint;
  }
}