import 'user_model.dart';

class ReportNotificationModel {
  final String id;
  final String title;
  final String message;
  final String? type;
  final String? status;
  final String? createdAt;
  final UserModel? sender;

  ReportNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.status,
    this.createdAt,
    this.sender,
  });

  factory ReportNotificationModel.fromJson(Map<String, dynamic> json) {
    return ReportNotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? json['subject'] ?? 'Notificación',
      message: json['message'] ?? json['content'] ?? '',
      type: json['type'],
      status: json['status'],
      createdAt: json['created_at'],
      sender: json['sender'] != null && json['sender'] is Map<String, dynamic>
          ? UserModel.fromJson(json['sender'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'status': status,
      'created_at': createdAt,
    };
  }
}
