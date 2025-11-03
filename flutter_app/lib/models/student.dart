class Student {
  final int id;
  final String name;
  final String studentCode;
  final String? status;
  final String? checkInTime;


  Student({
    required this.id,
    required this.name,
    required this.studentCode,
    required this.status,
    required this.checkInTime,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['student_id'],
      name: json['student_name'],
      studentCode: json['student_code'],
      status: json['status'] ?? 'absent',
      checkInTime: json['checkin_time'] ?? '--',
    );
  }
}