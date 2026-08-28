import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  // Step 1 Login - Validate Email
  static Future<Map<String, dynamic>> loginStep1(String email) async {
    final response = await ApiService.post(
      ApiConfig.loginStep1,
      body: {'email': email},
      requiresAuth: false,
    );
    return response as Map<String, dynamic>;
  }

  // Step 2 Login - Email & Password
  static Future<AuthResponse> loginStep2(String email, String password) async {
    final response = await ApiService.post(
      ApiConfig.loginStep2,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response as Map<String, dynamic>);
    
    // Save JWT token
    if (authResponse.accessToken.isNotEmpty) {
      await StorageService.saveToken(authResponse.accessToken);

      // If user profile is provided in response, save it; otherwise fetch profile
      if (authResponse.user != null) {
        await StorageService.saveUser(authResponse.user!);
      } else {
        try {
          final user = await getProfile();
          await StorageService.saveUser(user);
        } catch (_) {}
      }
    }

    return authResponse;
  }

  // Google Login (with idToken)
  static Future<AuthResponse> googleLogin(String idToken) async {
    final response = await ApiService.post(
      ApiConfig.googleAuth,
      body: {'idToken': idToken},
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response as Map<String, dynamic>);
    if (authResponse.accessToken.isNotEmpty) {
      await StorageService.saveToken(authResponse.accessToken);
      if (authResponse.user != null) {
        await StorageService.saveUser(authResponse.user!);
      } else {
        try {
          final user = await getProfile();
          await StorageService.saveUser(user);
        } catch (_) {}
      }
    }
    return authResponse;
  }

  // Forgot Password
  static Future<dynamic> forgotPassword(String email) async {
    return await ApiService.post(
      ApiConfig.forgotPassword,
      body: {'email': email},
      requiresAuth: false,
    );
  }

  // Reset Password
  static Future<dynamic> resetPassword(String token, String newPassword) async {
    return await ApiService.post(
      ApiConfig.resetPassword,
      body: {
        'token': token,
        'newPassword': newPassword,
      },
      requiresAuth: false,
    );
  }

  // Verify Account via Token
  static Future<dynamic> verifyAccount(String token) async {
    return await ApiService.get(
      ApiConfig.verifyAccount(token),
      requiresAuth: false,
    );
  }

  // Account Registration (Cumple con RegisterDto estricto de NestJS)
  static Future<dynamic> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'full_name': fullName,
    };

    final response = await ApiService.post(
      ApiConfig.register,
      body: body,
      requiresAuth: false,
    );
    return response;
  }

  // Get Current User Profile
  static Future<UserModel> getProfile() async {
    final response = await ApiService.get(ApiConfig.usersMe, requiresAuth: true);
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    await StorageService.saveUser(user);
    return user;
  }

  // Update Current User Profile (/api/users/me)
  static Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.patch(
      ApiConfig.usersMe,
      body: data,
      requiresAuth: true,
    );
    final updatedUser = UserModel.fromJson(response as Map<String, dynamic>);
    await StorageService.saveUser(updatedUser);
    return updatedUser;
  }

  // Logout & Clear Session
  static Future<void> logout() async {
    await StorageService.clearSession();
  }
}
