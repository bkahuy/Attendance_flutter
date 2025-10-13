import 'dart:io';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../utils/config.dart';

class AttendanceService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> resolveQr(String token) async {
    final res = await _dio.get(
      AppConfig.studentResolveQrPath,
      queryParameters: {'token': token},
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> checkIn({
    required int sessionId,
    required String status,
    String? password,
    double? lat,
    double? lng,
    File? photoFile,
  }) async {
    final form = FormData.fromMap({
      'session_id': sessionId,
      'status': status,
      if (password != null && password.isNotEmpty) 'password': password,
      if (lat != null) 'gps_lat': lat,
      if (lng != null) 'gps_lng': lng,
      if (photoFile != null)
        'photo': await MultipartFile.fromFile(photoFile.path, filename: 'checkin.jpg'),
    });

    await _dio.post(
      AppConfig.studentCheckinPath,
      data: form,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  Future<Map<String, dynamic>> createSession({
    required int classSectionId,
    required DateTime startAt,
    required DateTime endAt,
    bool camera = true,
    bool gps = false,
    String? password,
  }) async {
    final mode = {
      if (camera) 'camera': true,
      if (gps) 'gps': true,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final res = await _dio.post(
      AppConfig.teacherCreateSessionPath,
      data: {
        'class_section_id': classSectionId,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'mode_flags': mode,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return Map<String, dynamic>.from(res.data);
  }
}
