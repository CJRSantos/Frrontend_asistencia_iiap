import '../config/api_config.dart';
import '../models/historial_model.dart';
import 'api_service.dart';

class HistorialService {
  static Future<List<HistorialModel>> getMyHistory() async {
    final response = await ApiService.get(ApiConfig.historialMe, requiresAuth: true);
    if (response is List) {
      return response.map((item) => HistorialModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<List<HistorialModel>> getAllHistory() async {
    final response = await ApiService.get(ApiConfig.historialAll, requiresAuth: true);
    if (response is List) {
      return response.map((item) => HistorialModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
