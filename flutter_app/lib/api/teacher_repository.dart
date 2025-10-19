import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../utils/config.dart';
import '../models/schedule_item.dart';

class TeacherRepository {
  final Dio _dio = ApiClient().dio;

  /// Lịch giảng dạy theo ngày (YYYY-MM-DD)
  Future<List<ScheduleItem>> fetchByDate(String yyyymmdd, {int? teacherUserId}) async {
    final q = <String, dynamic>{'date': yyyymmdd};
    // DEV ONLY: nếu chưa gắn JWT, truyền thêm uid để test
    if (teacherUserId != null) q['teacher_user_id'] = teacherUserId;

    final r = await _dio.get(AppConfig.teacherSchedulePath, queryParameters: q);
    final list = (r.data as List).cast<Map>();
    return list.map((e) => ScheduleItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Tạo phiên điểm danh thủ công
  Future<Map<String, dynamic>> createSession({
    required int classSectionId,
    required DateTime startAt,
    required DateTime endAt,
    bool camera = true,
    bool gps = false,
    String? password,
  }) async {
    final mode = <String, dynamic>{};
    if (camera) mode['camera'] = true;
    if (gps) mode['gps'] = true;
    if (password != null && password.isNotEmpty) mode['password'] = password;

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
    return Map<String, dynamic>.from(res.data as Map);
  }
}
