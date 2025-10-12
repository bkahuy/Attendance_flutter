import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class Api {
  static final Api I = Api._();
  final Dio dio = Dio(BaseOptions(
      baseUrl: '$kBaseUrl/api',

      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 30),
      headers: {'Accept': 'application/json'}));
  Api._() {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
      final p = await SharedPreferences.getInstance();
      final t = p.getString('jwt');
      if (t != null && t.isNotEmpty) o.headers['Authorization'] = 'Bearer $t';
      h.next(o);
    }, onError: (e, h) async {
      if (e.response?.statusCode == 401) {
        final p = await SharedPreferences.getInstance();
        await p.remove('jwt');
        await p.remove('role');
      }
      h.next(e);
    }));
  }
}
