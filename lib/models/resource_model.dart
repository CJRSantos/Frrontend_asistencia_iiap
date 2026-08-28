class ResourceModel {
  final String id;
  final String name;
  final String? type;
  final String status;
  final String? description;
  final String? createdAt;

  ResourceModel({
    required this.id,
    required this.name,
    this.type,
    required this.status,
    this.description,
    this.createdAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'],
      status: json['status'] ?? 'AVAILABLE',
      description: json['description'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'description': description,
      'created_at': createdAt,
    };
  }
}
