import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';
import '../models/subscription_status_model.dart';

class SubscriptionService {
  static const String baseUrl = 'https://backend.ridealmobility.com';
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Get headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Log API request details - for debugging purposes
  // static void _logRequest(String method, String url, Map<String, dynamic>? body) {
  //   print('🔍 API Request: $method $url');
  //   if (body != null) {
  //     print('📤 Request Body: ${json.encode(body)}');
  //   }
  // }

  /// Fetch subscription status for a driver
  Future<SubscriptionStatusModel?> fetchSubscriptionStatus(
    String driverId,
  ) async {
    try {
      print('📡 API Call: GET $baseUrl/subscription-status?driverId=$driverId');

      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/subscription-status?driverId=$driverId'),
            headers: headers,
          )
          .timeout(timeoutDuration);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final subscriptionData = responseData['data'];
          print('✅ Subscription data found: $subscriptionData');

          return SubscriptionStatusModel.fromJson(subscriptionData);
        } else {
          print('❌ API returned success=false or no data');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ 404 - No subscription found for driver');
        return null;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');

        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'HTTP ${response.statusCode}',
          );
        } catch (e) {
          throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      }
    } on TimeoutException {
      print('❌ Request timeout after $timeoutDuration');
      throw Exception(
        'Request timeout. Please check your internet connection.',
      );
    } on FormatException catch (e) {
      print('❌ Invalid JSON response: $e');
      throw Exception('Invalid response format from server.');
    } catch (e) {
      print('❌ Error fetching subscription status: $e');
      rethrow;
    }
  }
}
