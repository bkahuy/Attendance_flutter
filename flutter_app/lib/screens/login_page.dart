import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  String? err;

  Future<void> _submit() async {
    setState(() { loading = true; err = null; });
    try {
      final (user, _) = await AuthService().login(email: email.text.trim(), password: pass.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage(user: user)));
    } on DioException catch (e) {
      setState(() {
        err = e.response?.data is Map && (e.response?.data['error'] != null)
          ? e.response?.data['error'].toString()
          : 'Lỗi đăng nhập (${e.response?.statusCode ?? ''})';
      });
    } catch (e) {
      setState(() { err = 'Có lỗi xảy ra: $e'; });
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Đăng nhập', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : _submit,
                    child: loading ? const CircularProgressIndicator() : const Text('Đăng nhập'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
