import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

/// 🚀 Production-ready Razorpay Service for RiDeal Driver App
/// Handles complete payment flow with backend integration
class RazorpayService extends GetxService {
  // Razorpay Configuration
  static const String _keyId = 'rzp_live_RoLpvsh1Qs9Cfs';

  late Razorpay _razorpay;
  late ApiService _apiService;

  // Payment state
  String? _currentOrderId;
  String? _currentPlanId;
  String? _currentDriverId;

  // Payment callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _initializeRazorpay();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  /// Initialize Razorpay with event listeners
  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    log('🚀 RazorpayService initialized successfully');
    log('🔑 Key ID: $_keyId');
  }

  /// 🛒 Complete Subscription Payment Flow
  /// Step 1: Create subscription order from backend
  /// Step 2: Open Razorpay checkout
  /// Step 3: Handle payment success/failure
  /// Step 4: Verify payment with backend
  /// ✅ FIXED: Changed planType to planId (MongoDB ObjectId)
  Future<void> buySubscription({
    required String driverId,
    required String planId,  // ✅ Now expects MongoDB ObjectId (24 chars)
    required double amount,
    String? contact,
    String? email,
  }) async {
    try {
      print('\n🛒 ════════════════════════════════════════════════════════');
      print('🛒           STARTING SUBSCRIPTION PURCHASE');
      print('🛒 ════════════════════════════════════════════════════════');
      print('🛒 Driver ID: $driverId');
      print('🛒 Plan ID: $planId');  // ✅ Now logging planId
      print('🛒 Amount: ₹$amount');
      print('🛒 ════════════════════════════════════════════════════════\n');

      // ✅ Validate planId format (MongoDB ObjectId must be 24 chars)
      if (planId.length != 24) {
        throw Exception('Invalid plan ID format. Expected 24 characters, got ${planId.length}');
      }

      // Store current session data
      _currentDriverId = driverId;
      _currentPlanId = planId;  // ✅ Store the plan ID

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Step 1: Create subscription order with backend
      log('📡 Step 1: Creating subscription order...');
      final orderResponse = await _apiService.buySubscription(
        driverId: driverId,
        planType: planId,  // ✅ Send planId to backend (API method still named planType)
        amount: amount,
      );

      // Close loading dialog
      Get.back();

      if (!orderResponse.isSuccess) {
        log('❌ Failed to create subscription order');
        _showError(
          'Failed to create order: ${orderResponse.message ?? 'Unknown error'}',
        );
        return;
      }

      // ✅ CRITICAL: Extract EXACT values from backend response
      final orderData = orderResponse.data!;
      final backendOrderId = orderData['orderId']; // EXACT backend order ID
      final backendAmount = orderData['amount']; // EXACT backend amount
      final backendCurrency = orderData['currency'] ?? 'INR'; // Backend currency
      final backendPlanId = orderData['planId'] ?? orderData['planType']; // ✅ Try both field names

      print('\n📋 Backend order response:');
      print('   orderId: $backendOrderId');
      print('   amount: $backendAmount');
      print('   currency: $backendCurrency');
      print('   planId: $backendPlanId');
      print('   response data: ${jsonEncode(orderData)}');

      if (backendOrderId == null || backendAmount == null) {
        print('❌ Invalid order response format');
        print('❌ Missing required fields in response');
        _showError('Invalid response from server - missing order details');
        return;
      }

      // ✅ VALIDATION: Ensure orderId is not empty
      if (backendOrderId.toString().trim().isEmpty) {
        print('❌ Empty orderId received from backend');
        _showError('Invalid order ID received from server');
        return;
      }

      // Store exact values for verification (DO NOT MODIFY)
      _currentOrderId = backendOrderId.toString(); // EXACT backend order ID
      _currentDriverId = driverId; // Driver ID for verification
      _currentPlanId = planId; // ✅ Plan ID for verification (MongoDB ObjectId)

      print('✅ Order validation passed:');
      print('   EXACT orderId: $backendOrderId');
      print('   amount: $backendAmount');
      print('   currency: $backendCurrency');
      print('   planId: $_currentPlanId');
      print('   driverId: $_currentDriverId');
      print('🔥 USING EXACT BACKEND ORDER ID: $backendOrderId');

      // Step 2: Open Razorpay checkout with EXACT backend values
      await _openRazorpayCheckout(
        backendOrderId: backendOrderId, // EXACT backend order ID
        backendAmount: backendAmount, // EXACT backend amount
        backendCurrency: backendCurrency, // EXACT backend currency
        planId: planId,  // ✅ Pass planId
        contact: contact,
        email: email,
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      log('❌ Error in buySubscription: $e');
      _showError('Failed to start payment: $e');
    }
  }

  /// Open Razorpay checkout with EXACT backend values
  /// ✅ FIXED: Changed planType parameter to planId
  Future<void> _openRazorpayCheckout({
    required dynamic backendOrderId, // EXACT from backend
    required dynamic backendAmount, // EXACT from backend
    required String backendCurrency, // EXACT from backend
    required String planId,  // ✅ Changed from planType to planId
    String? contact,
    String? email,
  }) async {
    try {
      print('\n💳 ════════════════════════════════════════════════════════');
      print('💳           OPENING RAZORPAY CHECKOUT');
      print('💳 ════════════════════════════════════════════════════════');
      print('💳 Backend Order ID: $backendOrderId');
      print('💳 Backend Amount: $backendAmount');
      print('💳 Backend Currency: $backendCurrency');
      print('💳 Plan ID: $planId');  // ✅ Log planId
      print('💳 ════════════════════════════════════════════════════════\n');

      // 🚨 CRITICAL: Use EXACT backend values without ANY modification
      final exactOrderId = backendOrderId.toString(); // EXACT backend order ID
      final exactAmount = (backendAmount is String)
          ? double.parse(backendAmount.toString())
          : backendAmount.toDouble(); // EXACT backend amount
      final exactCurrency = backendCurrency; // EXACT backend currency

      // Convert amount to paise (Razorpay requirement)
      final amountInPaise = (exactAmount * 100).round();

      // Validate minimum amount
      if (amountInPaise < 100) {
        throw Exception('Minimum amount is ₹1');
      }

      print('💰 EXACT Backend Values:');
      print('   orderId: "$exactOrderId"');
      print('   amount: $exactAmount (₹$exactAmount)');
      print('   amountInPaise: $amountInPaise');
      print('   currency: "$exactCurrency"');
      print('🔥 NO MODIFICATIONS TO BACKEND VALUES\n');

      // ✅ CONSTRUCT RAZORPAY OPTIONS WITH EXACT BACKEND VALUES
      final options = {
        'key': _keyId, // Razorpay public key
        'amount': amountInPaise, // Backend amount in paise
        'currency': exactCurrency, // Backend currency (exact)
        'order_id': exactOrderId, // 🔥 EXACT backend order ID
        'name': 'RiDeal Subscription', // Payment title
        'description': 'Subscription Payment', // ✅ Generic description
        'prefill': {
          if (contact != null && contact.isNotEmpty) 'contact': contact,
          if (email != null && email.isNotEmpty) 'email': email,
        },
        'theme': {'color': '#2196F3'},
      };

      print('\n🚀 Razorpay Options (EXACT backend values):');
      print('   key: $_keyId');
      print('   amount: $amountInPaise paise');
      print('   currency: $exactCurrency');
      print('   order_id: "$exactOrderId" ← MUST MATCH BACKEND');
      print('   name: RiDeal Subscription');
      print('   description: Subscription Payment');
      print('🚀 ════════════════════════════════════════════════════════\n');

      print(
        '🔥 CRITICAL: Razorpay will return this SAME order_id: "$exactOrderId"',
      );
      print(
        '🔥 Backend expects this EXACT order_id for signature verification\n',
      );

      // Open Razorpay with EXACT backend values
      _razorpay.open(options);

      print(
        '✅ Razorpay checkout opened with EXACT backend order ID: $exactOrderId',
      );
    } catch (e) {
      print('❌ Failed to open Razorpay checkout: $e');
      _showError('Failed to open payment gateway: $e');
    }
  }

  /// Handle successful payment from Razorpay
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print('\n🎉 ════════════════════════════════════════════════════════');
      print('🎉           PAYMENT SUCCESS FROM RAZORPAY');
      print('🎉 ════════════════════════════════════════════════════════');

      // 🔍 CRITICAL DEBUGGING - Log EXACT values from Razorpay
      print('PAYMENT: ${response.paymentId}');
      print('ORDER: ${response.orderId}');
      print('SIGNATURE: ${response.signature}');
      print('SIGNATURE LENGTH: ${response.signature?.length}');

      // 🚨 CRITICAL VALIDATION STAGE 1: Check for null/empty values
      if (response.paymentId == null || response.paymentId!.isEmpty) {
        print('❌ FRONTEND ERROR: paymentId is null or empty');
        _showError('Invalid payment ID received from Razorpay');
        return;
      }

      if (response.orderId == null || response.orderId!.isEmpty) {
        print('❌ FRONTEND ERROR: orderId is null or empty');
        _showError('Invalid order ID received from Razorpay');
        return;
      }

      if (response.signature == null || response.signature!.isEmpty) {
        print('❌ FRONTEND ERROR: signature is null or empty');
        _showError('Invalid signature received from Razorpay');
        return;
      }

      // 🚨 CRITICAL VALIDATION STAGE 2: Signature length MUST be 64
      final signatureLength = response.signature!.length;
      print('🔍 Signature validation - Length: $signatureLength');

      if (signatureLength != 64) {
        print('❌ FRONTEND SIGNATURE INVALID');
        print('❌ Expected: 64 characters');
        print('❌ Got: $signatureLength characters');
        print('❌ Signature: "${response.signature}"');
        print('❌ DO NOT CALL BACKEND VERIFICATION');

        _showError(
          'Invalid Razorpay signature format.\n'
          'Expected: 64 characters\n'
          'Received: $signatureLength characters\n'
          'Please contact support.',
        );
        return;
      }

      print('✅ Signature validation PASSED - Length: $signatureLength');
      print('✅ Proceeding with backend verification...');

      // Show verification loading
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying payment with backend...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Step 3: Verify payment with backend using EXACT values
      await _verifyPaymentWithBackend(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature!,
      );
    } catch (e) {
      print('❌ Error in _handlePaymentSuccess: $e');

      // Close any open dialogs
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      _showError('Payment processing failed: $e');
    }
  }

  /// Verify payment with backend using EXACT Razorpay values
  Future<void> _verifyPaymentWithBackend({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      print('\n🔍 ════════════════════════════════════════════════════════');
      print('🔍           VERIFYING PAYMENT WITH BACKEND');
      print('🔍 ════════════════════════════════════════════════════════');

      if (_currentDriverId == null || _currentPlanId == null) {
        throw Exception('Missing driver ID or plan ID for verification');
      }

      // 🔍 FINAL DEBUG: Log exact values being sent to backend
      print('📤 Backend verification payload:');
      print('   driverId: $_currentDriverId');
      print('   planId: $_currentPlanId (MongoDB ObjectId)');  // ✅ Clarified it's ObjectId
      print('   razorpay_payment_id: $paymentId');
      print('   razorpay_order_id: $orderId');
      print('   razorpay_signature: $signature');
      print('   signature_length: ${signature.length}');

      // 🚨 FINAL VALIDATION: Ensure signature is still 64 characters
      if (signature.length != 64) {
        print('❌ CRITICAL: Signature length changed during processing!');
        print('❌ Length: ${signature.length}');
        throw Exception('Signature corruption detected');
      }

      // ✅ Validate planId format one more time before sending
      if (_currentPlanId!.length != 24) {
        print('❌ CRITICAL: Invalid plan ID format!');
        print('❌ Expected: 24 characters (MongoDB ObjectId)');
        print('❌ Got: ${_currentPlanId!.length} characters');
        print('❌ Plan ID: "$_currentPlanId"');
        throw Exception('Invalid plan ID format');
      }

      print('✅ Final signature validation passed');
      print('✅ Final planId validation passed');
      print('🚀 Sending request to backend...');

      // ✅ SEND EXACT VALUES TO BACKEND (no modifications)
      final verificationResponse = await _apiService.verifySubscriptionPayment(
        driverId: _currentDriverId!,
        planId: _currentPlanId!,  // ✅ MongoDB ObjectId (24 chars)
        razorpayPaymentId: paymentId, // EXACT from response.paymentId
        razorpayOrderId: orderId, // EXACT from response.orderId
        razorpaySignature: signature, // EXACT from response.signature (64 chars)
      );

      print('📥 Backend response received');
      print('📥 Success: ${verificationResponse.isSuccess}');
      print('📥 Message: ${verificationResponse.message}');

      // Close verification dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (verificationResponse.isSuccess) {
        print('✅ ════════════════════════════════════════════════════════');
        print('✅           PAYMENT VERIFICATION SUCCESSFUL');
        print('✅ ════════════════════════════════════════════════════════');

        // Show success message
        _showSuccess('Payment successful! Subscription activated.');

        // Call success callback if available
        onSuccess?.call(
          PaymentSuccessResponse(
            paymentId,
            orderId,
            signature,
            null, // walletName parameter
          ),
        );

        // Navigate to dashboard
        try {
          Get.offAllNamed('/dashboard');
        } catch (e) {
          print('❌ Navigation error: $e');
          Get.back();
        }
      } else {
        print('❌ Backend verification failed');
        print('❌ Backend message: ${verificationResponse.message}');

        _showError(
          'Payment verification failed: ${verificationResponse.message ?? 'Unknown error'}\n'
          'Please contact support with this payment ID: $paymentId',
        );
      }
    } catch (e) {
      print('❌ Error in _verifyPaymentWithBackend: $e');

      // Close verification dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      _showError(
        'Payment verification failed: $e\n'
        'Please contact support.',
      );
    }
  }

  /// Handle payment failure from Razorpay
  void _handlePaymentError(PaymentFailureResponse response) {
    log('❌ ════════════════════════════════════════════════════════');
    log('❌           PAYMENT FAILED');
    log('❌ ════════════════════════════════════════════════════════');
    log('🚨 Error Code: ${response.code}');
    log('📝 Error Message: ${response.message}');

    String errorMessage;

    switch (response.code) {
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'Payment was cancelled by user';
        break;
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network error occurred. Please check your connection.';
        break;
      default:
        errorMessage = response.message ?? 'Payment failed. Please try again.';
    }

    _showError(errorMessage);
    onFailure?.call(response);
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    log('🏦 External wallet selected: ${response.walletName}');
    _showInfo('Opening ${response.walletName} wallet...');
    onExternalWallet?.call(response);
  }

  /// Show error toast and dialog
  void _showError(String message) {
    log('❌ Showing error: $message');

    // Show toast
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    // Show dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  /// Show success toast
  void _showSuccess(String message) {
    log('✅ Showing success: $message');

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  /// Show info toast
  void _showInfo(String message) {
    log('ℹ️ Showing info: $message');

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  /// Clean up payment session
  void cleanupSession() {
    _currentOrderId = null;
    _currentPlanId = null;
    _currentDriverId = null;
    log('🧹 Payment session cleaned up');
  }

  /// Get current session info (for debugging)
  Map<String, String?> getSessionInfo() {
    return {
      'orderId': _currentOrderId,
      'planId': _currentPlanId,
      'driverId': _currentDriverId,
    };
  }
}