import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class ApiClient {
  // Singleton pattern — chỉ tạo 1 instance duy nhất
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio dio;

  /// Khởi tạo Dio và interceptor
  Future<void> init() async {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.BASE_URL,
      connectTimeout: const Duration(seconds: 1000),
      receiveTimeout: const Duration(seconds: 1000),
      headers: {'Accept': 'application/json'},
    ));

    // Thêm interceptor để tự động thêm token vào request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Nếu token hết hạn => xóa thông tin đăng nhập
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            await prefs.remove('user_role');
            await prefs.remove('user_name');
          }
          handler.next(e);
        },
      ),
    );
  }

    Future get(String s) async {}


}
