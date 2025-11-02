import 'dart:io';
import 'dart:convert'; // 🎨 1. Thêm import để dùng Base64
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'student_home.dart';
// (Bạn có thể xóa 2 dòng import "provider" và "auth_service" thừa)

class FaceRegistrationPage extends StatefulWidget {
  final AppUser user;
  const FaceRegistrationPage({super.key, required this.user});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  final ImagePicker _picker = ImagePicker();

  // 🎨 2. Thay đổi State
  File? _previewPhoto; // Dùng để hiển thị ảnh vừa chụp
  String? _templateBase64; // Dùng để gửi lên server
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePictureAndCreateTemplate();
    });
  }

  // 🎨 3. Sửa lại hàm này
  Future<void> _takePictureAndCreateTemplate() async {
    try {
      final XFile? img = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (img != null) {
        // ‼️ TODO: TẠM THỜI (DÙNG CHO TEST)
        // Chúng ta đang gửi Base64 của ảnh thô.
        // BẠN NÊN thay thế logic này bằng SDK (như Regula)
        // để tạo "template" AI thực sự.
        final bytes = await File(img.path).readAsBytes();
        final String base64String = base64Encode(bytes);

        setState(() {
          _previewPhoto = File(img.path); // Lưu ảnh để xem
          _templateBase64 = base64String; // Lưu template để gửi
        });
      } else {
        if (mounted) Navigator.pop(context); // Quay lại Login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi camera: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  // 🎨 4. Sửa lại hàm này
  Future<void> _registerFace() async {
    if (_templateBase64 == null) return; // Kiểm tra template

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // 1. GỌI API ĐĂNG KÝ
      // (AuthService giờ sẽ gửi JSON chứa 'template_base64')
      await authService.registerFace(_templateBase64!);

      if (!mounted) return;

      // 2. NẾU THÀNH CÔNG: Đi đến StudentHome
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký khuôn mặt thành công!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentHome(user: widget.user),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi đăng ký: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký khuôn mặt"),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 5. Sửa lại Build (hiển thị _previewPhoto)
              if (_previewPhoto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_previewPhoto!, // 👈 Hiển thị ảnh xem trước
                      height: 300, width: 300, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text("Đang chờ ảnh...")),
                ),
              const SizedBox(height: 32),
              const Text(
                "Vui lòng chụp ảnh chân dung rõ nét để đăng ký.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nút chụp lại
                    ElevatedButton.icon(
                      onPressed: _takePictureAndCreateTemplate,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text("Chụp lại"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    // Nút xác nhận
                    ElevatedButton.icon(
                      onPressed: _templateBase64 == null ? null : _registerFace,
                      icon: const Icon(Icons.check),
                      label: const Text("Xác nhận"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}