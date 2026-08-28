class ApiConfig {
  // Base URL for backend API.
  // When running adb reverse tcp:3000 tcp:3000, http://localhost:3000/api works on physical Android device.
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth endpoints
  static const String loginStep1 = '$baseUrl/auth/login/step-1';
  static const String loginStep2 = '$baseUrl/auth/login/step-2';
  static const String register = '$baseUrl/auth/register';
  static const String meAuth = '$baseUrl/auth/me';
  static const String googleAuth = '$baseUrl/auth/google';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static String verifyAccount(String token) => '$baseUrl/auth/verify/$token';

  // Users endpoints
  static const String usersMe = '$baseUrl/users/me';
  static const String users = '$baseUrl/users';
  static String userById(String id) => '$baseUrl/users/$id';
  static String userRole(String id) => '$baseUrl/users/$id/role';

  // Attendance endpoints
  static const String attendanceMark = '$baseUrl/attendance/mark';
  static const String attendanceMyHistory = '$baseUrl/attendance/my-history';
  static const String attendanceHistory = '$baseUrl/attendance/history';

  // Historial (Audit Trail)
  static const String historialMe = '$baseUrl/historial/me';
  static const String historialAll = '$baseUrl/historial';

  // Schedules endpoints
  static const String schedules = '$baseUrl/schedules';
  static String schedulesByUser(String userId) => '$baseUrl/schedules/user/$userId';
  static String scheduleById(String id) => '$baseUrl/schedules/$id';

  // Projects endpoints
  static const String projects = '$baseUrl/projects';
  static String projectById(String id) => '$baseUrl/projects/$id';

  // Delegations endpoints
  static const String delegations = '$baseUrl/delegations';
  static String deactivateDelegation(String id) => '$baseUrl/delegations/$id/deactivate';

  // Institutions (Sedes) endpoints
  static const String institutions = '$baseUrl/institutions';
  static String institutionById(String id) => '$baseUrl/institutions/$id';

  // Events endpoints
  static const String events = '$baseUrl/events';
  static String eventById(String id) => '$baseUrl/events/$id';

  // Resources endpoints
  static const String resources = '$baseUrl/resources';
  static String resourceById(String id) => '$baseUrl/resources/$id';

  // Birthdays endpoints
  static const String birthdaysUpcoming = '$baseUrl/birthdays/upcoming';
  static const String birthdaysToday = '$baseUrl/birthdays/today';
  static const String birthdaysCalendar = '$baseUrl/birthdays';

  // Courses endpoints
  static const String courses = '$baseUrl/courses';

  // Videos endpoints
  static const String videos = '$baseUrl/videos';

  // Reports endpoints
  static const String reportsNotifications = '$baseUrl/reports/notifications';
  static const String reportsMonthlySummary = '$baseUrl/reports/monthly-summary';

  // Settings endpoints
  static const String settings = '$baseUrl/settings';
}
