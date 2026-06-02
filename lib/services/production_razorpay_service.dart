import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../core/storage_helper.dart';

/// 🚀 PRODUCTION-READY RAZORPAY PAYMENT SERVICE
/// Fixes: "Uh oh! Something went wrong" errors
class ProductionRazorpayService {
  // 🔧 CRITICAL CONFIGURATION - MUST BE CORRECT
  static const String _testKeyId = ' rzp_live_RoLpvsh1Qs9Cfs';
  static const String _testKeySecret =
      'YOUR_ACTUAL_TEST_SECRET_HERE'; // ⚠️ REPLACE THIS

  static const String _liveKeyId =
      'rzp_live_RoLpvsh1Qs9Cfs'; // ⚠️ ADD FOR PRODUCTION
  static const String _liveKeySecret =
      'YOUR_ACTUAL_LIVE_SECRET_HERE'; // ⚠️ ADD FOR PRODUCTION

  // Environment control
  static const bool _isProduction = false; // Set to true for live payments

  // API URLs
  static const String _razorpayApiUrl = 'https://api.razorpay.com/v1/orders';
  static const String _backendUrl = 'https://backend.ridealmobility.com';

  late Razorpay _razorpay;
  String? _currentOrderId;
  bool _isInitialized = false;

  // Getters for current environment
  String get _keyId => _isProduction ? _liveKeyId : _testKeyId;
  String get _keySecret => _isProduction ? _liveKeySecret : _testKeySecret;
  String get _environment => _isProduction ? 'LIVE' : 'TEST';

  ProductionRazorpayService() {
    _validateAndInitialize();
  }

