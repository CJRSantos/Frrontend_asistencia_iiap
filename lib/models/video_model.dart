class VideoModel {
  final String id;
  final String title;
  final String? url;
  final String? thumbnail;
  final String? description;
  final String? courseId;
  final String? createdAt;

  VideoModel({
    required this.id,
    required this.title,
    this.url,
    this.thumbnail,
    this.description,
    this.courseId,
    this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      url: json['url'] ?? json['link'] ?? json['video_url'],
      thumbnail: json['thumbnail'],
      description: json['description'],
      courseId: json['course_id'] ?? json['courseId'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'url': url,
      'link': url,
      'thumbnail': thumbnail,
      'description': description,
      'course_id': courseId,
      'created_at': createdAt,
    };
  }
}
