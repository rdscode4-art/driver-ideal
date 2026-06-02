import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';

/// Production-ready RiDeal Subscription Service
/// Handles all subscription-related API calls to backend.ridealmobility.com
class RidealSubscriptionService {
  static const String baseUrl = 'https://backend.ridealmobility.com';
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Get authorization headers with Bearer token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Log API request for debugging
  static void _logRequest(
    String method,
    String url, [
    Map<String, dynamic>? body,
  ]) {
    print('🌐 [$method] $url');
    if (body != null) {
      print('📤 Body: ${jsonEncode(body)}');
    }
  }

  /// Log API response for debugging
  static void _logResponse(int statusCode, String body) {
    print('📥 Response [$statusCode]: $body');
  }

  /// 1️⃣ CREATE RAZORPAY ORDER (Buy Subscription)
  /// POST /api/non-vehicle-driver/buy-subscription
  static Future<Map<String, dynamic>> createOrder({
    required String driverId,
    required String planId,
    required int amount,
  }) async {
    const endpoint = '$baseUrl/api/non-vehicle-driver/buy-subscription';

    final requestBody = {
      'driverId': driverId,
      'planId': planId,
      'amount': amount,
    };

    _logRequest('POST', endpoint, requestBody);

    try {
      final headers = await _getHeaders();

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(timeoutDuration);

      _logResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Expected response: { "orderId": "...", "amount": 100, "currency": "INR" }
        if (data['orderId'] != null) {
          print('✅ Order created successfully: ${data['orderId']}');
          return {'success': true, 'data': data};
        } else {
          throw Exception('Invalid response: orderId not found');
        }
      } else if (response.statusCode == 401) {
        print('🔐 Authentication failed - clearing token');
        await StorageHelper.clearAuthToken();
        return {
          'success': false,
          'needsAuth': true,
          'message': 'Authentication failed. Please login again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Failed to create order';
        print('❌ Create order failed: $message');
        return {'success': false, 'message': message};
      }
    } on SocketException {
      print('❌ No internet connection');
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on HttpException catch (e) {
      print('❌ HTTP error: $e');
      return {
        'success': false,
        'message': 'Server error. Please try again later.',
      };
    } catch (e) {
      print('❌ Error creating order: $e');
      return {'success': false, 'message': 'Failed to create order: $e'};
    }
  }

  /// 2️⃣ VERIFY RAZORPAY PAYMENT
  /// POST /api/non-vehicle-driver/verify-payment
  static Future<Map<String, dynamic>> verifyPayment({
    required String driverId,
    required String planId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    const endpoint = '$baseUrl/api/non-vehicle-driver/verify-payment';

    final requestBody = {
      'driverId': driverId,
      'planId': planId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
    };

    _logRequest('POST', endpoint, requestBody);

    try {
      final headers = await _getHeaders();

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(timeoutDuration);

      _logResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Expected response: { "success": true, "message": "...", "subscription": {...} }
        if (data['success'] == true) {
          print('✅ Payment verified successfully');
          return {
            'success': true,
            'data': data,
            'message': data['message'] ?? 'Subscription activated successfully',
          };
        } else {
          final message = data['message'] ?? 'Payment verification failed';
          print('❌ Payment verification failed: $message');
          return {'success': false, 'message': message};
        }
      } else if (response.statusCode == 401) {
        print('🔐 Authentication failed - clearing token');
        await StorageHelper.clearAuthToken();
        return {
          'success': false,
          'needsAuth': true,
          'message': 'Authentication failed. Please login again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Payment verification failed';
        print('❌ Verify payment failed: $message');
        return {'success': false, 'message': message};
      }
    } on SocketException {
      print('❌ No internet connection');
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on HttpException catch (e) {
      print('❌ HTTP error: $e');
      return {
        'success': false,
        'message': 'Server error. Please try again later.',
      };
    } catch (e) {
      print('❌ Error verifying payment: $e');
      return {'success': false, 'message': 'Failed to verify payment: $e'};
    }
  }

  /// 3️⃣ GET SUBSCRIPTION STATUS
  /// GET /api/non-vehicle-driver/status/DRIVER_ID
  static Future<Map<String, dynamic>> getSubscriptionStatus(
    String driverId,
  ) async {
    final endpoint = '$baseUrl/api/non-vehicle-driver/status/$driverId';

    _logRequest('GET', endpoint);

    try {
      final headers = await _getHeaders();

      final response = await http
          .get(Uri.parse(endpoint), headers: headers)
          .timeout(timeoutDuration);

      _logResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /* Expected response:
        {
          "subscribed": true,
          "plan": {
            "_id": "...",
            "title": "...",
            "durationInMonths": 3,
            "rate": 100
          },
          "startDate": "...",
          "endDate": "..."
        }
        */

        print('✅ Subscription status loaded successfully');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        print('ℹ️ No subscription found for driver');
        return {
          'success': true,
          'data': {'subscribed': false},
          'message': 'No active subscription found',
        };
      } else if (response.statusCode == 401) {
        print('🔐 Authentication failed - clearing token');
        await StorageHelper.clearAuthToken();
        return {
          'success': false,
          'needsAuth': true,
          'message': 'Authentication failed. Please login again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        final message =
            errorData['message'] ?? 'Failed to get subscription status';
        print('❌ Get subscription status failed: $message');
        return {'success': false, 'message': message};
      }
    } on SocketException {
      print('❌ No internet connection');
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on HttpException catch (e) {
      print('❌ HTTP error: $e');
      return {
        'success': false,
        'message': 'Server error. Please try again later.',
      };
    } catch (e) {
      print('❌ Error getting subscription status: $e');
      return {
        'success': false,
        'message': 'Failed to get subscription status: $e',
      };
    }
  }

  /// 4️⃣ GET SUBSCRIPTION PLANS
  /// GET /api/
  static Future<Map<String, dynamic>> getSubscriptionPlans() async {
    final endpoint = '$baseUrl/api/';

    _logRequest('GET', endpoint);

    try {
      final headers = await _getHeaders();

      final response = await http
          .get(Uri.parse(endpoint), headers: headers)
          .timeout(timeoutDuration);

      _logResponse(response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('✅ Subscription plans loaded successfully');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        print('🔐 Authentication failed - clearing token');
        await StorageHelper.clearAuthToken();
        return {
          'success': false,
          'needsAuth': true,
          'message': 'Authentication failed. Please login again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        final message =
            errorData['message'] ?? 'Failed to get subscription plans';
        print('❌ Get subscription plans failed: $message');
        return {'success': false, 'message': message};
      }
    } on SocketException {
      print('❌ No internet connection');
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on HttpException catch (e) {
      print('❌ HTTP error: $e');
      return {
        'success': false,
        'message': 'Server error. Please try again later.',
      };
    } catch (e) {
      print('❌ Error getting subscription plans: $e');
      return {
        'success': false,
        'message': 'Failed to get subscription plans: $e',
      };
    }
  }

  /// Retry mechanism for failed requests
  static Future<Map<String, dynamic>> _retryRequest(
    Future<Map<String, dynamic>> Function() requestFunction, {
    int maxRetries = 2,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        final result = await requestFunction();

        // If successful or authentication error, don't retry
        if (result['success'] == true || result['needsAuth'] == true) {
          return result;
        }

        // If network error and not last attempt, retry
        if (attempts < maxRetries) {
          print('🔄 Retrying request (attempt ${attempts + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 2 * (attempts + 1)));
          attempts++;
          continue;
        }

        return result;
      } catch (e) {
        if (attempts >= maxRetries) {
          return {
            'success': false,
            'message': 'Network error after $maxRetries attempts',
          };
        }
        attempts++;
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }

    return {
      'success': false,
      'message': 'Request failed after multiple attempts',
    };
  }
}
