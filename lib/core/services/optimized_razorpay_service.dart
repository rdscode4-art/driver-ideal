import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rideal_driver/core/utils/razorpay_webview_optimizer.dart';
import 'razorpay_webview_config.dart';

/// Optimized Razorpay service to prevent UI blocking
class OptimizedRazorpayService extends GetxService {
  late Razorpay _razorpay;
  final RxBool isInitialized = false.obs;
  final RxBool isProcessing = false.obs;

  // Callbacks
  Function(PaymentSuccessResponse)? onPaymentSuccess;
  Function(PaymentFailureResponse)? onPaymentError;
  Function(ExternalWalletResponse)? onExternalWallet;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeRazorpay();
  }

  /// Initialize Razorpay without blocking UI thread
  Future<void> _initializeRazorpay() async {
    try {
      print('🚀 Initializing optimized Razorpay service...');

      // Initialize WebView with GPU/Canvas fixes first
      await RazorpayWebViewConfig.initializeForRazorpay();

      // Initialize Razorpay on separate isolate
      _razorpay = Razorpay();

      // Set up event listeners
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      // Pre-load WebView in background
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RazorpayWebViewOptimizer.preloadWebView();
      });

      isInitialized.value = true;
      print('✅ Razorpay service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Razorpay service: $e');
    }
  }

  /// Open payment gateway with optimization
  Future<void> openPaymentGateway({
    required String keyId,
    required int amountInPaise,
    required String orderId,
    required String phone,
    required String email,
    required String name,
    required String driverId,
    required String planType,
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onError,
    Function(ExternalWalletResponse)? onWallet,
  }) async {
    if (!isInitialized.value) {
      throw Exception('Razorpay service not initialized');
    }

    if (isProcessing.value) {
      print('⚠️ Payment already in progress, ignoring duplicate request');
      return;
    }

    try {
      isProcessing.value = true;

      // Set callbacks
      onPaymentSuccess = onSuccess;
      onPaymentError = onError;
      onExternalWallet = onWallet;

      print('💳 Opening optimized Razorpay payment gateway...');
      print('📊 Order: $orderId | Amount: ₹${amountInPaise / 100}');

      // Show optimization tips
      RazorpayWebViewOptimizer.showOptimizationTips();

      // Get optimized options
      final options = RazorpayWebViewOptimizer.getOptimizedRazorpayOptions(
        keyId: keyId,
        amountInPaise: amountInPaise,
        orderId: orderId,
        phone: phone,
        email: email,
        name: name,
        driverId: driverId,
        planType: planType,
      );

      // Wait for WebView to be ready (non-blocking)
      if (!RazorpayWebViewOptimizer.isWebViewReady()) {
        print('⏳ WebView not ready, waiting...');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Open Razorpay with optimized settings
      _razorpay.open(options);
      print('✅ Razorpay payment gateway opened with optimization');
    } catch (e) {
      print('❌ Failed to open payment gateway: $e');
      isProcessing.value = false;

      // Fallback to UPI if available
      _handlePaymentGatewayError(e, planType);
    }
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅ Payment successful: ${response.paymentId}');
    isProcessing.value = false;

    if (onPaymentSuccess != null) {
      onPaymentSuccess!(response);
    }

    // Clean up
    _cleanup();
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment failed: ${response.code} - ${response.message}');
    isProcessing.value = false;

    if (onPaymentError != null) {
      onPaymentError!(response);
    }

    // Clean up
    _cleanup();
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🔗 External wallet selected: ${response.walletName}');
    isProcessing.value = false;

    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }

    // Clean up
    _cleanup();
  }

  /// Handle payment gateway errors
  void _handlePaymentGatewayError(dynamic error, String planType) {
    final errorStr = error.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (errorStr.contains('Invalid argument') ||
          errorStr.contains('Closure')) {
        Get.snackbar(
          '❌ Payment Error',
          'Gateway configuration issue. Try UPI payment.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          '❌ WebView Error',
          'Payment gateway loading issue. Please try again.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  /// Clean up resources
  void _cleanup() {
    onPaymentSuccess = null;
    onPaymentError = null;
    onExternalWallet = null;

    // Optimize WebView memory
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RazorpayWebViewOptimizer.optimizeWebViewMemory();
    });
  }

  /// Clear Razorpay instance
  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
