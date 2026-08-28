class EventModel {
  final String id;
  final String title;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String? location;
  final String? createdAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.location,
    this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      startDate: json['start_date'] ?? json['startDate'],
      endDate: json['end_date'] ?? json['endDate'],
      location: json['location'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'location': location,
      'created_at': createdAt,
    };
  }
}
