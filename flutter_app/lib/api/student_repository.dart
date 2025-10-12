import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class StudentRepository {
  final _dio = Api.I.dio;
  Future<List<dynamic>> schedule(String date) async {
    final r =
        await _dio.get('/student/schedule', queryParameters: {'date': date});
    return (r.data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> checkIn(
      {required int sessionId,
      required String status,
      File? photoFile,
      double? lat,
      double? lng,
      String? password}) async {
    final form = FormData.fromMap({
      'attendance_session_id': sessionId,
      'status': status,
      if (password != null) 'password': password,
      if (lat != null) 'gps_lat': lat,
      if (lng != null) 'gps_lng': lng,
      if (photoFile != null)
        'photo': await MultipartFile.fromFile(photoFile.path,
            filename: photoFile.uri.pathSegments.last)
    });
    final r = await _dio.post('/attendance/checkin', data: form);
    return Map<String, dynamic>.from(r.data as Map);
  }
}
