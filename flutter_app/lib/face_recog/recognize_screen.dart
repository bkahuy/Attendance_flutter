import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'face_service.dart';
import 'storage.dart';

class RecognizeScreen extends StatefulWidget {
  const RecognizeScreen({super.key});
  @override
  State<RecognizeScreen> createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends State<RecognizeScreen> {
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

  Future<void> _captureAndMatch() async {
    setState(() { _msg = null; _busy = true; });
    try {
      final shot = await _cam!.takePicture();
      final faces = await _svc.detectFacesFromImageFile(shot.path);
      if (faces.isEmpty) {
        setState(() { _msg = 'Không thấy khuôn mặt.'; _busy = false; });
        return;
      }
      faces.sort((a,b)=> b.boundingBox.width.compareTo(a.boundingBox.width));
      final emb = await _svc.embeddingFromFile(shot.path, faces.first);
      if (emb == null) {
        setState(() { _msg = 'Lỗi xử lý ảnh.'; _busy = false; });
        return;
      }

      final db = await _store.loadAll(); // Map<int, List<double>>
      final res = _svc.match(emb, db, threshold: 0.6); // tune 0.5–0.7
      if (res == null) {
        setState(() { _msg = 'Không khớp ai trong DB (threshold quá cao?).'; _busy = false; });
      } else {
        setState(() { _msg = 'Match: studentId=${res.key}, score=${res.value.toStringAsFixed(3)}'; _busy = false; });
        // TODO: gọi API điểm danh ở đây (gửi studentId, classId, score,...)
      }
    } catch (e) {
      setState(() { _msg = 'Lỗi: $e'; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm danh bằng mặt')),
      body: Column(
        children: [
          AspectRatio(aspectRatio: _cam!.value.aspectRatio, child: CameraPreview(_cam!)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _captureAndMatch, child: const Text('Chụp & Nhận diện')),
          if (_msg != null) Padding(padding: const EdgeInsets.all(12), child: Text(_msg!)),
        ],
      ),
    );
  }
}
