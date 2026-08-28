class AttendanceModel {
  final String id;
  final String userId;
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

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? json['created_at'] as String? ?? '',
      type: json['type'] as String? ?? 'CHECK_IN',
      status: json['status'] as String? ?? 'ON_TIME',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photo_url'] as String?,
      deviceId: json['device_id'] as String?,
      verificationMethod: json['verification_method'] as String?,
      observations: json['observations'] as String?,
      projectId: json['project_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
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
