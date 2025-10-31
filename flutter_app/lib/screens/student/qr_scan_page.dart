import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  final bool returnData;

  const QrScanPage({super.key, this.returnData = false});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _handled = false;
  final _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return; // tránh đọc nhiều lần

    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return; // Không có dữ liệu

    _handled = true;

    try {
      final String token = barcode;

      if (widget.returnData) {
        // Chỉ trả về token cho trang Loading xử lý
        Navigator.pop(context, token);
      } else {
        Navigator.pop(context, null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi quét QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎨 CẬP NHẬT: Đã bỏ comment và thêm style
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        backgroundColor: Colors.deepPurpleAccent, // Màu tím
        foregroundColor: Colors.white,           // Chữ và icon màu trắng
        elevation: 1,
      ),
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