class ApiConstants {
  static const baseUrl = 'http://127.0.0.1:5001';
  static const createDoctor = '$baseUrl/create-doctor';
  static const loginDoctor = '$baseUrl/login-doctor';
  static String uploadAudio(int patientId, int sessionId) =>
      '$baseUrl/upload-audio/$patientId/$sessionId';

  static String uploadVideo(int patientId, int sessionId) =>
      '$baseUrl/upload-video/$patientId/$sessionId';

  static String doctorPatients(String doctorID) =>
      '$baseUrl/$doctorID/patients';
}
