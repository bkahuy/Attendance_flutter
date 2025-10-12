// lib/api/auth_repository.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';
import 'api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthRepository {
  final Dio _dio = Dio(BaseOptions(
    // baseUrl: '$kBaseUrl/api',
    validateStatus: (_) => false, // chỉ bật khi debug để đọc body
    headers: {'Accept': 'application/json'},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>> login(String email, String password) async {

    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    print('status=${res.statusCode} body=${res.data}');

    final token = res.data['token'] as String;
    final user  = Map<String, dynamic>.from(res.data['user'] as Map);

    final sp = await SharedPreferences.getInstance();
    await sp.setString('jwt', token);
    await sp.setString('role', user['role'] ?? '');
    await sp.setString('user', jsonEncode(user));

    return {'token': token, 'user': user};
  }
  /// B2: Xin Firebase custom token (đã có Bearer JWT)
  Future<String> getFirebaseCustomToken() async {
    final res = await _dio.post('/firebase/token'); // protected
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['firebase_token'] as String;
  }

  /// B3: Đăng nhập Firebase bằng custom token
  Future<UserCredential> signInFirebaseWithCustomToken(String customToken) {
    return FirebaseAuth.instance.signInWithCustomToken(customToken);
  }

  /// One-shot: chạy đủ 3 bước
  Future<void> loginAll(String email, String password) async {
    // 1) Laravel
    await login(email, password);
    // 2) Lấy custom token
    final token = await getFirebaseCustomToken();
    // 3) Sign-in Firebase
    await signInFirebaseWithCustomToken(token);
  }

  /// Logout cả Laravel lẫn Firebase
  Future<void> logoutAll() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await FirebaseAuth.instance.signOut();
    final sp = await SharedPreferences.getInstance();
    await sp.remove('jwt');
    await sp.remove('user');
    await sp.remove('role');
  }
}
