class AppConfig {
  // static const String BASE_URL = 'http://103.75.183.227';
  static const String BASE_URL = 'http://10.0.2.2:8000';
  static const String loginPath = '/api/auth/login';
  static const String profilePath = '/api/auth/profile';
  static const String changePasswordPath = '/api/auth/change-password';
  static const String teacherSchedulePath = '/api/teacher/schedule';
  static const String teacherCreateSessionPath = '/api/attendance/session';
  static const String studentSchedulePath = '/api/student/schedule';
  static const String studentResolveQrPath = '/api/attendance/resolve-qr';
  static const String studentCheckinPath = '/api/attendance/checkin';
}
