// lib/face_recog/preprocess.dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Gói tham số truyền vào isolate
class CropArgs {
  final Uint8List bytes;
  final int x, y, w, h;
  CropArgs(this.bytes, this.x, this.y, this.w, this.h);
}

/// Hàm top-level để dùng với compute()
/// Decode -> crop -> resize (112x112) -> trả về img.Image đã xử lý
img.Image preprocessFace(CropArgs a) {
  final base = img.decodeImage(a.bytes)!;

  // clamp vẫn nên làm từ caller; ở đây giả định đã clamp
  final faceCrop = img.copyCrop(
    base,
    x: a.x,
    y: a.y,
    width: a.w,
    height: a.h,
  );

  final resized = img.copyResize(faceCrop, width: 112, height: 112);
  return resized;
}
