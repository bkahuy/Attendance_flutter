import 'dart:io';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/attendance_history.dart';
import '../utils/config.dart';
import '../models/session_detail.dart';
import 'dart:developer'; // Dùng để in log

class AttendanceService {
  final _dio = ApiClient().dio;

  // ===================== QR RESOLVE =====================
  Future<Map<String, dynamic>> resolveQr(String token) async {
    try {
      // Debug: log token being requested
      // (use print so it appears in debug console)
      print('[resolveQr] token -> $token');

      final res = await _dio.get(
        AppConfig.studentResolveQrPath,
        queryParameters: {'token': token},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      // If server returned a JSON body with an error message, prefer it
      final responseData = e.response?.data;
      final statusCode = e.response?.statusCode;
      print('[resolveQr] DioException status: $statusCode, body: $responseData');
      if (responseData is Map) {
        // Laravel validation errors usually come under 'errors' or 'message'
        if (responseData['errors'] != null) {
          try {
            final errors = responseData['errors'] as Map<String, dynamic>;
            final messages = errors.values
                .map((v) => (v is List) ? v.join('; ') : v.toString())
                .join(' | ');
            throw Exception('Validation failed: $messages (status $statusCode)');
          } catch (_) {}
        }
        if (responseData['message'] != null) {
          throw Exception('Server: ${responseData['message']} (status $statusCode)');
        }
        if (responseData['error'] != null) {
          throw Exception('Server: ${responseData['error']} (status $statusCode)');
        }
        // If it's a map but none of the above keys matched, stringify it
        throw Exception('Server response: ${responseData.toString()} (status $statusCode)');
      }
      // Fallback to original message
      throw Exception('DioException [status $statusCode]: ${e.message}');
    }
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
    bool qr = false,
    String? password,
  }) async {
    final mode = {
      if (camera) 'camera': true,
      if (gps) 'gps': true,
      if (qr) 'qr': true,
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
        if (sessionId == null) return "Mã QR không hợp lệ!";
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


  // ===================== GET HISTORY (TEACHER) =====================
  /// Lấy lịch sử các phiên điểm danh của giảng viên (cho Frame 19)
  Future<List<AttendanceHistory>> getAttendanceHistory({
    String? courseName, // Tên môn
    String? className,  // Tên lớp
    String? room,   // Phòng
    String? time,       // Giờ
  }) async {

    // === THÊM LOGIC TẠO THAM SỐ ===
    // Tạo một Map để chứa các tham số truy vấn
    final Map<String, dynamic> queryParameters = {};

    if (courseName != null && courseName.isNotEmpty) {
      queryParameters['course_name'] = courseName;
    }
    if (className != null && className.isNotEmpty) {
      queryParameters['class_name'] = className;
    }
    if (room != null && room.isNotEmpty) {
      queryParameters['room'] = room;
    }
    if (time != null && time.isNotEmpty) {
      queryParameters['time'] = time;
    }

    final res = await _dio.get(
      AppConfig.attendanceHistory,
      queryParameters: queryParameters, // Gửi các tham số tìm kiếm
      options: Options(headers: {'Accept': 'application/json'}),
    );
    log('--- API RESPONSE ---: ${res.data.toString()}');
    // (Phần còn lại của hàm giữ nguyên)
    if (res.data is Map<String, dynamic>) {
      final Map<String, dynamic> responseData = res.data;

      // 4. Lấy giá trị của key 'results' (dựa trên log của bạn)
      final dynamic data = responseData['results'];

      // 5. Kiểm tra xem 'results' có phải là List không
      if (data is List) {
        // Thành công!
        return data.map((item) => AttendanceHistory.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        // 'results' là null hoặc không phải List (ví dụ: tìm không thấy)
        return []; // Trả về danh sách rỗng
      }
    }
    if (res.data is List) {
      List<dynamic> listData = res.data;
      return listData.map((item) => AttendanceHistory.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('API response is not in expected format');
  }

  // ===================== GET SESSION DETAIL (TEACHER) =====================
  /// Lấy chi tiết một phiên điểm danh (cho Frame 20)
  Future<SessionDetail> getSessionDetail(String classSectionId) async {
    final res = await _dio.get(
      "${AppConfig.attendanceHistoryDetail}/$classSectionId/detail",
      options: Options(headers: {'Accept': 'application/json'}),
    );

    // Dio tự động parse JSON, res.data ở đây là một Map<String, dynamic>
    return SessionDetail.fromJson(res.data);
  }
}