import 'face_service.dart';

class FaceServiceHolder {
  FaceServiceHolder._();
  static final FaceServiceHolder I = FaceServiceHolder._();

  FaceService? _svc;
  Future<void>? _loading;

  Future<FaceService> get() async {
    if (_svc != null && _svc!.isReady) return _svc!;
    _svc ??= FaceService();
    _loading ??= _svc!.load();
    await _loading;
    return _svc!;
  }
}
