class ScheduleItem {
  final String courseCode;
  final String courseName;
  final String term;
  final String room;
  final int weekday;
  final String startTime;
  final String endTime;

  ScheduleItem({
    required this.courseCode,
    required this.courseName,
    required this.term,
    required this.room,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  // Factory constructor để parse JSON thành object ScheduleItem
  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      courseCode: json['course_code'] ?? 'N/A',
      courseName: json['course_name'] ?? 'N/A',
      term: json['term'] ?? 'N/A',
      room: json['room'] ?? 'N/A',
      weekday: json['weekday'] ?? 0,
      startTime: (json['start_time'] as String).substring(0, 5), // Lấy HH:mm
      endTime: (json['end_time'] as String).substring(0, 5),     // Lấy HH:mm
    );
  }
}