import 'user_model.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final UserModel? user;
  final String timestamp;
  final String type; // CHECK_IN, CHECK_OUT, BREAK_START, BREAK_END
  final String status; // ON_TIME, LATE, EARLY_DEPARTURE, EXCUSED, PENDING_REVIEW
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String? deviceId;
  final String? verificationMethod;
  final String? observations;
  final String? projectId;
  final String? createdAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    this.user,
    required this.timestamp,
    required this.type,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.deviceId,
    this.verificationMethod,
    this.observations,
    this.projectId,
    this.createdAt,
  });

  String get userName => user?.fullName ?? (userId.isNotEmpty ? 'Usuario $userId' : 'Empleado');

  String get typeLabel {
    switch (type) {
      case 'CHECK_IN':
        return 'Ingreso';
      case 'CHECK_OUT':
        return 'Salida';
      case 'BREAK_START':
        return 'Inicio Refrigerio';
      case 'BREAK_END':
        return 'Fin Refrigerio';
      default:
        return type;
    }
  }

  String get formattedTime {
    if (timestamp.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return timestamp.length >= 16 ? timestamp.substring(11, 16) : timestamp;
    }
  }

  String get formattedDate {
    if (timestamp.isEmpty) return '---';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d/$m/$y';
    } catch (_) {
      return timestamp.length >= 10 ? timestamp.substring(0, 10) : timestamp;
    }
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic> ? UserModel.fromJson(json['user']) : null,
      timestamp: json['timestamp']?.toString() ?? json['created_at']?.toString() ?? '',
      type: json['type']?.toString() ?? 'CHECK_IN',
      status: json['status']?.toString() ?? 'ON_TIME',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      photoUrl: json['photo_url']?.toString() ?? json['photoUrl']?.toString(),
      deviceId: json['device_id']?.toString() ?? json['deviceId']?.toString(),
      verificationMethod: json['verification_method']?.toString() ?? json['verificationMethod']?.toString(),
      observations: json['observations']?.toString(),
      projectId: json['project_id']?.toString() ?? json['projectId']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (user != null) 'user': user!.toJson(),
      'timestamp': timestamp,
      'type': type,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'device_id': deviceId,
      'verification_method': verificationMethod,
      'observations': observations,
      'project_id': projectId,
      'created_at': createdAt,
    };
  }
}
