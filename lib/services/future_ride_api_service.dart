import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/future_ride_models.dart';
import '../../core/storage_helper.dart';

class FutureRideApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com/api';

  static Future<Map<String, dynamic>> createFutureRide(FutureRideRequest request) async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/future-rides/driver/post'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('Future Ride API Response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final futureRideResponse = FutureRideResponse.fromJson(responseData);

        return {
          'success': true,
          'message': futureRideResponse.message,
          'ride': futureRideResponse.ride,
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create future ride',
        };
      }
    } catch (e) {
      print('Error creating future ride: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection and try again.',
      };
    }
  }

  /// Fetch driver's future ride requests
  static Future<Map<String, dynamic>> getDriverRideRequests() async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      print('🔄 Fetching driver ride requests from API...');

      final response = await http.get(
        Uri.parse('$baseUrl/future-rides/driver/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Driver Ride Requests API Response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Parse the rides array
        final List<dynamic> ridesData = responseData['rides'] ?? [];
        final List<FutureRideWithRequests> rides = ridesData
            .map((rideJson) => FutureRideWithRequests.fromJson(rideJson))
            .toList();

        print('✅ Successfully fetched ${rides.length} ride requests');

        return {
          'success': true,
          'rides': rides,
          'message': 'Ride requests fetched successfully',
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch ride requests',
        };
      }
    } catch (e) {
      print('❌ Error fetching ride requests: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection and try again.',
      };
    }
  }

  /// Respond to a passenger booking request (accept or reject)
  static Future<Map<String, dynamic>> respondToBooking({
    required String rideId,
    required String bookingId,
    required String action, // "accepted" or "rejected"
  }) async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      print('🔄 Responding to booking: $action for ride $rideId, booking $bookingId');

      final response = await http.post(
        Uri.parse('$baseUrl/future-rides/driver/respond/$rideId/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': action,
        }),
      );

      print('Respond to Booking API Response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message': responseData['msg'] ?? 'Booking $action successfully',
          'booking': responseData['booking'],
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to $action booking',
        };
      }
    } catch (e) {
      print('❌ Error responding to booking: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection and try again.',
      };
    }
  }
}
