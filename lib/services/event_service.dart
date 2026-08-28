import '../config/api_config.dart';
import '../models/event_model.dart';
import 'api_service.dart';

class EventService {
  static Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.events, body: data, requiresAuth: true);
    return EventModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<List<EventModel>> getAllEvents() async {
    final response = await ApiService.get(ApiConfig.events, requiresAuth: true);
    if (response is List) {
      return response.map((item) => EventModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<EventModel> getEventById(String id) async {
    final response = await ApiService.get(ApiConfig.eventById(id), requiresAuth: true);
    return EventModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<dynamic> updateEvent(String id, Map<String, dynamic> data) async {
    return await ApiService.patch(ApiConfig.eventById(id), body: data, requiresAuth: true);
  }

  static Future<dynamic> deleteEvent(String id) async {
    return await ApiService.delete(ApiConfig.eventById(id), requiresAuth: true);
  }
}
