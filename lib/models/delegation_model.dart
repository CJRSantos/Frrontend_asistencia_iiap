import 'user_model.dart';

class DelegationModel {
  final String id;
  final String delegatorId;
  final String delegateId;
  final UserModel? delegator;
  final UserModel? delegate;
  final String startDate;
  final String endDate;
  final bool isActive;
  final String? createdAt;

  DelegationModel({
    required this.id,
    required this.delegatorId,
    required this.delegateId,
    this.delegator,
    this.delegate,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.createdAt,
  });

  factory DelegationModel.fromJson(Map<String, dynamic> json) {
    return DelegationModel(
      id: json['id'] ?? '',
      delegatorId: json['delegator_id'] ?? json['delegatorId'] ?? '',
      delegateId: json['delegate_id'] ?? json['delegateId'] ?? '',
      delegator: json['delegator'] != null && json['delegator'] is Map<String, dynamic>
          ? UserModel.fromJson(json['delegator'])
          : null,
      delegate: json['delegate'] != null && json['delegate'] is Map<String, dynamic>
          ? UserModel.fromJson(json['delegate'])
          : null,
      startDate: json['start_date'] ?? json['startDate'] ?? '',
      endDate: json['end_date'] ?? json['endDate'] ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delegator_id': delegatorId,
      'delegate_id': delegateId,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
    };
  }
}
