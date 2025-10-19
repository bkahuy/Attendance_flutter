import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class FaceApi {
  final _dio = ApiClient().dio;

  Future<int> enroll({
    required List<int> templateBytes,
    String provider = 'regula',
    String version = 'regula-2025.10',
    double? quality,
    bool isPrimary = true,
  }) async {
    final b64 = base64Encode(templateBytes);
    final res = await _dio.post('/api/face/enroll', data: {
      'template_base64': b64,
      'provider': provider,
      'version': version,
      'quality_score': quality,
      'is_primary': isPrimary,
    });
    return (res.data['face_template_id'] as num).toInt();
  }

  Future<int> logMatch({
    required int attendanceSessionId,
    required int studentId,
    required double similarity,
    required double threshold,
    String decision = 'accept', // or 'reject'
    String method = '1:1',
    String livenessType = 'passive',
    double? livenessScore,
    String? modelVersion = 'regula-2025.10',
    Map<String, dynamic>? spoofFlags,
    String? imagePath,
  }) async {
    final res = await _dio.post('/api/face/match', data: {
      'attendance_session_id': attendanceSessionId,
      'student_id': studentId,
      'method': method,
      'similarity': similarity,
      'threshold': threshold,
      'decision': decision,
      'liveness_type': livenessType,
      'liveness_score': livenessScore,
      'model_version': modelVersion,
      'spoof_flags': spoofFlags == null ? null : jsonEncode(spoofFlags),
      'image_path': imagePath,
    });
    return (res.data['face_match_id'] as num).toInt();
  }
}
