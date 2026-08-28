import '../config/api_config.dart';
import '../models/birthday_model.dart';
import 'api_service.dart';

class BirthdayService {
  // Get Upcoming Birthdays
  static Future<List<BirthdayModel>> getUpcomingBirthdays() async {
    try {
      final response = await ApiService.get(
        ApiConfig.birthdaysUpcoming,
        requiresAuth: true,
      );

      if (response is List) {
        return response
            .map((item) => BirthdayModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // Get Calendar Birthdays
  static Future<List<BirthdayModel>> getCalendarBirthdays() async {
    try {
      final response = await ApiService.get(
        ApiConfig.birthdaysCalendar,
        requiresAuth: true,
      );

      if (response is List) {
        return response
            .map((item) => BirthdayModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
