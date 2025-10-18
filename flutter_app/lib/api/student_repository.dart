import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../utils/config.dart';
import '../models/schedule_item.dart';

class StudentRepository {
  final Dio _dio = ApiClient().dio;

  /// Lịch học theo ngày (YYYY-MM-DD)
  Future<List<ScheduleItem>> fetchByDate(String yyyymmdd, {int? studentUserId}) async {
    final q = <String, dynamic>{'date': yyyymmdd};
    if (studentUserId != null) q['student_user_id'] = studentUserId; // DEV ONLY

    final r = await _dio.get(AppConfig.studentSchedulePath, queryParameters: q);
    final list = (r.data as List).cast<Map>();
    return list.map((e) => ScheduleItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Điểm danh (multipart)
  Future<void> checkIn(FormData form) async {
    await _dio.post(
      AppConfig.studentCheckinPath,
      data: form,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }
}
