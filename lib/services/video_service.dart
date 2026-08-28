import '../config/api_config.dart';
import '../models/video_model.dart';
import 'api_service.dart';

class VideoService {
  static Future<List<VideoModel>> getVideos() async {
    final response = await ApiService.get(ApiConfig.videos, requiresAuth: true);
    if (response is List) {
      return response.map((item) => VideoModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<dynamic> createVideo(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConfig.videos, body: data, requiresAuth: true);
  }
}
