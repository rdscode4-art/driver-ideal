import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test API Integration for Payment Gateway
class APIIntegrationTest {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  /// Test buy subscription API
  static Future<void> testBuySubscription() async {
    try {
      print('🧪 Testing Buy Subscription API...');

      final response = await http.post(
        Uri.parse('$baseUrl/buy-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "driverId": "68df63a3085a93405fed4fe6",
          "planType": "Pookie plan",
          "amount": 100,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Buy Subscription API working!');
        print('🆔 Order ID: ${data['orderId']}');
        print('💰 Amount: ${data['amount']}');
      } else {
        print('❌ Buy Subscription API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error testing Buy Subscription API: $e');
    }
  }

  /// Test verify payment API
  static Future<void> testVerifyPayment() async {
    try {
      print('🧪 Testing Verify Payment API...');

      final response = await http.post(
        Uri.parse('$baseUrl/verify-subscription-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "driverId": "68df63a3085a93405fed4fe6",
          "planId": "68ede14b0efa19665b81303e",
          "razorpay_payment_id": "pay_PxQbA1K2Qv1234",
          "razorpay_order_id": "order_RoKE9UrbjdZ6Y5",
          "razorpay_signature": "b0d1ff44eaa4a67c3fc02459a123456789abcdfe",
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Verify Payment API working!');
      } else {
        print('❌ Verify Payment API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error testing Verify Payment API: $e');
    }
  }

  /// Run all API tests
  static Future<void> runAllTests() async {
    print('🚀 Starting API Integration Tests...');
    print('=' * 50);

    await testBuySubscription();
    print('-' * 30);

    await testVerifyPayment();
    print('=' * 50);
    print('🏁 API Tests Completed');
  }
}
