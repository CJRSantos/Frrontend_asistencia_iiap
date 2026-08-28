import 'user_model.dart';

class HistorialModel {
  final String id;
  final String userId;
  final UserModel? user;
  final String action;
  final String description;
  final String? ipAddress;
  final String createdAt;

  HistorialModel({
    required this.id,
    required this.userId,
    this.user,
    required this.action,
    required this.description,
    this.ipAddress,
    required this.createdAt,
  });

  factory HistorialModel.fromJson(Map<String, dynamic> json) {
    return HistorialModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : null,
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      ipAddress: json['ip_address'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'ip_address': ipAddress,
      'created_at': createdAt,
    };
  }
}
