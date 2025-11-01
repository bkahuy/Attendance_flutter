import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';                     // ⬅️ thêm
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_processing/tflite_flutter_processing.dart';
import 'package:image/image.dart' as img;

import 'preprocess.dart';                                      // ⬅️ thêm

class FaceService {
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast, // nhẹ hơn
      enableLandmarks: false,                  // tắt
      enableContours: false,                   // tắt
      minFaceSize: 0.15,                       // chỉ nhận mặt đủ lớn
    ),
  );

  late final Interpreter _interpreter;
  late final ImageProcessor _processor;
  late TensorImage _tensorInput;
  late TensorBuffer _tensorOutput;

  late List<int> _inShape;   // [1, 112, 112, 3]
  late List<int> _outShape;  // [1, 192] hoặc tương tự

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobile_face_net.tflite', // <-- sửa đúng key như pubspec
      options: InterpreterOptions()..threads = 4,
    );

    final input = _interpreter.getInputTensor(0);
    final output = _interpreter.getOutputTensor(0);

    _processor = ImageProcessorBuilder()
    // 112x112 đúng với MobileFaceNet
        .add(ResizeOp(112, 112, ResizeMethod.BILINEAR))
    // Chuẩn hoá [-1,1] (tuỳ model; bạn đang dùng mean=127.5/std=127.5 là ok)
        .add(NormalizeOp(127.5, 127.5))
        .build();

    _tensorInput  = TensorImage(input.type);
    _tensorOutput = TensorBuffer.createFixedSize(output.shape, output.type);

    _ready = true;
  }


  Future<List<Face>> detectFacesFromImageFile(String path) async {
    final input = InputImage.fromFilePath(path);
    return _detector.processImage(input);
  }

  /// Đọc ảnh -> (isolate) decode/crop/resize -> TensorImage -> run -> L2 norm
  Future<List<double>?> embeddingFromFile(String path, Face face) async {
    if (!_ready) {
      // Nếu quên load() sẽ lỗi precondition
      await load();
    }

    final bytes = await File(path).readAsBytes();

    // Clamp bounding box an toàn
    final tmp = img.decodeImage(bytes);
    if (tmp == null) return null;
    final bb = face.boundingBox;
    final x = bb.left.round().clamp(0, tmp.width  - 1);
    final y = bb.top .round().clamp(0, tmp.height - 1);
    final w = bb.width .round().clamp(1, tmp.width  - x);
    final h = bb.height.round().clamp(1, tmp.height - y);

    // ✅ chuyển xử lý nặng sang isolate
    final pre = await compute(preprocessFace, CropArgs(bytes, x, y, w, h));

    // Load vào TensorImage, sau đó apply ImageProcessor
    _tensorInput.loadImage(pre);
    final processed = _processor.process(_tensorInput);

    // Run model
    _interpreter.run(processed.buffer, _tensorOutput.buffer);

    // 4) lấy ra list double và L2-normalize
    final raw = _tensorOutput.getDoubleList(); // hoặc getFloatList rồi map -> double
    return _l2norm(raw);
  }

  MapEntry<int, double>? match(
      List<double> probe,
      Map<int, List<double>> db, {
        double threshold = 0.6,
      }) {
    int? bestId;
    double bestScore = -1;
    for (final e in db.entries) {
      final s = _cosine(probe, e.value);
      if (s > bestScore) {
        bestScore = s;
        bestId = e.key;
      }
    }
    if (bestId != null && bestScore >= threshold) {
      return MapEntry(bestId, bestScore);
    }
    return null;
  }

  double _cosine(List<double> a, List<double> b) {
    double dot = 0, na = 0, nb = 0;
    final n = min(a.length, b.length);
    for (int i = 0; i < n; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    return dot / (sqrt(na) * sqrt(nb));
  }

  List<double> _l2norm(List<double> v) {
    double n = 0;
    for (final x in v) n += x * x;
    n = sqrt(n);
    if (n == 0) return v;
    return v.map((e) => e / n).toList();
  }

  Future<void> dispose() async {
    await _detector.close();
    _interpreter.close();
  }
}
