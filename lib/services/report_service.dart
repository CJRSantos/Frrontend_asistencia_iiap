import '../config/api_config.dart';
import '../models/report_model.dart';
import 'api_service.dart';

class ReportService {
  static Future<dynamic> createNotification(Map<String, dynamic> data) async {
    return await ApiService.post(
      ApiConfig.reportsNotifications,
      body: data,
      requiresAuth: true,
    );
  }

  static Future<List<ReportNotificationModel>> getNotifications() async {
    final response = await ApiService.get(
      ApiConfig.reportsNotifications,
      requiresAuth: true,
    );
    if (response is List) {
      return response
          .map((item) => ReportNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<dynamic> getMonthlySummary(int year, int month) async {
    final url = '${ApiConfig.reportsMonthlySummary}?year=$year&month=$month';
    return await ApiService.get(url, requiresAuth: true);
  }
}
