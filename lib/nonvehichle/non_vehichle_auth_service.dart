import 'package:http/http.dart' as http;
import 'dart:convert';

class NonVehicleAuthService {
  static const String baseUrl =
      'https://backend.ridealmobility.com/api/nonvehicle';

  // Fetch ride requests
  static Future<Map<String, dynamic>> fetchRideRequests(
    String authToken,
  ) async {
    try {
      final url = '$baseUrl/ride/requests';
      print(
        '📡 [cURL] curl -X GET "$url" -H "Authorization: Bearer $authToken" -H "Content-Type: application/json"',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 [HISTORY API] Status: ${response.statusCode}');
      print('📥 [HISTORY API] Body: ${response.body}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else if (response.statusCode == 403) {
        final body = json.decode(response.body);
        return {
          'success': false,
          'hasActiveRide': true,
          'activeRideId': body['activeRideId']?.toString() ?? '',
          'status': body['status']?.toString() ?? 'accepted',
          'message': body['message'] ?? 'You have an active ride.',
        };
      } else if (response.statusCode == 404) {
        // No ride requests is a valid state, not an error
        return {
          'success': true,
          'data': {'requests': []},
        };
      } else {
        return {
          'success': false,
          'hasActiveRide': false,
          'message':
              'No ride requests available (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error in fetchRideRequests: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Accept ride request
  static Future<Map<String, dynamic>> acceptRide(
    String authToken,
    String requestId,
  ) async {
    try {
      print('📡 [POST] $baseUrl/ride/accept/$requestId');

      final response = await http.post(
        Uri.parse('$baseUrl/ride/accept/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to accept ride',
        };
      }
    } catch (e) {
      print('❌ Error in acceptRide: $e');
      return {'success': false, 'message': 'Error accepting ride: $e'};
    }
  }

  // Start ride with OTP verification
  static Future<Map<String, dynamic>> startRide(
    String authToken,
    String requestId,
    String otp,
  ) async {
    try {
      print('📡 [POST] $baseUrl/ride/$requestId/start');
      print('📦 Payload: {"otp": "$otp"}');

      final response = await http.post(
        Uri.parse('$baseUrl/ride/$requestId/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'otp': otp}),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to start ride',
        };
      }
    } catch (e) {
      print('❌ Error in startRide: $e');
      return {'success': false, 'message': 'Error starting ride: $e'};
    }
  }

  // Reject ride request
  static Future<Map<String, dynamic>> rejectRide(
    String authToken,
    String requestId,
    {String? cancelReason}
  ) async {
    try {
      print('🚀 [POST] $baseUrl/ride/reject/$requestId');
      
      final body = cancelReason != null ? json.encode({'cancelReason': cancelReason}) : null;

      final response = await http.post(
        Uri.parse('$baseUrl/ride/reject/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: body,
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Ride declined successfully',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to decline ride',
        };
      }
    } catch (e) {
      print('❌ Error in rejectRide: $e');
      return {'success': false, 'message': 'Error declining ride: $e'};
    }
  }

  static Future<Map<String, dynamic>> completeRide(
    String authToken,
    String requestId,
    String paymentMethod,
    String completionOtp,
  ) async {
    try {
      // Beautifully formatted copy-pasteable cURL command for debugging
      print(
        '📡 [cURL] curl --location \'$baseUrl/ride/$requestId/complete\' \\\n'
        '--header \'Content-Type: application/json\' \\\n'
        '--header \'Authorization: Bearer $authToken\' \\\n'
        '--data \'{\n'
        '    "paymentMethod": "$paymentMethod",\n'
        '    "completionOtp": "$completionOtp"\n'
        '  }\'',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/ride/$requestId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'paymentMethod': paymentMethod,
          'completionOtp': completionOtp,
        }),
      );

      print('📥 [API RESPONSE] Status: ${response.statusCode}');
      print('📥 [API RESPONSE] Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to complete ride',
        };
      }
    } catch (e) {
      print('❌ Error in completeRide: $e');
      return {'success': false, 'message': 'Error completing ride: $e'};
    }
  }

  // Get trip history
  static Future<Map<String, dynamic>> getTripHistory(String authToken) async {
    try {
      print('📡 [GET] $baseUrl/ride/history');
      final response = await http.get(
        Uri.parse('$baseUrl/ride/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else if (response.statusCode == 404) {
        // No trip history is a valid state
        return {
          'success': true,
          'data': {'rides': []},
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch trip history (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error in getTripHistory: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update driver availability status
  static Future<Map<String, dynamic>> updateDriverAvailability(
    String authToken,
    bool isAvailable, {
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('https://backend.ridealmobility.com/driver-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'isAvailable': isAvailable,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to update availability'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get single ride status
  static Future<Map<String, dynamic>> getRideStatus(
    String authToken,
    String requestId,
  ) async {
    try {
      print('📡 [GET] $baseUrl/ride/$requestId/status');

      final response = await http.get(
        Uri.parse('$baseUrl/ride/$requestId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch ride status (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error in getRideStatus: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
