import '../config/api_config.dart';
import '../models/institution_model.dart';
import 'api_service.dart';

class InstitutionService {
  static Future<InstitutionModel> createInstitution(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.institutions, body: data, requiresAuth: true);
    return InstitutionModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<List<InstitutionModel>> getAllInstitutions() async {
    final response = await ApiService.get(ApiConfig.institutions, requiresAuth: true);
    if (response is List) {
      return response.map((item) => InstitutionModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<InstitutionModel> getInstitutionById(String id) async {
    final response = await ApiService.get(ApiConfig.institutionById(id), requiresAuth: true);
    return InstitutionModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<dynamic> updateInstitution(String id, Map<String, dynamic> data) async {
    return await ApiService.patch(ApiConfig.institutionById(id), body: data, requiresAuth: true);
  }

  static Future<dynamic> deleteInstitution(String id) async {
    return await ApiService.delete(ApiConfig.institutionById(id), requiresAuth: true);
  }
}
