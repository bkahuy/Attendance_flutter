// models/session_detail.dart
import 'student.dart';

class SessionDetail {
  final List<Student> students;
  final int presentCount;
  final int absentCount;
  final int lateCount;

  SessionDetail({
    required this.students,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    // Parse danh sách sinh viên
    var studentList = json['students'] as List;
    List<Student> students = studentList.map((i) => Student.fromJson(i)).toList();

    return SessionDetail(
      students: students,
      presentCount: json['counts']['present'] ?? 0,
      absentCount: json['counts']['absent'] ?? 0,
      lateCount: json['counts']['late'] ?? 0,
    );
  }
}