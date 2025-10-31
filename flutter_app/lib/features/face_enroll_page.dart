import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../api/face_api_service.dart';

class FaceEnrollPage extends StatefulWidget {
  const FaceEnrollPage({super.key});
  @override
  State<FaceEnrollPage> createState() => _FaceEnrollPageState();
}

class _FaceEnrollPageState extends State<FaceEnrollPage> {
  bool _loading = false;
  String? _result;

  Future<void> _doEnroll() async {
    setState(() { _loading = true; _result = null; });

    // TODO: TÍCH HỢP SDK REGULA Ở ĐÂY
    // Lấy templateBytes từ SDK (embedding).
    // Tạm thời dùng dummy bytes để test API:
    final template = Uint8List.fromList(List.generate(64, (i) => i));

    try {
      final id = await FaceApiService().enroll(
        templateBytes: template,
        version: 'regula-2025.10',
        quality: 0.92,
        isPrimary: true,
      );
      setState(() { _result = 'Enroll OK. face_template_id=$id'; });
    } catch (e) {
      setState(() { _result = 'Enroll lỗi: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký khuôn mặt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Nhấn nút bên dưới để quét khuôn mặt và đăng ký.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _doEnroll,
              child: _loading ? const CircularProgressIndicator() : const Text('Quét & Đăng ký'),
            ),
            const SizedBox(height: 16),
            if (_result != null) Text(_result!, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
