class CourseModel {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? createdAt;

  CourseModel({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      category: json['category'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'created_at': createdAt,
    };
  }
}
