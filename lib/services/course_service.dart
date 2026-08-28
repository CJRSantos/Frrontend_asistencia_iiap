import '../config/api_config.dart';
import '../models/course_model.dart';
import 'api_service.dart';

class CourseService {
  static Future<List<CourseModel>> getCourses() async {
    final response = await ApiService.get(ApiConfig.courses, requiresAuth: true);
    if (response is List) {
      return response.map((item) => CourseModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<dynamic> createCourse(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.courses, body: data, requiresAuth: true);
  }
}
