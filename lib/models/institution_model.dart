class InstitutionModel {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? createdAt;

  InstitutionModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      city: json['city'],
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
    };
  }
}
