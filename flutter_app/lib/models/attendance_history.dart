class AttendanceHistory {
  final String id; // Thêm ID để biết nhấn vào session nào
  final String courseName;
  final String className;
  final String room;
  final String startTime;
  final String endAt;
  final String time;

  AttendanceHistory({
    required this.id,
    required this.courseName,
    required this.className,
    required this.room,
    required this.startTime,
    required this.endAt,
    required this.time,
  });

  // Factory constructor để parse JSON
  factory AttendanceHistory.fromJson(Map<String, dynamic> json) {
    return AttendanceHistory(
      id: json['id'].toString(),
      courseName: json['course_name'] ?? 'N/A',
      className: json['class_names'] ?? 'N/A',
      room: json['room'] ?? 'N/A',
      startTime: json['start_time'] ?? 'N/A',
      endAt: json['end_at'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
    );
  }
}