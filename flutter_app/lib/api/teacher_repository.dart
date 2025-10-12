import 'package:dio/dio.dart';
import 'api_client.dart';

class TeacherRepository {
  final _dio = Api.I.dio;
  Future<List<dynamic>> schedule(String date) async {
    final r =
        await _dio.get('/teacher/schedule', queryParameters: {'date': date});
    return (r.data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> createSession(
      {required int classSectionId,
      required String startAt,
      required String endAt,
      bool qr = true,
      bool camera = true,
      String? password,
      int? scheduleId}) async {
    final mode = {
      'camera': camera,
      'qr': qr,
      if (password != null && password.isNotEmpty) 'password': true
    };
    final body = {
      'class_section_id': classSectionId,
      'start_at': startAt,
      'end_at': endAt,
      'mode_flags': mode,
      if (password != null && password.isNotEmpty) 'password': password,
      if (scheduleId != null) 'schedule_id': scheduleId
    };
    final r = await _dio.post('/attendance/session', data: body);
    return Map<String, dynamic>.from(r.data as Map);
  }
}
