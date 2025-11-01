import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'; // <-- cho Face
import 'face_service.dart';
import 'storage.dart';
import '../services/face_api_service.dart';
import 'face_service_singleton.dart';

class RecognizeScreen extends StatefulWidget {
  final int studentId;
  final int sessionId;
  const RecognizeScreen({super.key, required this.studentId, required this.sessionId});

  @override
  State<RecognizeScreen> createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends State<RecognizeScreen> {
  CameraController? _cam;
  late FaceService _svc;
  final _api = FaceApiService();
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

      _svc = await FaceServiceHolder.I.get();

      final cams = await availableCameras();
      final cam = cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _cam = CameraController(
        cam,
        ResolutionPreset.low,
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
    super.dispose(); // không dispose _svc (singleton)
  }

  Future<void> _verifyFace() async {
    if (_cam == null || !_cam!.value.isInitialized) {
      setState(() => _msg = 'Camera chưa sẵn sàng');
      return;
    }
    if (_cam!.value.isTakingPicture) return;

    try {
      setState(() { _busy = true; _msg = null; });

      try { await _cam!.setFlashMode(FlashMode.off); } catch (_) {}
      if (_cam!.value.isPreviewPaused) {
        try { await _cam!.resumePreview(); } catch (_) {}
      }

      final shot = await _cam!.takePicture();

      List<Face> faces;
      try {
        faces = await _svc.detectFacesFromImageFile(shot.path);
      } catch (e) {
        setState(() { _msg = 'Detect face lỗi: $e'; _busy = false; });
        return;
      }
      if (faces.isEmpty) {
        setState(() { _msg = 'Không phát hiện khuôn mặt'; _busy = false; });
        return;
      }

      List<double>? emb;
      try {
        emb = await _svc.embeddingFromFile(shot.path, faces.first);
      } catch (e) {
        setState(() { _msg = 'Embedding lỗi: $e'; _busy = false; });
        return;
      }
      if (emb == null) {
        setState(() { _msg = 'Không lấy được đặc trưng khuôn mặt'; _busy = false; });
        return;
      }

      final ok = await _api.verifyFace(widget.studentId, emb);
      if (!mounted) return;

      if (ok) {
        setState(() { _msg = '✅ Xác thực thành công!'; _busy = false; });
        Navigator.pushNamed(
          context,
          '/attendance/manual',
          arguments: {'sessionId': widget.sessionId},
        );
      } else {
        setState(() { _msg = '❌ Khuôn mặt không khớp, thử lại'; _busy = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _msg = 'Lỗi: $e'; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực khuôn mặt')),
      body: Column(
        children: [
          if (_cam != null && _cam!.value.isInitialized)
            AspectRatio(
              aspectRatio: _cam!.value.aspectRatio,
              child: CameraPreview(_cam!),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _verifyFace,
            child: const Text('Chụp & Xác thực'),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_msg!, style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
