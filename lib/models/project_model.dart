class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final String status; // ACTIVE, COMPLETED, ON_HOLD
  final String? createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'created_at': createdAt,
    };
  }
}
