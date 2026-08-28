class BirthdayModel {
  final String id;
  final String fullName;
  final String? position;
  final String? department;
  final String? photoUrl;
  final String? dateOfBirth;

  BirthdayModel({
    required this.id,
    required this.fullName,
    this.position,
    this.department,
    this.photoUrl,
    this.dateOfBirth,
  });

  factory BirthdayModel.fromJson(Map<String, dynamic> json) {
    return BirthdayModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? 'Investigador',
      position: json['position'] as String?,
      department: json['department'] as String?,
      photoUrl: json['photo_url'] as String?,
      dateOfBirth: json['date_of_birth'] as String? ?? json['dateOfBirth'] as String?,
    );
  }
}
