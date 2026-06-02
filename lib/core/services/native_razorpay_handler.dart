import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class NativeRazorpayHandler {
  static Razorpay? _razorpay;
  static bool _isInitialized = false;

  // External callback functions
  static Function(PaymentSuccessResponse)? _externalOnSuccess;
  static Function(PaymentFailureResponse)? _externalOnError;
  static Function(ExternalWalletResponse)? _externalOnWallet;

  // 🔍 Debugging: Track event registrations
  static int _eventRegistrationCount = 0;
  static DateTime? _lastEventTime;
  static String? _lastEventType;

  /// Set external callbacks for payment events
  static void setExternalCallbacks({
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onError,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    print('\n📞 ════════════════════════════════════════════════════════');
    print('📞           SETTING EXTERNAL CALLBACKS');
    print('📞 ════════════════════════════════════════════════════════');

    _externalOnSuccess = onSuccess;
    _externalOnError = onError;
    _externalOnWallet = onWallet;

    print('✅ Success Callback: ${onSuccess != null ? "SET" : "NULL"}');
    print('❌ Error Callback: ${onError != null ? "SET" : "NULL"}');
    print('🏦 Wallet Callback: ${onWallet != null ? "SET" : "NULL"}');
    print('🔗 Status: External callbacks configured');
    print('⚠️ CRITICAL: Callbacks must be set BEFORE opening checkout');
    print('📞 ════════════════════════════════════════════════════════\n');
  }

  /// Initialize Native Razorpay (NO WebView dependencies)
  static void initializeNativeRazorpay() {
    if (_isInitialized) return;

    try {
      print('\n🚀 ═══════════════════════════════════════');
      print('🚀 INITIALIZING NATIVE RAZORPAY');
      print('🚀 ═══════════════════════════════════════');
      print('📱 Mode: Native (WebView-free)');
      print('🔧 Creating Razorpay instance...');

      _razorpay = Razorpay();

      print('🎯 Setting up event handlers...');

      // Clear any existing handlers first
      try {
        _razorpay!.clear();
        print('🧹 Cleared existing handlers');
      } catch (e) {
        print('ℹ️ No existing handlers to clear: $e');
      }

      // Set up event handlers (required for Razorpay to work)
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _eventRegistrationCount++;
      print('   ✅ Success handler registered (#$_eventRegistrationCount)');

      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _eventRegistrationCount++;
      print('   ❌ Error handler registered (#$_eventRegistrationCount)');

      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _eventRegistrationCount++;
      print('   🏦 Wallet handler registered (#$_eventRegistrationCount)');

      // 🔍 DEBUGGING: Add listener to verify event system is working
      print('🔍 Event system verification:');
      print('   Razorpay instance: ${_razorpay.hashCode}');
      print('   Total event handlers: $_eventRegistrationCount');
      print('   External callback status:');
      print('     - Success: ${_externalOnSuccess != null ? "SET" : "NULL"}');
      print('     - Error: ${_externalOnError != null ? "SET" : "NULL"}');
      print('     - Wallet: ${_externalOnWallet != null ? "SET" : "NULL"}');

      // 🔍 Test event constants
      print('🔍 Razorpay Event Constants:');
      print('   SUCCESS: "${Razorpay.EVENT_PAYMENT_SUCCESS}"');
      print('   ERROR: "${Razorpay.EVENT_PAYMENT_ERROR}"');
      print('   WALLET: "${Razorpay.EVENT_EXTERNAL_WALLET}"');

      _isInitialized = true;

      print('✅ Status: Native Razorpay ready!');
      print('🎯 Benefit: NO WebView/GPU issues!');
      print('🚀 ═══════════════════════════════════════\n');
    } catch (e) {
      print('❌ Native Razorpay initialization error: $e');
    }
  }

  /// Handle payment success with detailed response processing
  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _lastEventTime = DateTime.now();
    _lastEventType = 'PAYMENT_SUCCESS';

    print('\n🔊 ══════════════ RAZORPAY EVENT RECEIVED! ══════════════');
    print('🔊 EVENT TYPE: PAYMENT_SUCCESS');
    print('🔊 Handler: _handlePaymentSuccess called');
    print('🔊 Event Time: ${_lastEventTime!.toIso8601String()}');
    print('🔊 Event Count: $_eventRegistrationCount handlers registered');
    print('🔊 ═════════════════════════════════════════════════════════\n');

    print('\n🎉 ════════════════════════════════════════════════════════');
    print('🎉                RAZORPAY PAYMENT SUCCESS!');
    print('🎉 ════════════════════════════════════════════════════════');
    print('💳 Payment ID: ${response.paymentId}');
    print('📋 Order ID: ${response.orderId}');
    print('💰 Signature: ${response.signature}');
    print('⏰ Success Time: ${DateTime.now().toIso8601String()}');
    print('🔐 Payment Status: COMPLETED');
    print('✅ Razorpay Response: SUCCESS');
    print('🎯 Next Action: Verify payment signature with backend');
    print('🎉 ════════════════════════════════════════════════════════\n');

    // CRITICAL: Always call external callback first (main handler)
    if (_externalOnSuccess != null) {
      print('🔄 Calling external success handler...');
      try {
        _externalOnSuccess!(response);
        print('✅ External success handler completed');
      } catch (e) {
        print('❌ External success handler error: $e');
      }
    } else {
      print('⚠️ NO external success handler set - using default UI');
      // Default UI feedback
      Get.snackbar(
        '🎉 Payment Successful!',
        'Payment ID: ${response.paymentId}\nVerifying with server...',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    }
  }

  /// Handle payment error
  static void _handlePaymentError(PaymentFailureResponse response) {
    _lastEventTime = DateTime.now();
    _lastEventType = 'PAYMENT_ERROR';

    print('\n🔊 ══════════════ RAZORPAY EVENT RECEIVED! ══════════════');
    print('🔊 EVENT TYPE: PAYMENT_ERROR');
    print('🔊 Handler: _handlePaymentError called');
    print('🔊 Event Time: ${_lastEventTime!.toIso8601String()}');
    print('🔊 Event Count: $_eventRegistrationCount handlers registered');
    print('🔊 ═════════════════════════════════════════════════════════\n');

    print('\n❌ ═══════════════════════════════════════');
    print('❌ RAZORPAY PAYMENT FAILED!');
    print('❌ ═══════════════════════════════════════');
    print('🚫 Error Code: ${response.code}');
    print('📝 Error Message: ${response.message}');
    print('⏰ Failure Time: ${DateTime.now().toIso8601String()}');
    print('🔍 Error Details: ${response.error}');
    print('💡 User Action Required: Check payment method and retry');
    print('❌ ═══════════════════════════════════════\n');

    // CRITICAL: Always call external callback first (main handler)
    if (_externalOnError != null) {
      print('🔄 Calling external error handler...');
      try {
        _externalOnError!(response);
        print('✅ External error handler completed');
      } catch (e) {
        print('❌ External error handler error: $e');
      }
    } else {
      print('⚠️ NO external error handler set - using default UI');
      Get.snackbar(
        '❌ Payment Failed',
        'Error: ${response.message}\nCode: ${response.code}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 8),
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Handle external wallet
  static void _handleExternalWallet(ExternalWalletResponse response) {
    _lastEventTime = DateTime.now();
    _lastEventType = 'EXTERNAL_WALLET';

    print('\n🔊 ══════════════ RAZORPAY EVENT RECEIVED! ══════════════');
    print('🔊 EVENT TYPE: EXTERNAL_WALLET');
    print('🔊 Handler: _handleExternalWallet called');
    print('🔊 Event Time: ${_lastEventTime!.toIso8601String()}');
    print('🔊 Event Count: $_eventRegistrationCount handlers registered');
    print('🔊 ═════════════════════════════════════════════════════════\n');

    print('\n🏦 ═══════════════════════════════════════');
    print('🏦 EXTERNAL WALLET SELECTED!');
    print('🏦 ═══════════════════════════════════════');
    print('💳 Wallet Name: ${response.walletName}');
    print('⏰ Selection Time: ${DateTime.now().toIso8601String()}');
    print('🎯 Action: Redirecting to wallet app');
    print('🏦 ═══════════════════════════════════════\n');

    // CRITICAL: Always call external callback first (main handler)
    if (_externalOnWallet != null) {
      print('🔄 Calling external wallet handler...');
      try {
        _externalOnWallet!(response);
        print('✅ External wallet handler completed');
      } catch (e) {
        print('❌ External wallet handler error: $e');
      }
    } else {
      print('⚠️ NO external wallet handler set - using default UI');
      Get.snackbar(
        '🏦 External Wallet Selected',
        'Redirecting to ${response.walletName}...',
        backgroundColor: Colors.blue[100],
        colorText: Colors.blue[800],
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.account_balance_wallet, color: Colors.blue),
      );
    }
  }

  /// Open checkout with comprehensive options
  static Future<Map<String, dynamic>> openNativeCheckout({
    required String keyId,
    required int amountInPaise,
    required String orderId,
    required String phone,
    required String email,
    required String name,
    String description = 'RiDeal Driver Payment',
  }) async {
    try {
      // Initialize if not done
      initializeNativeRazorpay();

      if (_razorpay == null) {
        throw Exception('Native Razorpay not initialized');
      }

      // Check if test mode (key starts with rzp_test_)
      bool isTestMode = keyId.startsWith('rzp_test_');

      print('\n💳 ════════════════════════════════════════════════════════');
      print('💳                OPENING RAZORPAY CHECKOUT');
      print('💳 ════════════════════════════════════════════════════════');
      print('🧪 Test Mode: $isTestMode');
      print('🔑 Razorpay Key: $keyId');
      print(
        '💰 Amount: $amountInPaise paise (₹${(amountInPaise / 100).toStringAsFixed(2)})',
      );
      print('📋 Order ID: $orderId');
      print('📞 Phone: $phone');
      print('📧 Email: $email');
      print('👤 Name: $name');
      print('📝 Description: $description');
      print('⏰ Checkout Time: ${DateTime.now().toIso8601String()}');
      if (isTestMode) {
        print('🎯 Method: Test Mode (UPI disabled, Cards/Wallets enabled)');
        print('💡 Use test card: 4111 1111 1111 1111');
      } else {
        print('🎯 Method: Live Mode (All payment methods enabled)');
      }
      print('💳 ════════════════════════════════════════════════════════\n');

      // Create Razorpay options with test mode compatibility
      final options = {
        'key': keyId,
        'amount': amountInPaise,
        'name': 'RiDeal Driver',
        'description': description,
        'order_id': orderId,
        'prefill': {'contact': phone, 'email': email, 'name': name},
        'theme': {'color': '#FF5722'},
        // 🔥 PERFECT FIX: Test mode compatibility
        'method': isTestMode
            ? {
                'upi': false, // ❌ UPI fails in test mode
                'card': true, // ✅ Cards work in test mode
                'netbanking': true, // ✅ Net banking works
                'wallet': true, // ✅ Wallets work
              }
            : {
                'upi': true, // ✅ UPI works in live mode
                'card': true, // ✅ All methods in live
                'netbanking': true,
                'wallet': true,
              },
        'retry': {
          'enabled': false, // Disable retry to prevent loops
        },
      };

      // 🔍 DEBUGGING: Pre-open verification
      print('\n🔍 ═══ PRE-OPEN VERIFICATION ═══');
      print('🔍 Razorpay instance ready: ${_razorpay != null}');
      print('🔍 External callbacks status:');
      print('   Success: ${_externalOnSuccess != null ? "READY" : "MISSING"}');
      print('   Error: ${_externalOnError != null ? "READY" : "MISSING"}');
      print('   Wallet: ${_externalOnWallet != null ? "READY" : "MISSING"}');
      print('🔍 About to call _razorpay.open()...');

      // Open Razorpay checkout with appropriate method
      _razorpay!.open(options);

      print('🔍 _razorpay.open() called successfully');
      print('🔍 ═══ POST-OPEN STATUS ═══\n');

      if (isTestMode) {
        print('✅ Test Mode Razorpay opened');
        print('🧪 Available: Cards, NetBanking, Wallets');
        print('❌ UPI disabled (test mode limitation)');
        print('💡 Use test card: 4111 1111 1111 1111');
      } else {
        print('✅ Live Mode Razorpay opened');
        print('🎯 All payment methods available');
        print('📱 UPI apps will open directly');
      }
      print('⏳ Waiting for payment completion...');
      print('🔍 Event handlers are listening for:');
      print('   - ${Razorpay.EVENT_PAYMENT_SUCCESS}');
      print('   - ${Razorpay.EVENT_PAYMENT_ERROR}');
      print('   - ${Razorpay.EVENT_EXTERNAL_WALLET}');
      print('✅ ══════════════════════════════════════════════════════\n');

      return {
        'success': true,
        'message': 'Native Razorpay checkout opened successfully',
        'method': 'native',
      };
    } catch (e) {
      print('❌ Native Razorpay error: $e');
      return {
        'success': false,
        'error': 'Native checkout failed',
        'details': e.toString(),
      };
    }
  }

  /// Handle payment success (native)
  static void onPaymentSuccess(Function(PaymentSuccessResponse) callback) {
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, callback);
  }

  /// Handle payment error (native)
  static void onPaymentError(Function(PaymentFailureResponse) callback) {
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, callback);
  }

  /// Handle external wallet (native)
  static void onExternalWallet(Function(ExternalWalletResponse) callback) {
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, callback);
  }

  /// Cleanup native Razorpay
  static void cleanup() {
    try {
      _razorpay?.clear();
      _razorpay = null;
      _isInitialized = false;
      print('🧹 Native Razorpay cleaned up');
    } catch (e) {
      print('⚠️ Cleanup error: $e');
    }
  }

  /// Check if native Razorpay is available
  static bool isNativeRazorpayAvailable() {
    return _isInitialized && _razorpay != null;
  }

  /// Get event debugging information
  static Map<String, dynamic> getEventDebugInfo() {
    return {
      'initialized': _isInitialized,
      'razorpay_instance': _razorpay?.hashCode ?? 'null',
      'event_registrations': _eventRegistrationCount,
      'last_event_time': _lastEventTime?.toIso8601String() ?? 'never',
      'last_event_type': _lastEventType ?? 'none',
      'external_callbacks': {
        'success': _externalOnSuccess != null,
        'error': _externalOnError != null,
        'wallet': _externalOnWallet != null,
      },
    };
  }

  /// Print comprehensive debugging information
  static void printDebugInfo() {
    final info = getEventDebugInfo();
    print('\n🔍 ════════════════════════════════════════════════════════');
    print('🔍           RAZORPAY DEBUG INFORMATION');
    print('🔍 ════════════════════════════════════════════════════════');
    print('🔍 Initialized: ${info['initialized']}');
    print('🔍 Razorpay Instance: ${info['razorpay_instance']}');
    print('🔍 Event Registrations: ${info['event_registrations']}');
    print('🔍 Last Event Time: ${info['last_event_time']}');
    print('🔍 Last Event Type: ${info['last_event_type']}');
    print('🔍 External Callbacks:');
    final callbacks = info['external_callbacks'] as Map<String, dynamic>;
    callbacks.forEach((key, value) {
      print('🔍   $key: ${value ? "SET ✅" : "MISSING ❌"}');
    });
    print('🔍 ════════════════════════════════════════════════════════\n');
  }
}
