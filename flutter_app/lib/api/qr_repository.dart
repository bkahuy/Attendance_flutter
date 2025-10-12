import 'package:dio/dio.dart';
import 'api_client.dart';

class QrRepository {
  final _dio = Api.I.dio;
  Future<Map<String, dynamic>> resolve(String token) async {
    final r = await _dio
        .get('/attendance/resolve-qr', queryParameters: {'token': token});
    return Map<String, dynamic>.from(r.data as Map);
  }
}
