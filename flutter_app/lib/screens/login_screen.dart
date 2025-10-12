import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/auth_repository.dart';
import '../widgets/primary_button.dart';
import 'teacher/home_screen.dart' as tea;
import 'student/home_screen.dart' as stu;
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthRepository();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.login(_email.text.trim(), _password.text);
      final p = await SharedPreferences.getInstance();
      final role = p.getString('role');
      if (!mounted) return;
      if (role == 'teacher') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const tea.TeacherHomeScreen()));
      } else if (role == 'student') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const stu.StudentHomeScreen()));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Role không hợp lệ')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login fail: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    //uncheck role
    // try {
    //   await _auth.login(_email.text.trim(), _password.text);
    //
    //   if (!mounted) return;
    //   // 👉 Bỏ kiểm tra role, vào thẳng TeacherHomeScreen
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (_) => const tea.TeacherHomeScreen()),
    //   );
    // } catch (e) {
    //   if (mounted)
    //     ScaffoldMessenger.of(context)
    //         .showSnackBar(SnackBar(content: Text('Login fail: $e')));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Đăng nhập',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _password,
                        decoration:
                            const InputDecoration(labelText: 'Mật khẩu'),
                        obscureText: true),
                    const SizedBox(height: 16),
                    PrimaryButton(
                        text: 'Vào', onPressed: _login, loading: _loading)
                  ]))),
    ));
  }
}
