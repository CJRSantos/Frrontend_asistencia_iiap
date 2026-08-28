import '../config/api_config.dart';
import '../models/project_model.dart';
import 'api_service.dart';

class ProjectService {
  // Create project
  static Future<ProjectModel> createProject({
    required String name,
    String? description,
  }) async {
    final response = await ApiService.post(
      ApiConfig.projects,
      body: {
        'name': name,
        'description': ?description,
      },
      requiresAuth: true,
    );
    return ProjectModel.fromJson(response as Map<String, dynamic>);
  }

  // Get all projects (optional status filter)
  static Future<List<ProjectModel>> getProjects({String? status}) async {
    String url = ApiConfig.projects;
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }
    final response = await ApiService.get(url, requiresAuth: true);
    if (response is List) {
      return response.map((item) => ProjectModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // Get project by ID
  static Future<ProjectModel> getProjectById(String id) async {
    final response = await ApiService.get(ApiConfig.projectById(id), requiresAuth: true);
    return ProjectModel.fromJson(response as Map<String, dynamic>);
  }

  // Update project
  static Future<dynamic> updateProject(String id, Map<String, dynamic> data) async {
    return await ApiService.patch(
      ApiConfig.projectById(id),
      body: data,
      requiresAuth: true,
    );
  }

  // Delete project
  static Future<dynamic> deleteProject(String id) async {
    return await ApiService.delete(ApiConfig.projectById(id), requiresAuth: true);
  }
}
