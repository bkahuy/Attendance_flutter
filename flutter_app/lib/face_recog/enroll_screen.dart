import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'; // <-- cần cho Face
import 'face_service.dart';
import 'storage.dart';
import 'face_service_singleton.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      setState(() => _busy = true);

      // 1) Load model trước (singleton)
      _svc = await FaceServiceHolder.I.get();

      // 2) Init camera sau
      final cams = await availableCameras();
      final cam = cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _cam = CameraController(
        cam,
        ResolutionPreset.low,          // nếu mượt rồi có thể nâng lên medium
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
    // không dispose _svc vì dùng singleton
    super.dispose();
  }

  Future<void> _captureAndEnroll() async {
    if (_cam == null || !_cam!.value.isInitialized) {
      setState(() => _msg = 'Camera chưa sẵn sàng');
      return;
    }
    if (_cam!.value.isTakingPicture) return;

    try {
      setState(() { _msg = null; _busy = true; });

      try { await _cam!.setFlashMode(FlashMode.off); } catch (_) {}

      // ✅ plugin có resumePreview(), KHÔNG có startPreview()
      if (_cam!.value.isPreviewPaused) {
        try { await _cam!.resumePreview(); } catch (_) {}
      }

      // 1) Chụp
      final XFile shot = await _cam!.takePicture();

      // 2) Detect face
      List<Face> faces;
      try {
        faces = await _svc.detectFacesFromImageFile(shot.path);
      } catch (e) {
        setState(() { _msg = 'Detect face lỗi: $e'; _busy = false; });
        return;
      }
      if (faces.isEmpty) {
        setState(() { _msg = 'Không thấy khuôn mặt. Chụp gần/đủ sáng.'; _busy = false; });
        return;
      }

      // 3) Embedding
      faces.sort((a, b) => b.boundingBox.width.compareTo(a.boundingBox.width));
      List<double>? emb;
      try {
        emb = await _svc.embeddingFromFile(shot.path, faces.first);
      } catch (e) {
        setState(() { _msg = 'Embedding lỗi: $e'; _busy = false; });
        return;
      }
      if (emb == null) {
        setState(() { _msg = 'Không tạo được embedding'; _busy = false; });
        return;
      }

      // 4) Lưu
      await _store.saveOne(widget.studentId, emb);
      setState(() { _msg = 'Đăng ký thành công cho ID ${widget.studentId}'; _busy = false; });
    } catch (e) {
      setState(() { _msg = 'Lỗi: $e'; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
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
          ElevatedButton(
            onPressed: _captureAndEnroll,
            child: const Text('Chụp & Lưu Khuôn Mặt'),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_msg!, style: const TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }
}
