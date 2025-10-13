import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../utils/config.dart';

class QrRepository {
  final Dio _dio = ApiClient().dio;

  /// Nhận chuỗi quét (raw hoặc URL có ?token=...), trả session info (Map)
  Future<Map<String, dynamic>> resolve(String rawToken) async {
    String token = rawToken;
    final uri = Uri.tryParse(rawToken);
    if (uri != null && uri.hasQuery && uri.queryParameters['token'] != null) {
      token = uri.queryParameters['token']!;
    }

    final res = await _dio.get(
      AppConfig.studentResolveQrPath, // '/api/attendance/resolve-qr'
      queryParameters: {'token': token},
      options: Options(headers: {'Accept': 'application/json'}),
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw StateError('Phản hồi không hợp lệ: ${data.runtimeType}');
  }
}
