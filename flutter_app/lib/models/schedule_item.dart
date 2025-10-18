class ScheduleItem {
  final String courseName;
  final String className;
  final String room;
  final String startTime;
  final String endTime;

  ScheduleItem({
    required this.courseName,
    required this.className,
    required this.room,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      courseName: json['course_name'] ?? '',
      className: json['class_name'] ?? '',
      room: json['room'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }
}
