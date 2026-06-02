import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';

class SubscriptionApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com';
  static const int timeoutSeconds = 30;

  /// Get headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Log API request details
  static void _logRequest(
    String method,
    String url,
    Map<String, dynamic>? body,
  ) {
    print('🔍 API Request: $method $url');
    if (body != null) {
      print('📤 Request Body: ${json.encode(body)}');
    }
  }

  /// Log API response details
  static void _logResponse(int statusCode, String body) {
    print('📥 Response Status: $statusCode');
    print('📥 Response Body: $body');
  }

  /// Handle API errors gracefully
  static Map<String, dynamic> _handleError(String operation, dynamic error) {
    print('🔴 Error in $operation: $error');
    return {'success': false, 'message': 'Network error: $error', 'data': null};
  }

  /// Get subscription status for driver
  static Future<Map<String, dynamic>> getSubscriptionStatus(
    String driverId,
  ) async {
    final url = '$baseUrl/api/non-vehicle-driver/status/$driverId';

    try {
      _logRequest('GET', url, null);

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Subscription status fetched successfully',
          'data': data,
        };
      } else if (response.statusCode == 404) {
        // No subscription found - this is normal for new users
        print('ℹ️ No subscription found for driver');
        return {
          'success': true,
          'message': 'No active subscription',
          'data': {'subscribed': false, 'status': 'not_subscribed'},
        };
      } else if (response.statusCode == 401) {
        print('🚫 Authentication failed - invalid token');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
          'needsAuth': true,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorData['message'] ?? 'Failed to fetch subscription status',
          'data': null,
        };
      }
    } catch (error) {
      return _handleError('getSubscriptionStatus', error);
    }
  }

  /// Create subscription order
  static Future<Map<String, dynamic>> createSubscriptionOrder({
    required String driverId,
    required String planId,
    required int amount,
  }) async {
    final url = '$baseUrl/api/non-vehicle-driver/buy-subscription';

    final requestBody = {
      'driverId': driverId,
      'planId': planId,
      'amount': amount,
    };

    try {
      _logRequest('POST', url, requestBody);
      print('💳 Creating Razorpay order for amount: ₹$amount');

      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(response.statusCode, response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Validate that we received an order ID
        if (data['orderId'] == null && data['order_id'] == null) {
          return {
            'success': false,
            'message': 'Order ID not received from server',
            'data': null,
          };
        }

        return {
          'success': true,
          'message': 'Order created successfully',
          'data': data,
        };
      } else if (response.statusCode == 401) {
        print('🚫 Authentication failed during order creation');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
          'needsAuth': true,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create order',
          'data': null,
        };
      }
    } catch (error) {
      return _handleError('createSubscriptionOrder', error);
    }
  }

  /// Verify payment with backend
  static Future<Map<String, dynamic>> verifyPayment({
    required String driverId,
    required String planId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final url = '$baseUrl/api/non-vehicle-driver/verify-payment';

    final requestBody = {
      'driverId': driverId,
      'planId': planId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    };

    try {
      _logRequest('POST', url, requestBody);
      print(
        '🔍 Verifying payment with signature: ${razorpaySignature.substring(0, 10)}...',
      );

      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Payment verified successfully',
          'data': data,
        };
      } else if (response.statusCode == 401) {
        print('🚫 Authentication failed during payment verification');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
          'needsAuth': true,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Payment verification failed',
          'data': null,
        };
      }
    } catch (error) {
      return _handleError('verifyPayment', error);
    }
  }
}
