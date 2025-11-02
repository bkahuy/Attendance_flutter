import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../utils/config.dart';
import '../models/user.dart';
import 'dart:io';

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

  // 🎨 CẬP NHẬT: Kiểu trả về (thêm 'bool')
  // Mặc dù LoginPage không gọi hàm này, chúng ta vẫn cập nhật
  // để đồng bộ với AuthRepository
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
      final bool requiresFace = data['requires_face_registration'] ?? false;


      // 🎨 CẬP NHẬT: Trả về 3 giá trị
      return (user, token, requiresFace);

    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
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

  // 🎨 HÀM MỚI: Thêm hàm này để đăng ký khuôn mặt
  Future<void> registerFace(String templateBase64) async {
    try {
      // 1. 🎨 KHÔNG DÙNG FormData nữa, gửi JSON
      final data = {
        'template_base64': templateBase64,
        // (Nếu server cần các trường khác như 'version', 'quality_score'
        //  thì bạn cũng phải lấy chúng từ SDK và gửi lên đây)
      };

      // 2. Gọi API (POST)
      await ensureAuthHeader(); // Đảm bảo đã có token
      await _dio.post(
        AppConfig.faceRegistrationPath, // (api/student/register-face)
        data: data, // 👈 Gửi JSON
      );

    } on DioException catch (e) {
      // (Xử lý lỗi)
      throw Exception(e.response?.data['message'] ?? 'Lỗi không xác định');
    } catch (e) {
      throw Exception('Lỗi đăng ký khuôn mặt');
    }
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