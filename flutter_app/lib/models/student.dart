// models/student.dart
class Student {
  final String id;
  final String name;
  final String status;

  Student({
    required this.id,
    required this.name,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),
      name: json['name'] ?? 'N/A',
      status: json['status'] ?? 'Vắng', // Mặc định là 'Vắng'
    );
  }
}