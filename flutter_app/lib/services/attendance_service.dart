import 'dart:io';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../utils/config.dart';

class AttendanceService {
  final _dio = ApiClient().dio;

  // ===================== QR RESOLVE =====================
  Future<Map<String, dynamic>> resolveQr(String token) async {
    final res = await _dio.get(
      AppConfig.studentResolveQrPath,
      queryParameters: {'token': token},
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return Map<String, dynamic>.from(res.data);
  }

  // ===================== CHECK-IN =====================
  Future<void> checkIn({
    required int sessionId,
    required String status,
    String? password,
    double? lat,
    double? lng,
    File? photoFile,
  }) async {
    final form = FormData.fromMap({
      'session_id': sessionId,
      'status': status,
      if (password != null && password.isNotEmpty) 'password': password,
      if (lat != null) 'gps_lat': lat,
      if (lng != null) 'gps_lng': lng,
      if (photoFile != null)
        'photo': await MultipartFile.fromFile(photoFile.path, filename: 'checkin.jpg'),
    });

    await _dio.post(
      AppConfig.studentCheckinPath,
      data: form,
      options: Options(headers: {'Accept': 'application/json'}),
    );
  }

  // ===================== CREATE SESSION (TEACHER) =====================
  Future<Map<String, dynamic>> createSession({
    required int classSectionId,
    required DateTime startAt,
    required DateTime endAt,
    bool camera = true,
    bool gps = false,
    String? password,
  }) async {
    final mode = {
      if (camera) 'camera': true,
      if (gps) 'gps': true,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final res = await _dio.post(
      AppConfig.teacherCreateSessionPath,
      data: {
        'class_section_id': classSectionId,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'mode_flags': mode,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return Map<String, dynamic>.from(res.data);
  }

  // ===================== QR CHECK-IN HANDLER =====================
  /// Xử lý khi sinh viên quét mã QR
  /// [qrData] là chuỗi đọc từ mã QR, có thể chứa token hoặc sessionId
  Future<String> handleQrCheckIn(String qrData) async {
    try {
      // Nếu QR chứa token, resolve token -> sessionId
      if (qrData.startsWith("attendance_token_")) {
        final token = qrData.replaceFirst("attendance_token_", "");
        final resolved = await resolveQr(token);
        final sessionId = resolved['session_id'];
        await checkIn(sessionId: sessionId, status: "present");
        return "✅ Điểm danh thành công!";
      }

      // Nếu QR chứa sessionId trực tiếp
      else if (qrData.startsWith("attendance_session_")) {
        final sessionId = int.tryParse(qrData.replaceFirst("attendance_session_", ""));
        if (sessionId == null) return "❌ Mã QR không hợp lệ!";
        await checkIn(sessionId: sessionId, status: "present");
        return "✅ Điểm danh thành công!";
      }

      // QR không đúng định dạng
      else {
        return "❌ Mã QR không hợp lệ!";
      }
    } catch (e) {
      return "❌ Lỗi khi điểm danh: $e";
    }
  }
}
