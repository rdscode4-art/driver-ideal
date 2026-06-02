import '../services/api_service.dart';
import '../data/models/driver_rating_model.dart';
import '../core/storage_helper.dart';

class RatingApiService {
  static final ApiService _apiService = ApiService();

  // Get driver rating
  static Future<ApiResponse> getDriverRating({String? driverId}) async {
    try {
      // If no driverId provided, get from storage
      final id = driverId ?? await StorageHelper.getDriverId();
      if (id == null) {
        return ApiResponse.error('Driver ID not found');
      }

      return await _apiService.get('/rides/drivers/$id/rating');
    } catch (e) {
      return ApiResponse.error('Failed to get driver rating: ${e.toString()}');
    }
  }

  // // Submit feedback
  static Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> feedbackData) async {
    try {
      final driverId = await StorageHelper.getDriverId();
      if (driverId == null) {
        return {'success': false, 'message': 'Driver ID not found'};
      }

      // Create the request body by combining feedbackData with additional fields
      final requestBody = Map<String, dynamic>.from(feedbackData);
      requestBody['driverId'] = driverId;
      requestBody['timestamp'] = DateTime.now().toIso8601String();

      final response = await _apiService.post('/feedback/submit', body: requestBody);

      if (response.isSuccess) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': response.message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit feedback: ${e.toString()}'};
    }
  }

  // Get previous feedback
  static Future<Map<String, dynamic>> getPreviousFeedback() async {
    try {
      final driverId = await StorageHelper.getDriverId();
      if (driverId == null) {
        return {'success': false, 'message': 'Driver ID not found'};
      }

      final response = await _apiService.get('/feedback/driver/$driverId');

      if (response.isSuccess) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': response.message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to get previous feedback: ${e.toString()}'};
    }
  }

  // Parse rating response
  static DriverRating? parseDriverRating(Map<String, dynamic> data) {
    try {
      return DriverRating.fromJson(data);
    } catch (e) {
      print('Error parsing driver rating: $e');
      return null;
    }
  }
}
