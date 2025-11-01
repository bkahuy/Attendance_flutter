// lib/face_recog/enroll_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_service.dart';
import 'face_service_singleton.dart';
import 'storage.dart';

class EnrollScreen extends StatefulWidget {
  final int studentId;
  const EnrollScreen({super.key, required this.studentId});

  @override
  State<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends State<EnrollScreen> {
  CameraController? _cam;
  late FaceService _svc;
  final _store = EmbeddingStorage();
  bool _busy = true;
  String? _msg;

  @override
  void initState() {
    super.initState();
    // Đợi khung hình đầu tiên rồi mới init cho mượt
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      setState(() => _busy = true);

      // 1) Load model trước (singleton, dùng chung toàn app)
      _svc = await FaceServiceHolder.I.get();

      // 2) Init camera sau
      final cams = await availableCameras();
      final cam = cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      _cam = CameraController(
        cam,
        ResolutionPreset.low,          // đủ dùng, đỡ lag emulator
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cam!.initialize().timeout(const Duration(seconds: 4));

      if (!mounted) return;
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _msg = 'Lỗi khởi tạo: $e'; _busy = false; });
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    // Không dispose _svc (singleton)
    super.dispose();
  }

  // ==== Core: xử lý 1 file ảnh -> detect face -> embedding -> save ====
  Future<void> _processFile(String path) async {
    try {
      // Detect
      List<Face> faces;
      try {
        faces = await _svc.detectFacesFromImageFile(path);
      } catch (e) {
        setState(() { _msg = 'Detect face lỗi: $e'; _busy = false; });
        return;
      }
      if (faces.isEmpty) {
        setState(() { _msg = 'Không thấy khuôn mặt. Hãy chọn/chụp ảnh rõ mặt.'; _busy = false; });
        return;
      }

      // Lấy mặt lớn nhất
      faces.sort((a, b) => b.boundingBox.width.compareTo(a.boundingBox.width));

      // Embedding
      List<double>? emb;
      try {
        emb = await _svc.embeddingFromFile(path, faces.first);
      } catch (e) {
        setState(() { _msg = 'Embedding lỗi (run): $e'; _busy = false; });
        return;
      }
      if (emb == null) {
        setState(() { _msg = 'Không tạo được embedding'; _busy = false; });
        return;
      }

      // Lưu vào storage local theo studentId
      await _store.saveOne(widget.studentId, emb);

      setState(() {
        _msg = '✅ Đăng ký thành công cho ID ${widget.studentId}';
        _busy = false;
      });
    } catch (e) {
      setState(() { _msg = 'Lỗi: $e'; _busy = false; });
    }
  }

  // ==== Nút: chụp từ camera ====
  Future<void> _captureAndEnroll() async {
    if (_cam == null || !_cam!.value.isInitialized) {
      setState(() => _msg = 'Camera chưa sẵn sàng');
      return;
    }
    if (_cam!.value.isTakingPicture) return;

    setState(() { _msg = null; _busy = true; });

    try {
      // đảm bảo preview đang chạy
      try { await _cam!.setFlashMode(FlashMode.off); } catch (_) {}
      if (_cam!.value.isPreviewPaused) {
        try { await _cam!.resumePreview(); } catch (_) {}
      }

      final XFile shot = await _cam!.takePicture();
      await _processFile(shot.path);
    } catch (e) {
      setState(() { _msg = 'Chụp ảnh lỗi: $e'; _busy = false; });
    }
  }

  // ==== Nút: chọn ảnh từ thư viện ====
  Future<void> _pickAndEnroll() async {
    setState(() { _msg = null; _busy = true; });
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) {
        setState(() { _busy = false; _msg = 'Đã huỷ chọn ảnh'; });
        return;
      }
      await _processFile(picked.path);
    } catch (e) {
      setState(() { _msg = 'Chọn ảnh lỗi: $e'; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy && (_cam == null || !_cam!.value.isInitialized)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký khuôn mặt')),
      body: Column(
        children: [
          if (_cam != null && _cam!.value.isInitialized)
            AspectRatio(
              aspectRatio: _cam!.value.aspectRatio,
              child: CameraPreview(_cam!),
            ),
          const SizedBox(height: 12),

          // Hai nút: chụp & chọn ảnh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _captureAndEnroll,
                    child: const Text('Chụp & Lưu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _pickAndEnroll,
                    child: const Text('Chọn ảnh & Lưu'),
                  ),
                ),
              ],
            ),
          ),

          if (_busy) const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),

          if (_msg != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _msg!,
                style: TextStyle(
                  color: _msg!.startsWith('✅') ? Colors.green : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
