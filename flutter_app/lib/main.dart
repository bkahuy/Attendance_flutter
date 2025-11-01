import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'services/auth_service.dart';
import 'screens/login_page.dart';

import 'face_recog/enroll_screen.dart';
import 'face_recog/recognize_screen.dart';
import 'face_recog/test_gallery.dart';        // <-- THÊM IMPORT NÀY

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    developer.log('App start');
    // chỉ tắt spam log khi DEBUG
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  await initializeDateFormatting('vi_VN', null);
  await ApiClient().init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Attendance',
        locale: const Locale('vi', 'VN'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF111827)),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,

        // Màn hình mặc định
        home: const LoginPage(),

        // Route KHÔNG tham số
        routes: {
          '/login': (_) => const LoginPage(),
        },

        // Route CÓ tham số
        onGenerateRoute: (settings) {
          if (settings.name == '/face/enroll') {
            final int studentId = settings.arguments as int;
            return MaterialPageRoute(builder: (_) => EnrollScreen(studentId: studentId));
          }
          if (settings.name == '/face/recognize') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RecognizeScreen(
                studentId: args['studentId'] as int,
                sessionId: args['sessionId'] as int,
              ),
            );
          }
          if (settings.name == '/face/recognize') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => RecognizeScreen(
                studentId: args['studentId'] as int,
                sessionId: args['sessionId'] as int,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
