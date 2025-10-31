// 📝 TẠO FILE MỚI NÀY: lib/pages/student/student_checkin_loading_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/attendance_service.dart'; // Import service
import 'student_checkin_page.dart'; // Import trang check-in CỦA BẠN

class StudentCheckinLoadingPage extends StatefulWidget {
  final String qrToken;
  final File facePhoto;

  const StudentCheckinLoadingPage({
    super.key,
    required this.qrToken,
    required this.facePhoto,
  });

  @override
  State<StudentCheckinLoadingPage> createState() =>
      _StudentCheckinLoadingPageState();
}

class _StudentCheckinLoadingPageState extends State<StudentCheckinLoadingPage> {
  @override
  void initState() {
    super.initState();
    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    try {
      print("[DEBUG] Đang gửi token này lên server: ${widget.qrToken}");
      // 1. Gọi API resolveQr (giống trong QrScanPage của bạn)
      final sessionData =
      await AttendanceService().resolveQr(widget.qrToken);

      if (!mounted) return;

      // 2. Chuyển tiếp sang StudentCheckinPage (file CỦA BẠN)
      //    và gửi kèm session + ảnh đã chụp
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentCheckinPage(
            session: sessionData,
            photo: widget.facePhoto, // ‼️ Truyền ảnh vào đây
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Nếu lỗi (QR hết hạn, v.v.), hiển thị lỗi và quay về
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi giải mã QR: $e")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Đang lấy thông tin buổi học...",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}