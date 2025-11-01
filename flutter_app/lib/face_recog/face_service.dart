import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_processing/tflite_flutter_processing.dart';
import 'package:image/image.dart' as img;

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
  late TensorImage _tensorInput;
  late TensorBuffer _tensorOutput;

  late List<int> _inShape;   // [1, 112, 112, 3]
  late List<int> _outShape;  // [1, 192] hoặc tương tự

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobile_face_net.tflite',
      options: InterpreterOptions()..threads = 4,
    );

    final inTensor  = _interpreter.getInputTensor(0);
    final outTensor = _interpreter.getOutputTensor(0);
    print('[TFLite] IN shape=${inTensor.shape}, type=${inTensor.type} | '
        'OUT shape=${outTensor.shape}, type=${outTensor.type}');

    _inShape  = inTensor.shape;   // [1, H, W, C]
    _outShape = outTensor.shape;  // [1, D]

    final h = _inShape.length >= 3 ? _inShape[1] : 112;
    final w = _inShape.length >= 3 ? _inShape[2] : 112;

    _processor = ImageProcessorBuilder()
        .add(ResizeOp(h, w, ResizeMethod.BILINEAR))
        .add(NormalizeOp(127.5, 127.5))
        .build();

    // ✅ Dùng đúng kiểu từ tensor của model (khỏi cần viết TfLiteType.float32)
    _tensorInput  = TensorImage(inTensor.type);
    _tensorOutput = TensorBuffer.createFixedSize(_outShape, outTensor.type);

    _ready = true;
  }


  Future<List<Face>> detectFacesFromImageFile(String path) async {
    final input = InputImage.fromFilePath(path);
    return _detector.processImage(input);
  }

  // Đọc file ảnh, crop bbox -> embedding (L2-normalize)
  Future<List<double>?> embeddingFromFile(String path, Face face) async {
    if (!_ready) {
      // Nếu quên load() sẽ lỗi precondition
      await load();
    }

    final bytes = await File(path).readAsBytes();
    final base = img.decodeImage(bytes);
    if (base == null) return null;

    // BBOX an toàn
    final bb = face.boundingBox;
    final x = bb.left.round().clamp(0, base.width - 1);
    final y = bb.top.round().clamp(0, base.height - 1);
    final w = bb.width.round().clamp(1, base.width - x);
    final h = bb.height.round().clamp(1, base.height - y);

    // image 4.x yêu cầu tham số có tên
    final faceCrop = img.copyCrop(
      base,
      x: x,
      y: y,
      width: w,
      height: h,
    );

    // === TIỀN XỬ LÝ ĐÚNG THỨ TỰ ===
    // 1) nạp ảnh vào tensor float32
    _tensorInput.loadImage(faceCrop);
    // 2) resize + normalize theo processor
    _tensorInput = _processor.process(_tensorInput);

    // 3) chạy model (buffer input/output phải KHỚP kiểu & shape)
    _interpreter.run(_tensorInput.buffer, _tensorOutput.buffer);

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
