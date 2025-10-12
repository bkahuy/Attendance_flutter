import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrScreen extends StatelessWidget {
  final String qrText;
  final int sessionId;
  final String? password;
  const QrScreen(
      {super.key,
      required this.qrText,
      required this.sessionId,
      this.password});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('QR Điểm Danh')),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          QrImageView(data: qrText, version: QrVersions.auto, size: 240),
          const SizedBox(height: 16),
          Text('Session ID: $sessionId'),
          if (password != null && password!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Password: $password',
                style: const TextStyle(fontWeight: FontWeight.bold))
          ]
        ])));
  }
}
