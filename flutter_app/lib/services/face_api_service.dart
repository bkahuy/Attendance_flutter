import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class FaceApiService {
  final Dio _dio = ApiClient().dio;

  // Gửi template để đăng ký khuôn mặt
  Future<void> enrollFace(int studentId, List<double> embedding) async {
    final bytes = Float32List.fromList(embedding).buffer.asUint8List();
    final base64String = base64Encode(bytes);

    await _dio.post(
      '/api/face/enroll',
      data: {
        'student_id': studentId,
        'template_base64': base64String,
      },
    );
  }

  // Xác thực khuôn mặt trước khi điểm danh
  Future<bool> verifyFace(int studentId, List<double> embedding) async {
    final bytes = Float32List.fromList(embedding).buffer.asUint8List();
    final base64String = base64Encode(bytes);

    final res = await _dio.post(
      '/api/face/verify',
      data: {
        'student_id': studentId,
        'template_base64': base64String,
      },
    );
    return res.data['ok'] == true;
  }
}
