import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rideal_driver/data/models/ride_history_models.dart';
import '../core/storage_helper.dart';

class RideHistoryService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  Future<RideHistoryResponse> getRideHistory() async {
    try {
      final token = await StorageHelper.getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/driver-ride-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RideHistoryResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        // If 404 is returned when no rides exist, treat it as an empty list
        return RideHistoryResponse(
          totalRides: 0,
          rideCounts: {},
          rides: [],
        );
      } else {
        // Try to parse error message from body if available
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message']?.toString().toLowerCase() ?? '';
          if (message.contains('no ride') || message.contains('empty')) {
            return RideHistoryResponse(
              totalRides: 0,
              rideCounts: {},
              rides: [],
            );
          }
        } catch (_) {}
        
        throw Exception('Failed to load ride history (${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('no ride') || 
          e.toString().toLowerCase().contains('404')) {
         return RideHistoryResponse(
          totalRides: 0,
          rideCounts: {},
          rides: [],
        );
      }
      throw Exception('Error fetching ride history: $e');
    }
  }
}
