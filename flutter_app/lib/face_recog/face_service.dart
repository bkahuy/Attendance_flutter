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
      enableLandmarks: true,
      enableContours: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  late final Interpreter _interpreter;
  late final ImageProcessor _processor;
  late final TensorImage _tensorInput;
  late final TensorBuffer _tensorOutput;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(
      'models/mobile_face_net.tflite', // pubspec: assets: - assets/models/mobile_face_net.tflite
      options: InterpreterOptions()..threads = 4,
    );
    final input = _interpreter.getInputTensor(0);
    final output = _interpreter.getOutputTensor(0);
    _processor = ImageProcessorBuilder()
        .add(ResizeOp(112, 112, ResizeMethod.BILINEAR))
        .add(NormalizeOp(127.5, 127.5)) // tuỳ model
        .build();
    _tensorInput = TensorImage(input.type);
    _tensorOutput = TensorBuffer.createFixedSize(output.shape, output.type);
    _ready = true;
  }

  Future<List<Face>> detectFacesFromImageFile(String path) async {
    final input = InputImage.fromFilePath(path);
    return _detector.processImage(input);
  }

  // Đọc file ảnh, crop vùng mặt -> embedding (đã L2 normalize)
  Future<List<double>?> embeddingFromFile(String path, Face face) async {
    final bytes = await File(path).readAsBytes();
    final base = img.decodeImage(bytes);
    if (base == null) return null;

    final bb = face.boundingBox;
    final x = bb.left.round().clamp(0, base.width - 1);
    final y = bb.top.round().clamp(0, base.height - 1);
    final w = bb.width.round().clamp(1, base.width - x);
    final h = bb.height.round().clamp(1, base.height - y);

// ✅ image 4.x: dùng tham số đặt tên
    final faceCrop = img.copyCrop(
      base,
      x: x,
      y: y,
      width: w,
      height: h,
    );

    // Tiền xử lý -> run model
    final tImage = TensorImage.fromImage(faceCrop);      // img.Image -> TensorImage
    final processed = _processor.process(tImage);        // Resize 112x112, Normalize
    _interpreter.run(processed.buffer, _tensorOutput.buffer);

    final raw = _tensorOutput.getDoubleList();
    return _l2norm(raw);
  }

  MapEntry<int,double>? match(
      List<double> probe,
      Map<int, List<double>> db,
      {double threshold = 0.6}) {
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
    for (int i = 0; i < a.length; i++) {
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
    return v.map((e) => e / (n == 0 ? 1 : n)).toList();
  }

  Future<void> dispose() async {
    await _detector.close();
    _interpreter.close();
  }
}
