import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'api/api_client.dart';
import 'services/auth_service.dart';
import 'screens/login_page.dart';

import 'package:flutter_face_api/face_api.dart' as regula;

Future<void> initRegula() async {
  try {
    // Nếu bạn dùng file license:
    // final licenseText = (await rootBundle.loadString('assets/licenses/regula.license')).trim();
    // await regula.FaceSDK.setLicense(licenseText);

    // Một số version chỉ cần initialize(); nếu setLicense không có thì bỏ qua
    try { await regula.FaceSDK.initialize(); } catch (_) {}

    final version = await regula.FaceSDK.version();
    debugPrint('Regula FaceSDK OK: $version');
  } catch (e) {
    debugPrint('Regula init error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await ApiClient().init();
  await initRegula();     // init Regula trước khi vào app
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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)),
          useMaterial3: true,
        ),
        home: const LoginPage(),
        routes: {
          '/login': (_) => const LoginPage(),
        },
      ),
    );
  }
}
