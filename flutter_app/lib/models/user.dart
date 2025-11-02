class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;

  AppUser({required this.id, required this.name, required this.email, required this.role});

  factory AppUser.fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: (j['id'] as num).toInt(),
      name: j['name'] ?? '',
      email: j['email'] ?? '',
      role: j['role'] ?? '',
    );
  }
}
