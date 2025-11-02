import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class FaceApiService {
  final Dio _dio = ApiClient().dio;

  Future<void> enrollFace(int studentId, List<double> embedding) async {
    final bytes = Float32List.fromList(embedding).buffer.asUint8List();
    final base64String = base64Encode(bytes);

    final response = await _dio.post(
      '/api/face/enroll',
      data: {
        'template_base64': base64String,
        'version': 'mfn-1.0',
        'is_primary': true,
        'student_id': studentId,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Enroll face failed: ${response.data}');
    }
  }

  // Ghi log nhận diện khuôn mặt
  Future<void> logMatch({
    required int studentId,
    required double similarity,
    double threshold = 0.6,
  }) async {
    await _dio.post('/api/face/match', data: {
      'student_id': studentId,
      'face_template_id': null,
      'method': '1:1',
      'similarity': similarity,
      'threshold': threshold,
      'decision': similarity >= threshold ? 'accept' : 'reject',
      'liveness_type': 'none',
      'liveness_score': null,
      'spoof_flags': null,
      'model_version': 'mfn-1.0',
      'image_path': null,
    });
  }

  // Điểm danh bằng khuôn mặt
  Future<void> checkinFace({
    required int studentId,
    required int classId,
    required double similarity,
  }) async {
    await _dio.post('/api/attendance/checkin', data: {
      'class_id': classId,
      'student_id': studentId,
      'status': 'present',
      'method': 'face',
      'score': double.parse(similarity.toStringAsFixed(3)),
    });
  }
}
