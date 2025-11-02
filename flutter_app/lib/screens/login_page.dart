import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_repository.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../api/auth_repository.dart';    // repo login trả (AppUser, String token)
import 'teacher/teacher_home.dart';
import 'student/student_home.dart';
import './student/face_registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass  = TextEditingController();
  bool loading = false;
  String? err;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { loading = true; err = null; });
    try {
      // 🎨 CẬP NHẬT: Nhận 3 giá trị
      final (AppUser user, String token, bool requiresFaceRegistration) = await AuthRepository().login(
        email.text.trim(),
        pass.text,
      );

      // ✅ Lưu SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', user.role);
      await prefs.setInt('id', user.id);
      await prefs.setString('email', user.email);
      await prefs.setString('user_name', user.name);

      if (!mounted) return;

      // ✅ Điều hướng theo role
      switch (user.role) {
        case 'teacher':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => TeacherHome(user: user)),
          );
          break;

      // 🎨 CẬP NHẬT: Thêm logic điều hướng cho sinh viên
        case 'student':
          if (requiresFaceRegistration) {
            // 2a. NẾU CẦN ĐĂNG KÝ -> Đi đến trang đăng ký
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => FaceRegistrationPage(user: user)),
            );
          } else {
            // 2b. NẾU ĐÃ ĐĂNG KÝ -> Đi đến trang home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => StudentHome(user: user)),
            );
          }
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không xác định được vai trò: ${user.role}')),
          );
      }
    } on DioException catch (e) {
      setState(() {
        err = e.response?.data is Map && (e.response?.data['error'] != null)
            ? e.response?.data['error'].toString()
            : 'Lỗi đăng nhập (${e.response?.statusCode ?? e.type.name})';
      });
    } catch (e) {
      setState(() { err = 'Có lỗi xảy ra: $e'; });
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    // (Phần UI Build... không thay đổi)
    return Scaffold(
      backgroundColor: const Color(0xFF9A8CF6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo_TLU.png', width: 250),
                    const SizedBox(height: 24),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(err!, style: const TextStyle(color: Colors.red)),
                      ),
                    TextField(
                      controller: email,
                      decoration: InputDecoration(
                        hintText: 'email',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pass,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'mật khẩu',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('ĐĂNG NHẬP',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}