import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/attendance_service.dart';

class QrScanPage extends StatefulWidget {
  final bool returnData; // cho phép dùng trong nhiều ngữ cảnh

  const QrScanPage({super.key, this.returnData = false});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _handled = false;
  final _controller = MobileScannerController();
  final _attendanceService = AttendanceService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return; // tránh đọc nhiều lần
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    _handled = true;

    try {
      final uri = Uri.tryParse(barcode);
      final token = uri?.queryParameters['token'] ?? barcode;

      if (widget.returnData) {
        // Dành cho trường hợp dùng trong trang khác (trả token)
        Navigator.pop(context, token);
        return;
      }

      // 1️⃣ Gọi API resolveQr
      final resolved = await _attendanceService.resolveQr(token);
      final sessionId = resolved['session_id'];
      if (sessionId == null) {
        throw Exception('Không tìm thấy mã phiên điểm danh');
      }

      // 2️⃣ Gọi API checkIn
      await _attendanceService.checkIn(
        sessionId: sessionId,
        status: 'present',
      );

      if (!mounted) return;

      // 3️⃣ Thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điểm danh thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // quay lại sau khi điểm danh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Điểm danh thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _handled = false; // cho phép quét lại
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Hướng camera vào mã QR để điểm danh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
