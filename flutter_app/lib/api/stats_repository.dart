import 'package:dio/dio.dart';
import 'api_client.dart';

class StatsRepository {
  final _dio = Api.I.dio;
  Future<Map<String, dynamic>> classStats(int id) async {
    final r = await _dio.get('/stats/class/$id');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<Map<String, dynamic>> sessionStats(int id) async {
    final r = await _dio.get('/stats/session/$id');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<List<dynamic>> studentOverview() async {
    final r = await _dio.get('/stats/student');
    return (r.data as List).cast<dynamic>();
  }
}
