import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  // Get all users (Admin only)
  static Future<List<UserModel>> getAllUsers() async {
    final response = await ApiService.get(ApiConfig.users, requiresAuth: true);
    if (response is List) {
      return response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // Get single user by ID
  static Future<UserModel> getUserById(String id) async {
    final response = await ApiService.get(ApiConfig.userById(id), requiresAuth: true);
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  // Update user by ID (Admin)
  static Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final response = await ApiService.patch(
      ApiConfig.userById(id),
      body: data,
      requiresAuth: true,
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  // Delete user by ID (Admin)
  static Future<dynamic> deleteUser(String id) async {
    return await ApiService.delete(ApiConfig.userById(id), requiresAuth: true);
  }

  // Assign role to user (EMPLOYEE, ADMIN, SUPERADMIN)
  static Future<dynamic> assignRole(String id, String role) async {
    return await ApiService.patch(
      ApiConfig.userRole(id),
      body: {'role': role},
      requiresAuth: true,
    );
  }
}
