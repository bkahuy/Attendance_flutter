import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class ApiClient {
  static final ApiClient _i = ApiClient._internal();
  factory ApiClient() => _i;
  ApiClient._internal();

  late final Dio dio;

  Future<void> init() async {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.BASE_URL,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('user_role');
          await prefs.remove('user_name');
        }
        handler.next(e);
      },
    ));
  }

  Future get(String s) async {}
  
}
