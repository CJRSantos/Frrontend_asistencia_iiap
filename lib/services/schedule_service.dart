import '../config/api_config.dart';
import '../models/schedule_model.dart';
import 'api_service.dart';

class ScheduleService {
  // Create schedule
  static Future<ScheduleModel> createSchedule({
    required String userId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await ApiService.post(
      ApiConfig.schedules,
      body: {
        'user_id': userId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      },
      requiresAuth: true,
    );
    return ScheduleModel.fromJson(response as Map<String, dynamic>);
  }

  // Get all schedules
  static Future<List<ScheduleModel>> getAllSchedules() async {
    final response = await ApiService.get(ApiConfig.schedules, requiresAuth: true);
    if (response is List) {
      return response.map((item) => ScheduleModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // Get schedules by User ID
  static Future<List<ScheduleModel>> getSchedulesByUser(String userId) async {
    final response = await ApiService.get(
      ApiConfig.schedulesByUser(userId),
      requiresAuth: true,
    );
    if (response is List) {
      return response.map((item) => ScheduleModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // Update schedule
  static Future<dynamic> updateSchedule(String id, Map<String, dynamic> data) async {
    return await ApiService.patch(
      ApiConfig.scheduleById(id),
      body: data,
      requiresAuth: true,
    );
  }

  // Delete schedule
  static Future<dynamic> deleteSchedule(String id) async {
    return await ApiService.delete(ApiConfig.scheduleById(id), requiresAuth: true);
  }
}
