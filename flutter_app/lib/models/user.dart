class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;

  /// Cờ đã đăng ký khuôn mặt (mặc định false nếu backend chưa trả)
  final bool faceEnrolled;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.faceEnrolled = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // backend có thể trả face_enrolled / has_face, kiểu bool | num | string
    final raw = j['face_enrolled'] ?? j['has_face'] ?? false;
    final bool enrolled = switch (raw) {
      bool b => b,
      num n => n != 0,
      String s => s == '1' || s.toLowerCase() == 'true',
      _ => false,
    };

    return AppUser(
      id: (j['id'] ?? j['user_id'] as int) as int,
      name: (j['name'] ?? j['full_name'] ?? '') as String,
      email: (j['email'] ?? '') as String,
      role: (j['role'] ?? j['user_role'] ?? '') as String,
      faceEnrolled: enrolled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'face_enrolled': faceEnrolled,
  };
}
