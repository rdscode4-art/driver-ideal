import 'dart:convert';
import 'dart:developer';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';

class RazorpayPaymentService {
  // 🔧 RAZORPAY CONFIGURATION - CRITICAL SETUP
  static const String _razorpayKeyId = ' rzp_live_RoLpvsh1Qs9Cfs';
  // IMPORTANT: Razorpay *secret* must NEVER be stored in client code.
  // The secret has been removed from the client. Order creation and
  // signature verification must be performed on the backend where the
  // secret is securely stored.

  // Provide lightweight accessors used by the client. The secret is
  // intentionally empty to avoid accidental use in client code.
  String get _keyId => _razorpayKeyId;
  String get _keySecret => ''; // secret removed from client
  static const String _baseUrl = 'https://backend.ridealmobility.com';

  // Environment validation
  static const bool _isLiveMode = false; // Set to true for production

  late Razorpay _razorpay;
  String? _currentOrderId;

  // Payment callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayPaymentService() {
    _validateConfiguration();
    _initializeRazorpay();
  }

  /// 🛒 NEW: Complete Subscription Purchase Flow
  /// Step 1: Call backend to create subscription order
  /// Step 2: Open Razorpay with returned order details
  /// Step 3: Handle success and verify payment
  Future<void> buySubscriptionComplete({
    required String driverId,
    required String planType,
    required double amount,
    String? contact,
    String? email,
  }) async {
    try {
      log('🛒 ════════════════════════════════════════════════════════');
      log('🛒           COMPLETE SUBSCRIPTION PURCHASE FLOW');
      log('🛒 ════════════════════════════════════════════════════════');
      log('👤 Driver ID: $driverId');
      log('📦 Plan Type: $planType');
      log('💰 Amount: ₹$amount');

      // Step 1: Create subscription order with backend
      final orderResponse = await _createSubscriptionOrder(
        driverId: driverId,
        planType: planType,
        amount: amount,
      );

      if (!orderResponse['success']) {
        throw Exception(orderResponse['message'] ?? 'Failed to create order');
      }

      final orderId = orderResponse['orderId'];
      final orderAmount = orderResponse['amount'];
      final planId = orderResponse['planId'];

      log(
        '✅ Order created - ID: $orderId, Amount: ₹$orderAmount, Plan: $planId',
      );

      // Step 2: Open Razorpay checkout
      await openCheckout(
        orderId: orderId,
        amount: orderAmount,
        name: 'RiDeal Driver',
        description: planType,
        email: email,
        contact: contact,
      );
    } catch (e) {
      log('❌ Error in buySubscriptionComplete: $e');
      throw Exception('Failed to start payment: $e');
    }
  }

  /// 🛒 Create Subscription Order with Backend
  Future<Map<String, dynamic>> _createSubscriptionOrder({
    required String driverId,
    required String planType,
    required double amount,
  }) async {
    try {
      log('📡 Creating subscription order with backend...');

      final authToken = await StorageHelper.getAuthToken();

      final requestBody = {
        'driverId': driverId,
        'planType': planType,
        'amount': amount,
      };

      log('📤 Request: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/buy-subscription'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      log('📥 Response Status: ${response.statusCode}');
      log('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orderId': data['orderId'],
          'amount': data['amount'],
          'planId': data['planId'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      log('❌ Error creating subscription order: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ✅ STEP 1: Validate Razorpay Configuration
  void _validateConfiguration() {
    if (_keyId.isEmpty || _keyId == ' rzp_live_RoLpvsh1Qs9Cfs') {
      log(
        '⚠️ WARNING: Using default test key. Please add your actual Razorpay key.',
      );
    }

    if (_keySecret.contains('YOUR_ACTUAL_TEST_KEY_SECRET')) {
      log('❌ ERROR: You must add your actual Razorpay key secret!');
    }

    // Validate key-mode consistency
    if (_isLiveMode && _keyId.startsWith('rzp_test_')) {
      log('❌ CRITICAL ERROR: Live mode enabled but using test key!');
      throw Exception('Environment mismatch: Live mode with test key');
    }

    if (!_isLiveMode && _keyId.startsWith('rzp_live_')) {
      log('❌ CRITICAL ERROR: Test mode but using live key!');
      throw Exception('Environment mismatch: Test mode with live key');
    }

    log('✅ Razorpay configuration validated');
    log('🔧 Mode: ${_isLiveMode ? "LIVE" : "TEST"}');
    log('🔑 Key: ${_keyId.substring(0, 12)}...');
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    log('🚀 Razorpay initialized successfully');
  }

  // ✅ STEP 2: Create Razorpay Order with Proper API Format
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String receipt,
    String currency = 'INR',
    Map<String, dynamic>? notes,
  }) async {
    try {
      log('📡 Creating Razorpay order with official API...');
      log('💰 Amount: ₹$amount (${(amount * 100).round()} paise)');
      log('🧾 Receipt: $receipt');
      log('💱 Currency: $currency');

      // Convert amount to paise (Razorpay requirement)
      final amountInPaise = (amount * 100).round();

      // Validate amount
      if (amountInPaise < 100) {
        throw Exception('Minimum amount is ₹1 (100 paise)');
      }

      // Prepare request body as per Razorpay API docs
      final requestBody = {
        'amount': amountInPaise,
        'currency': currency,
        'receipt': receipt,
        'payment_capture': 1, // Auto-capture payment
        if (notes != null) 'notes': notes,
      };

      // NOTE: Client-side order creation against Razorpay requires the
      // Razorpay secret and MUST NOT be done from the mobile app.
      // Use your backend endpoint `/api/create-order` which holds the
      // secret, creates the order, and returns the `orderId` and `key`.
      log(
        '⚠️ Client-side order creation disabled. Call backend /api/create-order',
      );
      return {
        'success': false,
        'error':
            'Client-side order creation disabled. Call backend /api/create-order.',
      };
    } catch (e) {
      log('❌ Razorpay order creation failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ STEP 3: Alternative - Create Order via Backend (Your Current Flow)
  Future<Map<String, dynamic>> createBackendOrder({
    required double amount,
    required String receipt,
    required String driverId,
    required String planType,
    String currency = 'INR',
  }) async {
    try {
      log('📡 Creating order via backend...');
      log('👤 Driver: $driverId');
      log('📦 Plan: $planType');
      log('💰 Original Amount: ₹$amount');

      // Amount should already be in rupees, not paise for backend
      final amountInRupees = amount.round();
      log('💰 Amount for Backend: ₹$amountInRupees');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/buy-subscription'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await StorageHelper.getAuthToken()}',
            },
            body: jsonEncode({
              'driverId': driverId,
              'planType': planType,
              'amount':
                  amountInRupees, // Send in rupees, backend will convert to paise
            }),
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () => throw Exception('Backend timeout'),
          );

      log('📥 Backend Response Status: ${response.statusCode}');
      log('📥 Backend Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        log('🔍 Backend Response Analysis:');
        log('  Success: ${data['success']}');
        log('  OrderId: ${data['orderId']}');
        log('  Amount: ${data['amount']}');
        log('  Currency: ${data['currency']}');

        if (data['success'] == true && data['orderId'] != null) {
          _currentOrderId = data['orderId'];

          // Backend returns amount in paise, convert for display
          final backendAmount = data['amount'] ?? amountInRupees;
          final finalAmount = backendAmount is int
              ? backendAmount
              : (backendAmount * 100).round();
          log('💰 Final Amount: $finalAmount paise');

          return {
            'success': true,
            'order_id': data['orderId'],
            'amount': finalAmount, // Amount in paise for Razorpay
            'currency': data['currency'] ?? currency,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to create order');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Backend error: ${errorData['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Backend order creation failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // STEP 2: Open Razorpay Payment Gateway
  Future<void> openCheckout({
    required String orderId,
    required dynamic amount, // Can be int (paise) or double (rupees)
    required String name,
    required String description,
    String? email,
    String? contact,
    Map<String, dynamic>? notes,
  }) async {
    try {
      log('🚀 Opening Razorpay checkout...');
      log('📋 Order ID: $orderId');

      // Handle amount - if it's already in paise (int), use as is
      // If it's in rupees (double), convert to paise
      final amountInPaise = amount is int ? amount : (amount * 100).round();
      log('💰 Amount: $amountInPaise paise');

      // Use minimal options for better compatibility
      var options = {
        'key': _keyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'order_id': orderId,
        'name': 'RiDeal Driver',
        'description': description,
        'prefill': {
          'name': name,
          if (contact != null) 'contact': contact,
          if (email != null) 'email': email,
        },
        'theme': {'color': '#2196F3'},
      };

      log('📋  Response Body: ');
      log('   Key: $_keyId');
      log('   Amount: $amountInPaise paise');
      log('   Order ID: $orderId');

      log('🔧 Test Mode: $_isLiveMode');
      log('🔍 Should Simulate: false');
      log('🚀 Initializing Razorpay for subscription payments...');

      // Validate minimum amount
      if (amountInPaise < 100) {
        throw Exception('Amount too low: $amountInPaise paise (minimum ₹1)');
      }

      // Re-initialize Razorpay to ensure clean state
      _razorpay.clear();
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      log('✅ Razorpay initialized with event listeners');
      log('📋 Success Event: payment.success');
      log('❌ Error Event: payment.error');
      log('🏦 Wallet Event: payment.external_wallet');

      log('💳 REAL RAZORPAY MODE: Opening actual payment gateway...');
      log('🔍 About to open Razorpay with minimal options...');
      log('   Razorpay instance initialized $options');

      _razorpay.open(options);
      log('✅ Checkout opened successfully - waiting for payment completion...');
    } catch (e) {
      log('❌ Failed to open checkout: $e');
      onFailure?.call(
        PaymentFailureResponse(
          1, // Generic error code
          'Failed to open payment gateway: $e',
          null, // orderId might not be available at this point
        ),
      );
    }
  }

  // STEP 3: Handle Payment Success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    log('🎉 Payment successful!');
    log('💳 Payment ID: ${response.paymentId}');
    log('📋 Order ID: ${response.orderId}');
    log('🔒 Signature: ${response.signature}');

    onSuccess?.call(response);
  }

  // Handle Payment Failure
  void _handlePaymentError(PaymentFailureResponse response) {
    log('❌ ════════════════════════════════════════════════════════');
    log('❌           RAZORPAY PAYMENT ERROR');
    log('❌ ════════════════════════════════════════════════════════');
    log('🚨 Error Code: ${response.code}');
    log('📝 Error Description: ${response.message}');
    log('❌ ════════════════════════════════════════════════════════');

    // Provide user-friendly error messages
    String userMessage;
    switch (response.code) {
      case 0:
        userMessage = 'Payment was cancelled by you';
        break;
      case 1:
        userMessage = 'Network error - Please check your internet connection';
        break;
      case 2:
        userMessage = 'Payment gateway configuration error';
        break;
      default:
        userMessage = 'Payment failed: ${response.message}';
    }

    log('👤 User Message: $userMessage');
    onFailure?.call(response);
  }

  // Handle External Wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    log('🏦 External wallet selected: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  // STEP 4: Verify Payment
  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String driverId,
    required String planId,
  }) async {
    try {
      log('🔍 ════════════════════════════════════════════════════════');
      log('🔍           STARTING PAYMENT VERIFICATION');
      log('🔍 ════════════════════════════════════════════════════════');
      log('💳 Payment ID: $paymentId');
      log('📋 Order ID: $orderId');
      log('🔒 Signature: $signature');
      log('👤 Driver ID: $driverId');
      log('📦 Plan ID: $planId');

      final authToken = await StorageHelper.getAuthToken();
      log('🔐 Auth Token: ${authToken?.substring(0, 20) ?? 'null'}...');
      log('📡 API Call: POST $_baseUrl/verify-subscription-payment');

      final requestBody = {
        'driverId': driverId,
        'planId': planId,
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
      };

      log('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/verify-subscription-payment'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            Duration(seconds: 60), // Increased timeout
            onTimeout: () {
              log('⏰ Verification API timeout after 60 seconds');
              throw Exception(
                'Verification timeout. Please check your connection.',
              );
            },
          );

      log('📥 ════════════════════════════════════════════════════════');
      log('📥           VERIFICATION API RESPONSE');
      log('📥 ════════════════════════════════════════════════════════');
      log('📥 Status Code: ${response.statusCode}');
      log('📥 Headers: ${response.headers}');
      log('📥 Response Body: ${response.body}');
      log('📥 ════════════════════════════════════════════════════════');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);

          if (data['success'] == true) {
            log('✅ ════════════════════════════════════════════════════════');
            log('✅           PAYMENT VERIFICATION SUCCESSFUL!');
            log('✅ ════════════════════════════════════════════════════════');
            log('✅ Message: ${data['message'] ?? 'No message'}');
            log('✅ Data: ${data['data']}');

            return {
              'success': true,
              'data': data['data'],
              'message': data['message'] ?? 'Payment verified successfully',
            };
          } else {
            final errorMsg = data['message'] ?? 'Payment verification failed';
            log('❌ Verification failed: $errorMsg');
            throw Exception(errorMsg);
          }
        } catch (jsonError) {
          log('❌ Failed to parse response JSON: $jsonError');
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 'Bad request';
          log('❌ Bad Request (400): $errorMsg');
          throw Exception('Verification failed: $errorMsg');
        } catch (e) {
          throw Exception('Bad request: Invalid data sent to server');
        }
      } else if (response.statusCode == 401) {
        log('❌ Unauthorized (401): Invalid authentication');
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        log('❌ Not Found (404): Verification endpoint not found');
        throw Exception('Verification service not available');
      } else if (response.statusCode == 500) {
        log('❌ Server Error (500): Backend server error');

        // Try manual verification if backend is down
        log('🔄 Backend seems down, trying manual verification...');
        return await _manualVerifyPayment(
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        );
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 'Unknown server error';
          log('❌ Server Error (${response.statusCode}): $errorMsg');
          throw Exception('Server error: $errorMsg');
        } catch (e) {
          log('❌ Server Error (${response.statusCode}): ${response.body}');
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      log('❌ ════════════════════════════════════════════════════════');
      log('❌           VERIFICATION ERROR');
      log('❌ ════════════════════════════════════════════════════════');
      log('❌ Error Type: ${e.runtimeType}');
      log('❌ Error Message: $e');
      log('❌ ════════════════════════════════════════════════════════');

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Manual verification when backend is unavailable
  Future<Map<String, dynamic>> _manualVerifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      log('🔄 ════════════════════════════════════════════════════════');
      log('🔄         MANUAL PAYMENT VERIFICATION (FALLBACK)');
      log('🔄 ════════════════════════════════════════════════════════');

      // Manual verification on the client is NOT supported because it
      // requires the Razorpay secret. Instruct the caller to retry
      // verification against the backend endpoint instead.
      log('⚠️ Manual verification unavailable on client (secret removed).');
      return {
        'success': false,
        'error':
            'Manual verification unavailable on client. Verify on backend /api/verify-payment.',
      };
    } catch (e) {
      log('❌ Manual verification failed: $e');
      return {'success': false, 'error': 'Manual verification failed: $e'};
    }
  }

  /// Generate expected signature for verification
  String _generateExpectedSignature(String orderId, String paymentId) {
    // Signature generation requires the Razorpay secret which is not
    // available in the client. Always perform signature verification
    // on the backend using the secret.
    log(
      '⚠️ Signature generation not available on client. Use backend verification.',
    );
    return '';
  }

  /// Store payment details locally as backup
  Future<void> _storePaymentLocally(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    try {
      await StorageHelper.setString('last_payment_id', paymentId);
      await StorageHelper.setString('last_order_id', orderId);
      await StorageHelper.setString('last_payment_signature', signature);
      await StorageHelper.setString(
        'last_payment_timestamp',
        DateTime.now().toIso8601String(),
      );

      log('💾 Payment details stored locally');
    } catch (e) {
      log('❌ Failed to store payment locally: $e');
    }
  }

  // Complete Payment Flow
  Future<void> processPayment({
    required double amount,
    required String description,
    required String driverId,
    required String planId,
    required String driverName,
    String? driverEmail,
    String? driverPhone,
    String? planType, // Add explicit planType parameter
    required Function(Map<String, dynamic>) onVerificationSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Step 1: Create order
      final orderResult = await createBackendOrder(
        amount: amount,
        receipt: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        driverId: driverId,
        planType:
            planType ??
            description, // Use planType if provided, otherwise description
      );

      if (!orderResult['success']) {
        onError('Failed to create order: ${orderResult['error']}');
        return;
      }

      final orderId = orderResult['order_id'];

      // Set callbacks
      onSuccess = (PaymentSuccessResponse response) async {
        log('🎉 ════════════════════════════════════════════════════════');
        log('🎉         RAZORPAY PAYMENT SUCCESS RECEIVED');
        log('🎉 ════════════════════════════════════════════════════════');
        log('💳 Payment ID: ${response.paymentId}');
        log('📋 Order ID: ${response.orderId}');
        log('🔒 Signature: ${response.signature}');
        log('🎉 ════════════════════════════════════════════════════════');

        try {
          // Step 3: Verify payment
          final verificationResult = await verifyPayment(
            paymentId: response.paymentId!,
            orderId: response.orderId!,
            signature: response.signature!,
            driverId: driverId,
            planId: planId,
          );

          if (verificationResult['success']) {
            log('✅ Complete payment flow successful!');
            onVerificationSuccess(verificationResult);
          } else {
            log('❌ Verification failed: ${verificationResult['error']}');
            onError(
              'Payment verification failed: ${verificationResult['error']}',
            );
          }
        } catch (e) {
          log('❌ Error during verification: $e');
          onError('Verification error: $e');
        }
      };

      onFailure = (PaymentFailureResponse response) {
        onError('Payment failed: ${response.message}');
      };

      onExternalWallet = (ExternalWalletResponse response) {
        onError('External wallet payments not supported yet');
      };

      // Step 2: Open checkout with amount from order response
      final orderAmount =
          orderResult['amount']; // This should be in paise from backend
      await openCheckout(
        orderId: orderId,
        amount: orderAmount, // Use amount from order response (in paise)
        name: driverName,
        description: description,
        email: driverEmail,
        contact: driverPhone,
        notes: {'driver_id': driverId, 'plan_id': planId},
      );
    } catch (e) {
      onError('Payment process failed: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}

// Payment Result Models
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;
  final Map<String, dynamic>? data;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.error,
    this.data,
  });
}

// Common Payment Errors
class PaymentErrors {
  static const String PAYMENT_CANCELLED = 'Payment cancelled by user';
  static const String NETWORK_ERROR = 'Network connection failed';
  static const String INVALID_CREDENTIALS = 'Invalid Razorpay credentials';
  static const String ORDER_EXPIRED = 'Payment order has expired';
  static const String INSUFFICIENT_BALANCE = 'Insufficient balance';
  static const String CARD_DECLINED = 'Card payment declined';
  static const String VERIFICATION_FAILED = 'Payment verification failed';

  static String getErrorMessage(int errorCode) {
    switch (errorCode) {
      case 0:
        return PAYMENT_CANCELLED;
      case 1:
        return NETWORK_ERROR;
      case 2:
        return INVALID_CREDENTIALS;
      case 3:
        return ORDER_EXPIRED;
      default:
        return 'Unknown payment error';
    }
  }
}
