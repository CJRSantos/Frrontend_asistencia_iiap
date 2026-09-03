import '../config/api_config.dart';
import '../models/attendance_model.dart';
import '../models/today_attendance_status_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  // Coordenadas oficiales de la Sede Central del IIAP (Iquitos)
  static const double sedeCentralLatitude = -3.7719;
  static const double sedeCentralLongitude = -73.2690;
  static const int sedeCentralRadiusMeters = 1000;
  static const String sedeCentralName = 'Sede Central IIAP - Iquitos (Av. Quiñones km 2.5)';

  // Mark Attendance (CHECK_IN, CHECK_OUT) - POST /api/attendance/mark
  static Future<dynamic> markAttendance({
    required String type, // CHECK_IN or CHECK_OUT
    double latitude = sedeCentralLatitude,
    double longitude = sedeCentralLongitude,
    String? photoUrl,
    String? deviceId,
    String? observations,
    String? projectId,
    String? userId,
    String? verificationMethod = 'MANUAL',
    String? shift, // 'MORNING' (8:30-13:00) or 'AFTERNOON' (13:00-18:30)
    String? recordedAt, // ISO timestamp for offline sync
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'verification_method': verificationMethod ?? 'MANUAL',
    };

    if (shift != null && shift.isNotEmpty) {
      body['shift'] = shift;
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      body['photo_url'] = photoUrl;
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      body['device_id'] = deviceId;
    }
    if (observations != null && observations.isNotEmpty) {
      body['observations'] = observations;
    }
    if (projectId != null && projectId.isNotEmpty) {
      body['project_id'] = projectId;
    }
    if (userId != null && userId.isNotEmpty) {
      body['user_id'] = userId;
    }
    if (recordedAt != null && recordedAt.isNotEmpty) {
      body['recorded_at'] = recordedAt;
    }

    final response = await ApiService.post(
      ApiConfig.attendanceMark,
      body: body,
      requiresAuth: true,
    );
    return response;
  }

  // Get Today Attendance Status (GET /api/attendance/today-status)
  static Future<TodayAttendanceStatusModel?> getTodayStatus({String? shift}) async {
    final shiftKey = shift ?? 'DEFAULT';
    try {
      final url = shift != null && shift.isNotEmpty
          ? '${ApiConfig.attendanceTodayStatus}?shift=$shift'
          : ApiConfig.attendanceTodayStatus;
      final response = await ApiService.get(
        url,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        await StorageService.saveCachedTodayStatus(shiftKey, response);
        return TodayAttendanceStatusModel.fromJson(response);
      }
    } catch (_) {
      final cached = await StorageService.getCachedTodayStatus(shiftKey);
      if (cached != null) {
        return TodayAttendanceStatusModel.fromJson(cached);
      }
    }
    return null;
  }

  // Clear My Attendance History (Deletes from DB)
  static Future<void> clearMyHistory() async {
    await ApiService.delete(
      ApiConfig.attendanceClearMyHistory,
      requiresAuth: true,
    );
  }

  // Get My Attendance History
  static Future<List<AttendanceModel>> getMyHistory() async {
    try {
      final response = await ApiService.get(
        ApiConfig.attendanceMyHistory,
        requiresAuth: true,
      );

      List<dynamic>? rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        rawList = response['data'] as List;
      }

      if (rawList != null) {
        await StorageService.saveCachedHistory(rawList);
        return rawList
            .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      final cached = await StorageService.getCachedHistory();
      if (cached != null) {
        return cached
            .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  // Sincronizar marcaciones guardadas en modo offline
  static Future<int> syncPendingAttendances() async {
    final pending = await StorageService.getPendingAttendances();
    if (pending.isEmpty) return 0;

    int syncedCount = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final item in pending) {
      try {
        await ApiService.post(
          ApiConfig.attendanceMark,
          body: item,
          requiresAuth: true,
        );
        syncedCount++;
      } catch (e) {
        if (e is ApiException && (e.message.toLowerCase().contains('conexi') || e.message.toLowerCase().contains('servidor'))) {
          remaining.add(item);
        }
      }
    }

    if (remaining.isEmpty) {
      await StorageService.clearPendingAttendances();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageService.pendingAttendancesKey, jsonEncode(remaining));
    }

    return syncedCount;
  }

  // Get Global Attendance History (Admin / Supervisor)
  static Future<List<AttendanceModel>> getAllHistory({int limit = 50}) async {
    final response = await ApiService.get(
      '${ApiConfig.attendanceHistory}?limit=$limit',
      requiresAuth: true,
    );

    if (response is List) {
      return response
          .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
