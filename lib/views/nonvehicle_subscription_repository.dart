import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rideal_driver/core/token_manager.dart';

class NonVehicleSubscriptionRepository {
  static const String baseUrl = 'https://backend.ridealmobility.com';
  Future<Map<String, String>> _getHeaders() async {
    final token = TokenManager.instance.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all subscription plans
  Future<Map<String, dynamic>> getAllPlans() async {
    try {
      final token = TokenManager.instance.token;

      final response = await http.get(
        Uri.parse('$baseUrl/api/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch plans: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error fetching plans: $e'};
    }
  }

  // Get subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus(String driverId) async {
    try {
      // ✅ CORRECT ENDPOINT - Matches your Postman request
      final url = '$baseUrl/api/non-vehicle-driver/status/$driverId';
      print('📡 API Call: GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Handle 404 as "no subscription found"
      if (response.statusCode == 404) {
        print('ℹ️ 404 - No subscription found');
        return {
          'success': true,
          'data': {
            'status': 'not_subscribed',
            'hasSubscription': false,
            'subscribed': false,
          },
        };
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Subscription data received: $data');

        // Transform the response to match what controller expects
        // Backend returns: {"subscribed": true, "plan": {...}, "startDate": "...", ...}
        if (data is Map) {
          // Check if subscribed field exists
          final isSubscribed = data['subscribed'] == true;

          return {
            'success': true,
            'data': {
              'status': isSubscribed ? 'active' : 'not_subscribed',
              'hasSubscription': isSubscribed,
              'subscribed': isSubscribed,
              'plan_id': data['plan']?['_id'],
              'planId': data['plan']?['_id'],
              'plan_name': data['plan']?['title'] ?? 'Premium Plan',
              'planName': data['plan']?['title'] ?? 'Premium Plan',
              'start_date': data['startDate'],
              'startDate': data['startDate'],
              'expiry_date': data['endDate'],
              'expiryDate': data['endDate'],
              'rate': data['plan']?['rate'],
              'durationInMonths': data['plan']?['durationInMonths'],
            },
          };
        }

        return {'success': true, 'data': data};
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message':
              'Failed to fetch subscription status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error fetching subscription status: $e');
      return {
        'success': false,
        'message': 'Error fetching subscription status: $e',
      };
    }
  }

  // Buy subscription (initiate payment) - Updated to match API
  Future<Map<String, dynamic>> buySubscription({
    required String driverId,
    required String planId,
    String? planType,
    int? amount,
  }) async {
    try {
      final url = '$baseUrl/buy-subscription';
      print('📡 API Call: POST $url');

      final requestBody = {
        'driverId': driverId,
        'planType': planType ?? 'Pookie plan',
        'amount': amount ?? 100,
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: json.encode(requestBody),
      );
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Extract order details from response
        return {
          'success': true,
          'data': {
            'orderId': data['orderId'],
            'order_id': data['orderId'],
            'amount': data['amount'] ?? 100,
            'currency': data['currency'] ?? 'INR',
          },
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to initiate payment',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error initiating payment: $e'};
    }
  }

  // Verify payment - Updated to match API
  Future<Map<String, dynamic>> verifyPayment({
    required String driverId,
    required String planId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      final url = '$baseUrl/verify-subscription-payment';
      print('📡 API Call: POST $url');

      final requestBody = {
        'driverId': driverId,
        'planId': planId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Payment verification failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error verifying payment: $e'};
    }
  }
}
