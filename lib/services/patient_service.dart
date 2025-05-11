// lib/services/patient_service.dart

import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';

class PatientService {
  /// Upload given bytes as an audio file.
  static Future<void> uploadAudio({
    required int patientId,
    required int sessionId,
    required Uint8List bytes,
    required String filename,
  }) =>
      _upload(
        url: ApiConstants.uploadAudio(patientId, sessionId),
        bytes: bytes,
        filename: filename,
      );

  /// Upload given bytes as a video file.
  static Future<void> uploadVideo({
    required int patientId,
    required int sessionId,
    required Uint8List bytes,
    required String filename,
  }) =>
      _upload(
        url: ApiConstants.uploadVideo(patientId, sessionId),
        bytes: bytes,
        filename: filename,
      );

  /// Internal helper: always uses bytes.
  static Future<void> _upload({
    required String url,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse(url);
    final req = http.MultipartRequest('POST', uri)
      ..files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception('Upload failed: ${resp.body}');
    }
  }
}
