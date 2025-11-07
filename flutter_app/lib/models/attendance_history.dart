class AttendanceHistory {
  final String id; // Thêm ID để biết nhấn vào session nào
  final String classSectionId;
  final String sessionId;
  final String courseName;
  final String className;
  final String room;
  final String startTime;
  final String endAt;
  final String time;
  final String createdAt;


  AttendanceHistory({
    required this.id,
    required this.classSectionId,
    required this.sessionId,
    required this.courseName,
    required this.className,
    required this.room,
    required this.startTime,
    required this.endAt,
    required this.time,
    required this.createdAt,
  });

  // Factory constructor để parse JSON
  factory AttendanceHistory.fromJson(Map<String, dynamic> json) {
    return AttendanceHistory(
      id: json['id'].toString(),
      classSectionId: json['class_section_id'].toString(),
      sessionId: json['session_id'].toString(),
      courseName: json['course_name'] ?? 'N/A',
      className: json['class_names'] ?? 'N/A',
      room: json['room'] ?? 'N/A',
      startTime: json['start_time'] ?? 'N/A',
      endAt: json['end_at'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
      createdAt: json['created_at'] ?? 'N/A',
    );
  }
}