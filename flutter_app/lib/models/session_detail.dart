import 'student.dart';

class SessionDetail {
//   final String? studentName;
//   final String? studentCode;
//   final String? checkInTime;
//   final String? attendanceStatus;
//   final int? sessionId;
//
//   SessionDetail({
//     this.studentName,
//     this.studentCode,
//     this.checkInTime,
//     this.attendanceStatus,
//     this.sessionId,
//   });
//
//   // Hàm fromJson này sẽ nhận phần 'data' từ JSON
//   factory SessionDetail.fromJson(Map<String, dynamic> json) {
//     return SessionDetail(
//       studentName: json['student_name'],
//       studentCode: json['student_code'],
//       checkInTime: json['checkin_time'],
//       attendanceStatus: json['attendance_status'],
//       sessionId: json['session_id'],
//     );
//   }
// }


  final SessionInfo sessionInfo;
  final List<Student> students;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  SessionDetail({
    required this.sessionInfo,
    required this.students,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  // Hàm fromJson này sẽ nhận phần 'data' từ JSON
  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    // 1. Phân tích danh sách (List) sinh viên
    var studentListFromJson = json['students'] as List;
    List<Student> studentList = studentListFromJson
        .map((i) => Student.fromJson(i))
        .toList();

    // 2. Xây dựng đối tượng SessionDetail
    return SessionDetail(
      // 2a. Phân tích đối tượng (Map) session_info
      sessionInfo: SessionInfo.fromJson(json['session_info']),
      // 2b. Gán danh sách sinh viên đã phân tích
      students: studentList,
      // 2c. Lấy các giá trị đếm
      presentCount: json['present_count'],
      lateCount: json['late_count'],
      absentCount: json['absent_count'],
    );
  }
}


class SessionInfo {
  final int id;
  final String? checkInTime;
  final String courseName;

  SessionInfo({
    required this.id,
    required this.checkInTime,
    required this.courseName,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'],
      checkInTime: json['checkin_time'] ?? '--',
      courseName: json['course_name'],
    );
  }
}