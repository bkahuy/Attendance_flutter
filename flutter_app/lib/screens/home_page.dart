import 'package:flutter/material.dart';
import '../models/user.dart';
import 'teacher/teacher_home.dart';
import 'student/student_home.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  final AppUser user;
  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (user.role) {
      case 'teacher': body = TeacherHome(user: user); break;
      case 'student': body = StudentHome(user: user); break;
      default:
        body = Center(child: Text('Role không hỗ trợ: ${user.role}'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          )
        ],
      ),
      body: body,
    );
  }
}
