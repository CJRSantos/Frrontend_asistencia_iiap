import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConfig.authLogin,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      requiresAuth: false,
    );

    final token = response['access_token']?.toString() ?? '';
    final userJson = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await StorageService.saveSession(token: token, user: user);
    return user;
  }

  static Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? documentNumber,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    if (documentNumber != null && documentNumber.trim().isNotEmpty) {
      body['document_number'] = documentNumber.trim();
    }
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      body['phone_number'] = phoneNumber.trim();
    }

    final response = await ApiClient.post(
      ApiConfig.authRegister,
      body: body,
      requiresAuth: false,
    );

    final token = response['access_token']?.toString() ?? '';
    final userJson = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    await StorageService.saveSession(token: token, user: user);
    return user;
  }

  static Future<UserModel> getProfile() async {
    final response = await ApiClient.get(ApiConfig.authMe);
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    await StorageService.updateCurrentUser(user);
    return user;
  }

  static Future<void> logout() async {
    await StorageService.clearSession();
  }
}
