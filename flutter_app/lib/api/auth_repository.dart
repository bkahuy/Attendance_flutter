import 'package:dio/dio.dart';
import 'api_client.dart';
import '../utils/config.dart';
import '../models/user.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  // 🎨 CẬP NHẬT: Kiểu trả về (thêm 'bool')
  Future<(AppUser, String, bool)> login(String email, String password) async {
    try {
      final res = await _dio.post(
        AppConfig.loginPath,
        data: {'email': email, 'password': password},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final data = res.data as Map<String, dynamic>;
      final token = (data['access_token'] ?? data['token']) as String;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);

      // 🎨 CẬP NHẬT: Lấy cờ (flag) từ API
      // (Backend của bạn PHẢI trả về trường này)
      final bool requiresFace = data['requires_face_registration'] ?? false;

      // 🎨 CẬP NHẬT: Trả về 3 giá trị
      return (user, token, requiresFace);

    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}