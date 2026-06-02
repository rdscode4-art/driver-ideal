import '../services/api_service.dart';
import '../data/models/recent_feedback_model.dart';

class RecentFeedbackApiService {
  static final ApiService _apiService = ApiService();

  // Get recent feedback for driver
  static Future<ApiResponse> getRecentFeedback() async {
    try {
      return await _apiService.get('/rides/driver/recent-feedback');
    } catch (e) {
      return ApiResponse.error('Failed to get recent feedback: ${e.toString()}');
    }
  }

  // Parse recent feedback response
  static RecentFeedbackResponse? parseRecentFeedback(Map<String, dynamic> data) {
    try {
      return RecentFeedbackResponse.fromJson(data);
    } catch (e) {
      print('Error parsing recent feedback: $e');
      return null;
    }
  }
}
