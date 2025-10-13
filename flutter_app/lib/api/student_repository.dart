import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../utils/config.dart';

class StudentRepository {
  final Dio _dio = ApiClient().dio;

  /// Lịch học theo ngày (YYYY-MM-DD)
  Future<List<Map<String, dynamic>>> scheduleByDate(String date) async {
    final res = await _dio.get(
      AppConfig.studentSchedulePath,
      queryParameters: {'date': date},
      options: Options(headers: {'Accept': 'application/json'}),
    );
    final List list = res.data as List;
    return list.cast<Map<String, dynamic>>();
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
