import 'package:dio/dio.dart';
import '../api/api_client.dart';

class StatsRepository {
  final Dio _dio = ApiClient().dio;

  /// Tổng quan của sinh viên
  Future<Map<String, dynamic>> studentOverview() async {
    final res = await _dio.get(
      '/api/stats/student',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Thống kê lớp (giảng viên)
  Future<Map<String, dynamic>> classStats(int classId) async {
    final res = await _dio.get(
      '/api/stats/class/$classId',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Thống kê theo phiên
  Future<Map<String, dynamic>> sessionStats(int sessionId) async {
    final res = await _dio.get(
      '/api/stats/session/$sessionId',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
