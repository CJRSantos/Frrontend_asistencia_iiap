import '../config/api_config.dart';
import '../models/resource_model.dart';
import 'api_service.dart';

class ResourceService {
  static Future<ResourceModel> createResource(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.resources, body: data, requiresAuth: true);
    return ResourceModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<List<ResourceModel>> getAllResources({String? status}) async {
    String url = ApiConfig.resources;
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }
    final response = await ApiService.get(url, requiresAuth: true);
    if (response is List) {
      return response.map((item) => ResourceModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<ResourceModel> getResourceById(String id) async {
    final response = await ApiService.get(ApiConfig.resourceById(id), requiresAuth: true);
    return ResourceModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<dynamic> updateResource(String id, Map<String, dynamic> data) async {
    return await ApiService.patch(ApiConfig.resourceById(id), body: data, requiresAuth: true);
  }

  static Future<dynamic> deleteResource(String id) async {
    return await ApiService.delete(ApiConfig.resourceById(id), requiresAuth: true);
  }
}
