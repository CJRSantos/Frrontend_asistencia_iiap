import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

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

  // Upload Profile Photo (POST /api/users/me/photo with Base64 fallback)
  static Future<Map<String, dynamic>> uploadProfilePhoto({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final response = await ApiService.uploadMultipart(
        ApiConfig.userPhotoUpload,
        fileField: 'file',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName ?? 'profile.jpg',
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        if (response['user'] is Map<String, dynamic>) {
          final updatedUser = UserModel.fromJson(response['user'] as Map<String, dynamic>);
          await StorageService.saveUser(updatedUser);
        } else if (response['photo_url'] != null) {
          final currentUser = await StorageService.getUser();
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(photoUrl: response['photo_url'].toString());
            await StorageService.saveUser(updatedUser);
          }
        }
        return response;
      }
    } catch (e) {
      // Automatic Base64 fallback if multipart fails
      try {
        List<int>? bytes = fileBytes;
        if (bytes == null && filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          String ext = 'jpeg';
          if (filePath != null && filePath.contains('.')) {
            ext = filePath.split('.').last.toLowerCase();
            if (ext == 'jpg') ext = 'jpeg';
          }
          final base64String = 'data:image/$ext;base64,${base64Encode(bytes)}';
          final response = await ApiService.post(
            ApiConfig.userPhotoUploadBase64,
            body: {'image_base64': base64String},
            requiresAuth: true,
          );

          if (response is Map<String, dynamic>) {
            if (response['user'] is Map<String, dynamic>) {
              final updatedUser = UserModel.fromJson(response['user'] as Map<String, dynamic>);
              await StorageService.saveUser(updatedUser);
            } else if (response['photo_url'] != null) {
              final currentUser = await StorageService.getUser();
              if (currentUser != null) {
                final updatedUser = currentUser.copyWith(photoUrl: response['photo_url'].toString());
                await StorageService.saveUser(updatedUser);
              }
            }
            return response;
          }
        }
      } catch (_) {}
      rethrow;
    }
    return {'message': 'Foto actualizada con éxito'};
  }
}
