import '../config/api_config.dart';
import '../models/attendance_model.dart';
import 'api_service.dart';

class AttendanceService {
  // Mark Attendance (CHECK_IN, CHECK_OUT, BREAK_START, BREAK_END)
  static Future<dynamic> markAttendance({
    required String type, // CHECK_IN or CHECK_OUT
    required double latitude,
    required double longitude,
    String? photoUrl,
    String? deviceId,
    String? observations,
    String? projectId,
    String? verificationMethod = 'MANUAL',
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'verification_method': verificationMethod,
    };

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

    final response = await ApiService.post(
      ApiConfig.attendanceMark,
      body: body,
      requiresAuth: true,
    );
    return response;
  }

  // Get My Attendance History
  static Future<List<AttendanceModel>> getMyHistory() async {
    final response = await ApiService.get(
      ApiConfig.attendanceMyHistory,
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
