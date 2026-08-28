import 'user_model.dart';

class ScheduleModel {
  final String id;
  final String userId;
  final UserModel? user;
  final int dayOfWeek; // 0=Domingo, 1=Lunes, ...
  final String startTime; // "08:00"
  final String endTime; // "17:00"

  ScheduleModel({
    required this.id,
    required this.userId,
    this.user,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : null,
      dayOfWeek: json['day_of_week'] is num ? (json['day_of_week'] as num).toInt() : 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  String get dayName {
    switch (dayOfWeek) {
      case 0:
        return 'Domingo';
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      default:
        return 'Día $dayOfWeek';
    }
  }
}
