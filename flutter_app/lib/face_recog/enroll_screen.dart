import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'face_service.dart';
import 'storage.dart';

class EnrollScreen extends StatefulWidget {
  final int studentId; // truyền vào từ màn trước
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
    _init();
  }

  Future<void> _init() async {
    final cams = await availableCameras();
    _cam = CameraController(cams.first, ResolutionPreset.medium, enableAudio: false);
    await _cam!.initialize();
    _svc = FaceService();
    await _svc.load();
    setState(() => _busy = false);
  }

  @override
  void dispose() {
    _cam?.dispose();
    _svc.dispose();
    super.dispose();
  }

  Future<void> _captureAndEnroll() async {
    try {
      setState(() { _msg = null; _busy = true; });
      final XFile shot = await _cam!.takePicture();
      final faces = await _svc.detectFacesFromImageFile(shot.path);
      if (faces.isEmpty) {
        setState(() { _msg = 'Không thấy khuôn mặt. Chụp lại gần/đủ sáng.'; _busy = false; });
        return;
      }
      // lấy khuôn mặt lớn nhất
      faces.sort((a,b)=> b.boundingBox.width.compareTo(a.boundingBox.width));
      final emb = await _svc.embeddingFromFile(shot.path, faces.first);
      if (emb == null) {
        setState(() { _msg = 'Lỗi xử lý ảnh.'; _busy = false; });
        return;
      }
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
          AspectRatio(
            aspectRatio: _cam!.value.aspectRatio,
            child: CameraPreview(_cam!),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _captureAndEnroll,
            child: const Text('Chụp & Lưu Embedding'),
          ),
          if (_msg != null) Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_msg!, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
