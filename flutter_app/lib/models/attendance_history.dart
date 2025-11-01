// import 'dart:convert';

// Hàm helper để parse danh sách
// List<AttendanceHistory> attendanceSessionFromJson(String str) =>
//     List<AttendanceHistory>.from(
//         json.decode(str).map((x) => AttendanceHistory.fromJson(x)));

class AttendanceHistory {
  final String id; // Thêm ID để biết nhấn vào session nào
  final String courseName;
  final String className;
  final String room;
  final String time;

  AttendanceHistory({
    required this.id,
    required this.courseName,
    required this.className,
    required this.room,
    required this.time,
  });

  // Factory constructor để parse JSON
  factory AttendanceHistory.fromJson(Map<String, dynamic> json) {
    return AttendanceHistory(
      id: json['id'].toString(),
      courseName: json['course_name'] ?? 'N/A',
      className: json['class_name'] ?? 'N/A',
      room: json['room'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
    );
  }
}