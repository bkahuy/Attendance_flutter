import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_service_singleton.dart';
import 'face_service.dart';
import 'dart:developer' as log;

class TestGalleryScreen extends StatefulWidget {
  const TestGalleryScreen({super.key});

  @override
  State<TestGalleryScreen> createState() => _TestGalleryScreenState();
}

class _TestGalleryScreenState extends State<TestGalleryScreen> {
  late FaceService _svc;
  String _status = 'Chưa chạy';
  XFile? _picked;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _status = 'Đang load model...');
    _svc = await FaceServiceHolder.I.get();
    setState(() => _status = 'Sẵn sàng');
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() { _picked = x; _status = 'Đã chọn: ${x.path}'; });
  }

  Future<void> _run() async {
    if (_picked == null) { setState(() => _status = 'Hãy chọn ảnh trước'); return; }
    setState(() => _status = 'Đang detect...');
    try {
      final faces = await _svc.detectFacesFromImageFile(_picked!.path);
      if (faces.isEmpty) { setState(() => _status = '❌ Không thấy mặt'); return; }

      final emb = await _svc.embeddingFromFile(_picked!.path, faces.first);
      if (emb == null) { setState(() => _status = '❌ Không tạo được embedding'); return; }

      setState(() => _status = '✅ OK. Embedding length = ${emb.length}');
      log.log('EMB preview: ${emb.take(8).toList()} ...');
    } catch (e, s) {
      setState(() => _status = '💥 Lỗi: $e');
      log.log('ERR', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test từ Gallery')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(onPressed: _pick, child: const Text('Chọn ảnh')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _run,  child: const Text('Detect + Embedding')),
              ],
            ),
            const SizedBox(height: 12),
            if (_picked != null)
              Text(_picked!.path, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
