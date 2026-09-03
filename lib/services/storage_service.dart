import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_session';
  static const String _rememberMeKey = 'remember_me_status';
  static const String _rememberEmailKey = 'remembered_email';
  static const String _darkModeKey = 'dark_mode_status';

  // Offline Caching Keys
  static const String _cachedHistoryKey = 'cached_history_data';
  static const String _cachedTodayStatusPrefix = 'cached_today_status_';
  static const String _cachedBirthdaysKey = 'cached_birthdays_';
  static const String pendingAttendancesKey = 'pending_offline_attendances';

  // Save JWT Token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get JWT Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Clear Token & Session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Save User Model
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Get Saved User Model
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString == null) return null;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(userString);
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  // Save Remember Me Preference & Email
  static Future<void> saveRememberMe(bool enabled, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, enabled);
    if (enabled) {
      await prefs.setString(_rememberEmailKey, email);
    } else {
      await prefs.remove(_rememberEmailKey);
    }
  }

  // Get Remember Me Status
  static Future<bool> getRememberMeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Get Remembered Email
  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberEmailKey);
  }

  // Save Dark Mode Preference
  static Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  // Get Dark Mode Status
  static Future<bool> getDarkModeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  // --- Offline Mode: Cache History ---
  static Future<void> saveCachedHistory(List<dynamic> historyJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedHistoryKey, jsonEncode(historyJson));
    } catch (_) {}
  }

  static Future<List<dynamic>?> getCachedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cachedHistoryKey);
      if (data == null) return null;
      return jsonDecode(data) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  // --- Offline Mode: Cache Today Status ---
  static Future<void> saveCachedTodayStatus(String shift, Map<String, dynamic> statusJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachedTodayStatusPrefix$shift', jsonEncode(statusJson));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getCachedTodayStatus(String shift) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_cachedTodayStatusPrefix$shift');
      if (data == null) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // --- Offline Mode: Cache Birthdays ---
  static Future<void> saveCachedBirthdays(String category, List<dynamic> listJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachedBirthdaysKey$category', jsonEncode(listJson));
    } catch (_) {}
  }

  static Future<List<dynamic>?> getCachedBirthdays(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_cachedBirthdaysKey$category');
      if (data == null) return null;
      return jsonDecode(data) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  // --- Offline Mode: Pending Attendances (Queue) ---
  static Future<void> savePendingAttendance(Map<String, dynamic> attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getPendingAttendances();
      list.add(attendance);
      await prefs.setString(pendingAttendancesKey, jsonEncode(list));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getPendingAttendances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(pendingAttendancesKey);
      if (data == null) return [];
      final decoded = jsonDecode(data) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearPendingAttendances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pendingAttendancesKey);
    } catch (_) {}
  }
}
