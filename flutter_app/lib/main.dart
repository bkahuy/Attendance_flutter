import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'screens/login_page.dart';
import 'services/auth_service.dart';

import 'face_recog/enroll_screen.dart';
import 'face_recog/recognize_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const LoginPage(),
        routes: {
          '/login': (_) => const LoginPage(),
          // ↓↓↓ thêm 2 route mới ↓↓↓
          '/face/recognize': (_) => const RecognizeScreen(),
        },
        // với enroll cần truyền studentId động, dùng onGenerateRoute
        onGenerateRoute: (settings) {
          if (settings.name == '/face/enroll') {
            final int studentId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => EnrollScreen(studentId: studentId),
            );
          }
          return null;
        },
      ),
    );
  }
}
