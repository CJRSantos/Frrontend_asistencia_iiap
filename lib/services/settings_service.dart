import '../config/api_config.dart';
import 'api_service.dart';

class SettingsService {
  static Future<dynamic> getSettings() async {
    return await ApiService.get(ApiConfig.settings, requiresAuth: true);
  }

  static Future<dynamic> updateSettings(Map<String, dynamic> data) async {
    return await ApiService.put(
      ApiConfig.settings,
      body: data,
      requiresAuth: true,
    );
  }
}