  // ✅ STEP 1: CRITICAL VALIDATION & INITIALIZATION
  void _validateAndInitialize() {
    log('🔧 Initializing Razorpay Payment Service...');

    // 1. Validate configuration
    if (_keyId.isEmpty || _keySecret.isEmpty) {
      throw Exception('❌ Razorpay keys not configured!');
    }

    if (_keySecret.contains('YOUR_ACTUAL_')) {
      throw Exception(
        '❌ Please replace placeholder key secret with actual value!',
      );
    }

    // 2. Validate environment consistency
    if (_isProduction) {
      if (!_keyId.startsWith('rzp_live_')) {
        throw Exception('❌ CRITICAL: Production mode but using test key!');
      }
      log('🔴 PRODUCTION MODE - Live payments enabled');
    } else {
      if (!_keyId.startsWith('rzp_test_')) {
        throw Exception('❌ CRITICAL: Test mode but using live key!');
      }
      log('🟡 TEST MODE - Test payments enabled');
    }

    // 3. Initialize Razorpay
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _isInitialized = true;

      log('✅ Razorpay initialized successfully');
      log('🔑 Using key: ${_keyId.substring(0, 12)}...');
      log('🌍 Environment: $_environment');
    } catch (e) {
      log('❌ Razorpay initialization failed: $e');
      throw Exception('Failed to initialize Razorpay: $e');
    }
  }

  // ✅ STEP 2: CREATE ORDER WITH PROPER RAZORPAY API
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String receipt,
    String currency = 'INR',
    Map<String, dynamic>? notes,
  }) async {
    try {
      log('📡 Creating Razorpay order directly...');
      log('💰 Amount: ₹$amount');
      log('🧾 Receipt: $receipt');
      log('🌍 Environment: $_environment');

      // Validate amount
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      final amountInPaise = (amount * 100).round();
      if (amountInPaise < 100) {
        throw Exception('Minimum amount is ₹1');
      }

      // Prepare request body according to Razorpay API docs
      final requestBody = {
        'amount': amountInPaise,
        'currency': currency,
        'receipt': receipt,
        'payment_capture': 1,
        if (notes != null) 'notes': notes,
      };

      log('📤 Request: ${jsonEncode(requestBody)}');

      // Create authorization header
      final auth = base64Encode(utf8.encode('$_keyId:$_keySecret'));

      final response = await http
          .post(
            Uri.parse(_razorpayApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic $auth',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      log('📥 Response Status: ${response.statusCode}');
      log('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderData = jsonDecode(response.body);

        if (orderData['id'] == null ||
            !orderData['id'].toString().startsWith('order_')) {
          throw Exception('Invalid order ID received: ${orderData['id']}');
        }

        _currentOrderId = orderData['id'];

        return {
          'success': true,
          'order_id': orderData['id'],
          'amount': orderData['amount'],
          'currency': orderData['currency'],
          'status': orderData['status'],
          'receipt': orderData['receipt'],
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception('Razorpay Error: ${errorData['error']['description']}');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - Check your Razorpay keys');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Order creation failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ STEP 3: OPEN RAZORPAY PAYMENT WITH COMPREHENSIVE VALIDATION
  Future<bool> openPayment({
    required String orderId,
    required double amount,
    required String customerName,
    required String description,
    String? email,
    String? phoneNumber,
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('Razorpay not initialized');
      }

      log('🚀 Opening Razorpay payment...');
      log('📋 Order: $orderId');
      log('💰 Amount: ₹$amount');
      log('👤 Customer: $customerName');

      // Validate inputs
      if (orderId.isEmpty || !orderId.startsWith('order_')) {
        throw Exception('Invalid order ID format: $orderId');
      }

      if (amount <= 0) {
        throw Exception('Invalid amount: $amount');
      }

      // Check environment consistency
      if (_isProduction && orderId.contains('_test_')) {
        log('⚠️ WARNING: Production environment but order ID looks like test');
      }

      final amountInPaise = (amount * 100).round();

      // Set callbacks
      if (onSuccess != null) this.onSuccess = onSuccess;
      if (onFailure != null) this.onFailure = onFailure;
      if (onExternalWallet != null) this.onExternalWallet = onExternalWallet;

      // Prepare payment options
      final options = <String, dynamic>{
        'key': _keyId,
        'order_id': orderId,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'RiDeal Driver App',
        'description': description,
        'image': 'https://your-logo-url.com/logo.png', // Optional logo
        'timeout': 300, // 5 minutes
        'retry': {'enabled': true, 'max_count': 3},
        'send_sms_hash': true,
        'allow_rotation': true,
        'prefill': {
          'name': customerName,
          if (email != null && email.isNotEmpty) 'email': email,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'contact': phoneNumber,
        },
        'readonly': {'email': email == null, 'contact': phoneNumber == null},
        'theme': {'color': '#2196F3', 'backdrop_color': '#F5F5F5'},
        'modal': {'escape': false, 'animation': true, 'backdrop_close': false},
      };

      log('📋 Payment Options Prepared:');
      log('  Key: ${options['key']}');
      log('  Order: ${options['order_id']}');
      log('  Amount: ${options['amount']} paise (₹$amount)');

      // Show loading dialog
      _showLoadingDialog('Opening payment gateway...');

      // Open Razorpay
      await Future.delayed(Duration(milliseconds: 500)); // Small delay for UI
      _razorpay.open(options);

      // Close loading dialog
      _closeLoadingDialog();

      return true;
    } catch (e) {
      log('❌ Failed to open payment: $e');
      _closeLoadingDialog();

      _showErrorDialog(
        'Payment Error',
        'Failed to open payment gateway: $e\\n\\nPlease try again or contact support.',
      );

      onFailure?.call(PaymentFailureResponse(1, e.toString(), null));
      return false;
    }
  }

  // ✅ STEP 4: PAYMENT EVENT HANDLERS
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    log('🎉 Payment SUCCESS!');
    log('💳 Payment ID: ${response.paymentId}');
    log('📋 Order ID: ${response.orderId}');
    log('🔒 Signature: ${response.signature}');

    _closeLoadingDialog();

    // Show success message
    _showSuccessDialog(
      'Payment Successful!',
      'Payment completed successfully.\\nPayment ID: ${response.paymentId}',
    );

    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    log('❌ Payment FAILED!');
    log('🔢 Code: ${response.code}');
    log('📝 Message: ${response.message}');

    _closeLoadingDialog();

    String userMessage = _getUserFriendlyErrorMessage(
      response.code,
      response.message,
    );
    _showErrorDialog('Payment Failed', userMessage);

    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    log('🏦 External wallet: ${response.walletName}');
    _closeLoadingDialog();
    onExternalWallet?.call(response);
  }

  // ✅ STEP 5: USER-FRIENDLY ERROR MESSAGES
  String _getUserFriendlyErrorMessage(int? code, String? message) {
    switch (code) {
      case 0:
        return 'Payment was cancelled. You can try again anytime.';
      case 1:
        return 'Network error occurred. Please check your internet connection and try again.';
      case 2:
        return 'Invalid payment details. Please contact support if this persists.';
      default:
        if (message?.contains('network') == true) {
          return 'Network connection failed. Please check your internet and try again.';
        }
        if (message?.contains('order') == true) {
          return 'Payment order expired. Please try creating a new order.';
        }
        if (message?.contains('key') == true) {
          return 'Payment configuration error. Please contact support.';
        }
        return message ??
            'Payment failed. Please try again or contact support.';
    }
  }

  // ✅ STEP 6: UI HELPERS
  void _showLoadingDialog(String message) {
    if (Get.isDialogOpen != true) {
      Get.dialog(
        AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  void _closeLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _showSuccessDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(onPressed: () => Get.back(), child: Text('OK')),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Flexible(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Close')),
          ElevatedButton(onPressed: () => Get.back(), child: Text('Retry')),
        ],
      ),
    );
  }

  // ✅ STEP 7: PAYMENT VERIFICATION
  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      log('🔍 Verifying payment...');
      log('💳 Payment ID: $paymentId');
      log('📋 Order ID: $orderId');

      final response = await http
          .post(
            Uri.parse('$_backendUrl/verify-subscription-payment'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await StorageHelper.getAuthToken()}',
            },
            body: jsonEncode({
              'razorpay_payment_id': paymentId,
              'razorpay_order_id': orderId,
              'razorpay_signature': signature,
              if (additionalData != null) ...additionalData,
            }),
          )
          .timeout(Duration(seconds: 30));

      log('📥 Verification Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      log('❌ Verification failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ STEP 8: COMPLETE PAYMENT FLOW
  Future<void> processPayment({
    required double amount,
    required String receipt,
    required String customerName,
    required String description,
    String? email,
    String? phone,
    required Function(Map<String, dynamic>) onVerificationSuccess,
    required Function(String) onError,
  }) async {
    try {
      log('🚀 Starting complete payment flow...');

      // Step 1: Create order
      final orderResult = await createRazorpayOrder(
        amount: amount,
        receipt: receipt,
        notes: {'description': description},
      );

      if (!orderResult['success']) {
        onError('Failed to create payment order: ${orderResult['error']}');
        return;
      }

      final orderId = orderResult['order_id'];
      log('✅ Order created: $orderId');

      // Step 2: Open payment
      final paymentOpened = await openPayment(
        orderId: orderId,
        amount: amount,
        customerName: customerName,
        description: description,
        email: email,
        phoneNumber: phone,
        onSuccess: (response) async {
          log('💳 Payment completed, verifying...');

          // Step 3: Verify payment
          final verificationResult = await verifyPayment(
            paymentId: response.paymentId!,
            orderId: response.orderId!,
            signature: response.signature!,
          );

          if (verificationResult['success']) {
            log('✅ Payment verified successfully!');
            onVerificationSuccess(verificationResult);
          } else {
            onError(
              'Payment verification failed: ${verificationResult['error']}',
            );
          }
        },
        onFailure: (response) {
          onError('Payment failed: ${response.message}');
        },
      );

      if (!paymentOpened) {
        onError('Failed to open payment gateway');
      }
    } catch (e) {
      onError('Payment process failed: $e');
    }
  }

  // Callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  // Cleanup
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
  }
}

// ✅ COMMON RAZORPAY ERROR CAUSES & SOLUTIONS
/*
🚨 "Uh oh! Something went wrong" - Common Causes:

1. WRONG ENVIRONMENT:
   ❌ Using test key with live order
   ❌ Using live key with test order
   ✅ Match key and order environment

2. INVALID ORDER ID:
   ❌ Empty or malformed order_id
   ❌ Expired order (24h limit)
   ✅ Create fresh order for each payment

3. AUTHENTICATION ISSUES:
   ❌ Wrong key_id or key_secret
   ❌ Missing/expired authorization
   ✅ Validate credentials before use

4. AMOUNT MISMATCH:
   ❌ Order amount != payment amount
   ❌ Amount in rupees instead of paise
   ✅ Always use paise (₹1 = 100 paise)

5. NETWORK ISSUES:
   ❌ Poor internet connection
   ❌ Timeout during order creation
   ✅ Add proper timeout handling

6. BACKEND ISSUES:
   ❌ Backend returns wrong order format
   ❌ Missing required fields in response
   ✅ Validate backend response structure

📝 DEBUGGING STEPS:
1. Check logs for exact error
2. Validate environment consistency  
3. Test with minimal order first
4. Verify credentials in Razorpay dashboard
5. Test with different payment methods
6. Check network connectivity
*/
