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
      print('[resolveQr] token -> $token');

      final res = await _dio.get(
        AppConfig.studentResolveQrPath,
        queryParameters: {'token': token},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final statusCode = e.response?.statusCode;
      print('[resolveQr] DioException status: $statusCode, body: $responseData');
      if (responseData is Map) {
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
        throw Exception('Server response: ${responseData.toString()} (status $statusCode)');
      }
      throw Exception('DioException [status $statusCode]: ${e.message}');
    }
  }

  Future<void> checkIn({
    required int sessionId,
    required String status,
    required String templateBase64, // 👈 Đổi từ File sang String
    String? password,
    double? lat,
    double? lng,
  }) async {
    try {
      // 1. 🎨 Gửi JSON (thay vì FormData)
      await _dio.post(
        AppConfig.studentCheckinPath, // 👈 Đảm bảo bạn có AppConfig.studentCheckinPath
        data: {
          'attendance_session_id': sessionId,
          'status': status,
          'template_base64': templateBase64, // 👈 Gửi template
          'password': password,
          'gps_lat': lat,
          'gps_lng': lng,
        },
      );
    } on DioException catch (e) {
      // 2. 🎨 Xử lý lỗi validation (422) tốt hơn
      final responseData = e.response?.data;
      if (responseData is Map && responseData['error'] != null) {
        throw Exception(responseData['error']);
      }
      throw Exception('Lỗi điểm danh: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      throw Exception('Lỗi điểm danh: $e');
    }
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

  // 🎨 ĐÃ XÓA HÀM 'handleQrCheckIn'
  // (Vì logic này đã cũ, không bao gồm quét mặt)


  // ===================== GET HISTORY (TEACHER) =====================
  Future<List<AttendanceHistory>> getAttendanceHistory({
    String? courseName,
    String? className,
    String? room,
    String? startTime,
  }) async {
    final Map<String, dynamic> queryParameters = {};
    if (courseName != null && courseName.isNotEmpty) {
      queryParameters['course_name'] = courseName;
    }
    if (className != null && className.isNotEmpty) {
      queryParameters['class_names'] = className;
    }
    if (room != null && room.isNotEmpty) {
      queryParameters['room'] = room;
    }
    if (startTime != null && startTime.isNotEmpty) {
      queryParameters['start_time'] = startTime;
    }

    final res = await _dio.get(
      AppConfig.attendanceHistory,
      queryParameters: queryParameters, // Gửi các tham số tìm kiếm
      options: Options(headers: {'Accept': 'application/json'}),
    );
    log('--- API RESPONSE ---: ${res.data.toString()}');
    if (res.data is Map<String, dynamic>) {
      final Map<String, dynamic> responseData = res.data;
      final dynamic data = responseData['results'];
      if (data is List) {
        return data.map((item) => AttendanceHistory.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        return [];
      }
    }
    if (res.data is List) {
      List<dynamic> listData = res.data;
      return listData.map((item) => AttendanceHistory.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('API response is not in expected format');
  }

  // ===================== GET SESSION DETAIL (TEACHER) =====================
  Future<SessionDetail> getSessionDetail(String classSectionId) async {
    final res = await _dio.get(
      "${AppConfig.attendanceHistoryDetail}/$classSectionId/detail",
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return SessionDetail.fromJson(res.data);
  }
}