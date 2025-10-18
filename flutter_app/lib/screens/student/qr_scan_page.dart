// qr_scan_page.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/attendance_service.dart';
import 'student_checkin_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool handled = false;
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (handled) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    handled = true;
    try {
      final uri = Uri.tryParse(barcode);
      String? token = uri?.queryParameters['token'] ?? barcode;

      final data = await AttendanceService().resolveQr(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentCheckinPage(session: data),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR không hợp lệ: $e')),
      );
      handled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR')),
      body: MobileScanner(
        controller: controller,
        onDetect: _onDetect,
      ),
    );
  }
}
