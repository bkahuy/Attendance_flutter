import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'screens/login_page.dart';
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
    return MaterialApp(
      title: 'Attendance',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)), useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {
        '/login': (_) => const LoginPage(),
      },
    );
  }
}
