import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';
import '../core/utils/app_snackbar.dart';

/// 🚀 COMPLETE RAZORPAY FIX SERVICE
///
/// This service FIXES the "Uh oh! Something went wrong" error
///
/// 🔧 CRITICAL SETUP:
/// 1. Replace _keySecret with your actual Razorpay test secret
/// 2. Get it from: Razorpay Dashboard → Settings → API Keys → Test Key Secret
/// 3. Test with ₹1 payment first
///
/// 🧪 TESTING:
/// - Call testRazorpaySetup() to verify your setup
/// - Use test card: 4111 1111 1111 1111, CVV: 123, Expiry: any future date
class WorkingRazorpayService {
  // 🚨 REPLACE WITH YOUR ACTUAL CREDENTIALS
  static const String keyId = ' rzp_live_RoLpvsh1Qs9Cfs';
  static const String keySecret =
      'YOUR_ACTUAL_TEST_SECRET_HERE'; // ⚠️ MUST REPLACE

  late Razorpay _razorpay;

  // Payment callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  WorkingRazorpayService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    log('🚀 Razorpay initialized');

    // Validate setup
    if (keySecret.contains('YOUR_ACTUAL_TEST_SECRET_HERE')) {
      showWarningSnackBar(
        'Add your actual Razorpay secret key in WorkingRazorpayService',
        title: '⚠️ Setup Required',
      );
    }
  }

  /// 🎯 Create Razorpay order (Direct API method)
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String receipt,
  }) async {
    try {
      // Validate secret is set
      if (keySecret.contains('YOUR_ACTUAL_TEST_SECRET_HERE')) {
        return {
          'success': false,
          'error':
              'Razorpay secret key not configured. Please add your actual secret.',
        };
      }

      log('📡 Creating Razorpay order for ₹$amount');

      // Convert to paise
      final amountInPaise = (amount * 100).round();

      // Validate minimum amount
      if (amountInPaise < 100) {
        throw Exception('Minimum amount is ₹1');
      }

      final requestBody = {
        'amount': amountInPaise,
        'currency': 'INR',
        'receipt': receipt,
        'payment_capture': 1,
      };

      // Create Basic Auth
      final auth = base64Encode(utf8.encode('$keyId:$keySecret'));

      final response = await http
          .post(
            Uri.parse('https://api.razorpay.com/v1/orders'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic $auth',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: 30));

      log('📥 Razorpay Response: ${response.statusCode}');
      log('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('✅ Order created: ${data['id']}');

        return {
          'success': true,
          'order_id': data['id'],
          'amount': data['amount'],
          'currency': data['currency'],
        };
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('Bad request: ${error['error']['description']}');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Check your key and secret.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Razorpay Error: ${error['error']['description']}');
      }
    } catch (e) {
      log('❌ Order creation failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🎯 Open payment gateway
  Future<bool> openPayment({
    required String orderId,
    required double amount,
    required String customerName,
    String? email,
    String? phone,
  }) async {
    try {
      // Validate order ID format
      if (!orderId.startsWith('order_')) {
        showErrorSnackBar(
          'Order ID format is invalid: $orderId',
          title: '❌ Invalid Order',
        );
        return false;
      }

      final amountInPaise = (amount * 100).round();

      var options = {
        'key': keyId,
        'order_id': orderId,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'RiDeal Driver',
        'description': 'Subscription Payment',
        'timeout': 300, // 5 minutes
        'retry': {'enabled': true, 'max_count': 3},
        'prefill': {
          'name': customerName,
          if (email != null) 'email': email,
          if (phone != null) 'contact': phone,
        },
      };

      log('📋 Opening payment with:');
      log('  Order: $orderId');
      log('  Amount: ₹$amount ($amountInPaise paise)');
      log('  Key: ${keyId.substring(0, 12)}...');

      _razorpay.open(options);
      return true;
    } catch (e) {
      log('❌ Failed to open payment: $e');
      showErrorSnackBar(
        'Failed to open payment: $e',
        title: '❌ Payment Error',
      );
      return false;
    }
  }

  /// 🎯 Complete subscription payment flow
  Future<void> processSubscriptionPayment({
    required double amount,
    required String customerName,
    required String driverId,
    required String planId,
    String? email,
    String? phone,
    required Function(Map<String, dynamic>) onPaymentSuccess,
    required Function(String) onPaymentError,
  }) async {
    try {
      // Show loading
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating payment order...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Create order
      final orderResult = await createRazorpayOrder(
        amount: amount,
        receipt: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Close loading
      Get.back();

      if (!orderResult['success']) {
        onPaymentError('Order creation failed: ${orderResult['error']}');
        return;
      }

      final orderId = orderResult['order_id'];

      // Set success callback
      onSuccess = (PaymentSuccessResponse response) async {
        log('🎉 Payment successful!');
        log('💳 Payment ID: ${response.paymentId}');

        // Show verification loading
        Get.dialog(
          AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verifying payment...'),
              ],
            ),
          ),
          barrierDismissible: false,
        );

        // Verify with backend
        final verification = await _verifyWithBackend(
          paymentId: response.paymentId!,
          orderId: response.orderId!,
          signature: response.signature!,
          driverId: driverId,
          planId: planId,
        );

        // Close verification dialog
        Get.back();

        if (verification['success']) {
          onPaymentSuccess(verification);
        } else {
          onPaymentError(
            'Payment verification failed: ${verification['error']}',
          );
        }
      };

      // Set failure callback
      onFailure = (PaymentFailureResponse response) {
        String error = _getUserFriendlyError(response);
        log('❌ Payment failed: $error');
        onPaymentError(error);
      };

      // Open payment
      final opened = await openPayment(
        orderId: orderId,
        amount: amount,
        customerName: customerName,
        email: email,
        phone: phone,
      );

      if (!opened) {
        onPaymentError('Failed to open payment gateway');
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log('❌ Payment process error: $e');
      onPaymentError('Payment process failed: $e');
    }
  }

  /// Verify payment with backend
  Future<Map<String, dynamic>> _verifyWithBackend({
    required String paymentId,
    required String orderId,
    required String signature,
    required String driverId,
    required String planId,
  }) async {
    try {
      final token = await StorageHelper.getAuthToken();

      final response = await http
          .post(
            Uri.parse(
              'https://backend.ridealmobility.com/verify-subscription-payment',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'driverId': driverId,
              'planId': planId,
              'razorpay_payment_id': paymentId,
              'razorpay_order_id': orderId,
              'razorpay_signature': signature,
            }),
          )
          .timeout(Duration(seconds: 30));

      log('📥 Verification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Payment verified successfully',
            'data': data['data'],
          };
        } else {
          throw Exception(data['message'] ?? 'Verification failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Verification error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user-friendly error message
  String _getUserFriendlyError(PaymentFailureResponse response) {
    switch (response.code) {
      case 0:
        return 'Payment cancelled by user';
      case 1:
        return 'Network error. Please check your internet connection';
      case 2:
        return 'Payment failed. Please try a different payment method';
      default:
        return response.message ?? 'Payment failed. Please try again';
    }
  }

  /// Event handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call(response);
  }

  /// 🧪 Test your Razorpay setup
  Future<void> testSetup() async {
    try {
      log('🧪 Testing Razorpay setup...');

      showInfoSnackBar(
        'Creating test order...',
        title: '🧪 Testing Setup',
      );

      final testOrder = await createRazorpayOrder(
        amount: 1.0, // ₹1 test
        receipt: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (testOrder['success']) {
        log('✅ Test order created: ${testOrder['order_id']}');

        showSuccessSnackBar(
          'Test order created successfully. Your Razorpay setup is correct!',
          title: '✅ Setup Working!',
        );
      } else {
        log('❌ Test failed: ${testOrder['error']}');

        showErrorSnackBar(
          'Error: ${testOrder['error']}',
          title: '❌ Setup Failed',
        );
      }
    } catch (e) {
      log('❌ Test error: $e');

      showErrorSnackBar(
        'Setup test failed: $e',
        title: '❌ Test Error',
      );
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}

/// 🧪 Quick test function - Call this to test your setup
void testRazorpaySetup() {
  final service = WorkingRazorpayService();
  service.testSetup();
}
