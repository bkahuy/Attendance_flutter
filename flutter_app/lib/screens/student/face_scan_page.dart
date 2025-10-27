// 📝 TẠO FILE MỚI NÀY: lib/pages/student/face_scan_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Tự động mở camera khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePicture();
    });
  }

  Future<void> _takePicture() async {
    try {
      final XFile? img = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (img != null) {
        // ‼️ QUAN TRỌNG: Trả File ảnh về cho StudentHome
        Navigator.pop(context, File(img.path));
      } else {
        // Nếu người dùng không chụp (bấm back), tự động đóng trang
        Navigator.pop(context, null);
      }
    } catch (e) {
      // Xử lý lỗi (ví dụ: không có quyền camera)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi camera: $e")),
      );
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác thực khuôn mặt"),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Đang mở camera trước...",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}