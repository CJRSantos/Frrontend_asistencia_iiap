class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? documentNumber;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? photoUrl;
  final String? position;
  final String? department;
  final String role;
  final bool isVerified;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.documentNumber,
    this.phoneNumber,
    this.dateOfBirth,
    this.photoUrl,
    this.position,
    this.department,
    required this.role,
    this.isVerified = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      documentNumber: json['document_number'] as String?,
      phoneNumber: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      photoUrl: json['photo_url'] as String?,
      position: json['position'] as String?,
      department: json['department'] as String?,
      role: json['role'] as String? ?? 'EMPLOYEE',
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'document_number': documentNumber,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'photo_url': photoUrl,
      'position': position,
      'department': department,
      'role': role,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
