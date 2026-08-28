import 'user_model.dart';

class AuthResponse {
  final String accessToken;
  final UserModel? user;

  AuthResponse({
    required this.accessToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? json['token'] as String? ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
