import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQrPage extends StatelessWidget {
  final Map<String, dynamic> session;

  const ShowQrPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // Link để sinh viên quét (hoặc bạn có thể chỉ cần session ID)
    final qrData = "https://yourserver.com/attendance/session/${session['id']}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Mã QR - ${session['course']}"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                "Phiên điểm danh: ${session['course']}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Giảng viên: ${session['teacher']}"),
              const SizedBox(height: 8),
              Text("ID phiên: ${session['id']}"),
            ],
          ),
        ),
      ),
    );
  }
}
