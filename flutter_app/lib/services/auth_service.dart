import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../utils/config.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<void> ensureAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      _dio.options.headers['Accept'] = 'application/json';
    }
  }

  Future<(AppUser, String)> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      AppConfig.loginPath,
      data: {'email': email, 'password': password},
      options: Options(headers: {'Accept': 'application/json'}),
    );

    final data = res.data as Map<String, dynamic>;
    final token = (data['access_token'] ?? data['token']) as String;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_role', user.role);
    await prefs.setString('user_name', user.name);
    if (data['user'] is Map && (data['user'] as Map).containsKey('student_id')) {
      await prefs.setInt('student_id', (data['user']['student_id'] as num).toInt());
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';
    _dio.options.headers['Accept'] = 'application/json';

    return (user, token);
  }

  Future<AppUser?> me() async {
    try {
      final res = await _dio.get(AppConfig.profilePath);
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    try { await _dio.post('/api/auth/logout'); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _dio.options.headers.remove('Authorization');
  }

  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post(
      AppConfig.changePasswordPath,
      data: {
        'email': email,
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('student_id');
  }
}
