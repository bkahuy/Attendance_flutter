import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/teacher/home_screen.dart' as tea;
import 'screens/student/home_screen.dart' as stu;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Attendance',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const _Gate(),
        debugShowCheckedModeBanner: false);
  }
}

class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  Future<Widget> _next() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('jwt');
    final role = p.getString('role');
    if (t != null && role != null) {
      if (role == 'teacher') return const tea.TeacherHomeScreen();
      if (role == 'student') return const stu.StudentHomeScreen();
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _next(),
        builder: (ctx, s) {
          if (!s.hasData)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          return s.data as Widget;
        });
  }
}
