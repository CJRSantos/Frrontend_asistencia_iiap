class InstitutionModel {
  final String id;
  final String? code;
  final String name;
  final String? address;
  final String? city;
  final bool? isActive;
  final double? latitude;
  final double? longitude;
  final String? createdAt;

  InstitutionModel({
    required this.id,
    this.code,
    required this.name,
    this.address,
    this.city,
    this.isActive,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] ?? '',
      code: json['code'],
      name: json['name'] ?? '',
      address: json['address'],
      city: json['city'],
      isActive: json['is_active'],
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'address': address,
      'city': city,
      'is_active': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
    };
  }
}
