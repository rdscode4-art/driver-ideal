import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/rideal_subscription_models.dart';
import '../services/rideal_subscription_service.dart';
import '../core/storage_helper.dart';
import '../core/utils/app_snackbar.dart';

class ProductionSubscriptionController extends GetxController {
  late Razorpay _razorpay;

  // Observable variables
  var subscriptionStatus = Rxn<RidealSubscriptionStatus>();
  var subscriptionPlans = <RidealSubscriptionPlan>[].obs;
  var isLoading = false.obs;
  var isCreatingOrder = false.obs;
  var isVerifyingPayment = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Current payment details
  var currentPlanId = ''.obs;
  var currentOrderId = ''.obs;
  var currentAmount = 0.obs;

  // Driver ID cache
  String? _cachedDriverId;

  /// Get driver ID (async)
  Future<String?> getDriverId() async {
    if (_cachedDriverId != null) return _cachedDriverId;
    _cachedDriverId = await StorageHelper.getDriverId();
    return _cachedDriverId;
  }

  @override
  void onInit() {
    super.onInit();
    print('🔄 ProductionSubscriptionController initialized');
    _initializeRazorpay();
    loadSubscriptionStatus();
    _loadDemoPlans();
  }

  @override
  void onClose() {
    print('🧹 Cleaning up ProductionSubscriptionController');
    _razorpay.clear();
    super.onClose();
  }

  /// Initialize Razorpay
  void _initializeRazorpay() {
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      print('✅ Razorpay initialized successfully');
    } catch (e) {
      print('🔴 Failed to initialize Razorpay: $e');
      _showError('Failed to initialize payment system');
    }
  }

  /// Load demo subscription plans
  void _loadDemoPlans() {
    subscriptionPlans.value = [
      RidealSubscriptionPlan(
        id: '68ede14b0efa19665b81303e',
        title: 'Pookie Plan',
        rate: 1,
        durationInMonths: 3,
        isPopular: true,
        description: 'Special discounted plan',
      ),
      RidealSubscriptionPlan(
        id: 'demo_basic_plan',
        title: 'Basic Plan',
        rate: 99,
        durationInMonths: 1,
      ),
      RidealSubscriptionPlan(
        id: 'demo_premium_plan',
        title: 'Premium Plan',
        rate: 250,
        durationInMonths: 3,
      ),
      RidealSubscriptionPlan(
        id: 'demo_pro_plan',
        title: 'Pro Plan',
        rate: 499,
        durationInMonths: 6,
      ),
    ];
    print('📋 Loaded ${subscriptionPlans.length} demo plans');
  }

  /// Load subscription status from API
  Future<void> loadSubscriptionStatus() async {
    final driverId = await getDriverId();

    if (driverId == null) {
      print('❌ No driver ID found');
      return;
    }

    try {
      isLoading.value = true;
      hasError.value = false;

      print('🔍 Loading subscription status for driver: $driverId');
      final response = await RidealSubscriptionService.getSubscriptionStatus(
        driverId,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data != null && data['subscribed'] == true) {
          subscriptionStatus.value = RidealSubscriptionStatus.fromJson(data);
          print(
            '✅ Active subscription found: ${subscriptionStatus.value?.displayTitle}',
          );
        } else {
          subscriptionStatus.value = RidealSubscriptionStatus.empty();
          print('ℹ️ No active subscription found');
        }
      } else {
        if (response['needsAuth'] == true) {
          _handleAuthError();
        } else {
          subscriptionStatus.value = RidealSubscriptionStatus.empty();
          print('⚠️ Failed to load subscription: ${response['message']}');
        }
      }
    } catch (e) {
      print('🔴 Error loading subscription status: $e');
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Start subscription purchase flow
  Future<void> buySubscription(RidealSubscriptionPlan plan) async {
    final driverId = await getDriverId();

    if (driverId == null) {
      _showError('Driver ID not found. Please login again.');
      return;
    }

    try {
      print('🛒 Starting purchase for plan: ${plan.title} (₹${plan.rate})');

      // Step 1: Create order
      await _createOrder(plan);
    } catch (e) {
      print('🔴 Error in buySubscription: $e');
      _showError('Failed to start payment: $e');
      _resetPaymentState();
    }
  }

  /// Create Razorpay order
  Future<void> _createOrder(RidealSubscriptionPlan plan) async {
    final driverId = await getDriverId();

    if (driverId == null) {
      throw Exception('Driver ID not found');
    }

    try {
      isCreatingOrder.value = true;
      _showLoadingDialog('Creating order...');

      print('💳 Creating order for plan: ${plan.title}');
      final response = await RidealSubscriptionService.createOrder(
        driverId: driverId,
        planId: plan.id,
        amount: plan.rate,
      );

      Get.back(); // Close loading dialog

      if (response['success'] == true) {
        final data = response['data'];
        final orderId = data['orderId'] ?? data['order_id'];

        if (orderId == null) {
          throw Exception('Order ID not received from server');
        }

        // Store payment details
        currentPlanId.value = plan.id;
        currentOrderId.value = orderId;
        currentAmount.value = plan.rate;

        print('✅ Order created successfully: $orderId');

        // Step 2: Start Razorpay payment
        await _startRazorpayPayment(plan, orderId);
      } else {
        if (response['needsAuth'] == true) {
          _handleAuthError();
        } else {
          throw Exception(response['message'] ?? 'Failed to create order');
        }
      }
    } catch (e) {
      Get.back(); // Close loading dialog if open
      rethrow;
    } finally {
      isCreatingOrder.value = false;
    }
  }

  /// Start Razorpay payment
  Future<void> _startRazorpayPayment(
    RidealSubscriptionPlan plan,
    String orderId,
  ) async {
    try {
      print('📱 Opening Razorpay payment for order: $orderId');

      final options = {
        'key': ' rzp_live_RoLpvsh1Qs9Cfs', // Replace with your Razorpay key
        'amount': plan.rate * 100, // Convert to paise
        'currency': 'INR',
        'name': 'RiDeal Driver',
        'description': 'Subscription: ${plan.title}',
        'order_id': orderId,
        'prefill': {
          'contact': await _getUserPhone(),
          'email': await _getUserEmail(),
        },
        'theme': {'color': '#FF7F00'},
        'retry': {'enabled': true, 'max_count': 3},
      };

      print('🚀 Opening Razorpay with options: $options');
      _razorpay.open(options);
    } catch (e) {
      print('🔴 Error opening Razorpay: $e');
      throw Exception('Failed to open payment: $e');
    }
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('🟢 Payment Success: ${response.paymentId}');

    _verifyPayment(
      paymentId: response.paymentId!,
      orderId: response.orderId!,
      signature: response.signature!,
    );
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('🔴 Payment Failed: ${response.code} - ${response.message}');

    _resetPaymentState();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(response.message ?? 'Payment was cancelled or failed'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Try Again')),
        ],
      ),
    );
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('📱 External Wallet: ${response.walletName}');
    _showError('External wallet payments are not supported');
  }

  /// Verify payment with backend
  Future<void> _verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      isVerifyingPayment.value = true;
      _showLoadingDialog('Verifying payment...');

      final driverId = await getDriverId();

      if (driverId == null) {
        throw Exception('Driver ID not found');
      }

      print('🔍 Verifying payment: $paymentId');

      final response = await RidealSubscriptionService.verifyPayment(
        driverId: driverId,
        planId: currentPlanId.value,
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
      );

      Get.back(); // Close loading dialog

      if (response['success'] == true) {
        print('✅ Payment verified successfully');

        // Show success dialog
        _showSuccessDialog();

        // Refresh subscription status
        await loadSubscriptionStatus();

        _resetPaymentState();
      } else {
        if (response['needsAuth'] == true) {
          _handleAuthError();
        } else {
          throw Exception(response['message'] ?? 'Payment verification failed');
        }
      }
    } catch (e) {
      Get.back(); // Close loading dialog if open
      print('🔴 Error verifying payment: $e');
      _showError('Payment verification failed: $e');
      _resetPaymentState();
    } finally {
      isVerifyingPayment.value = false;
    }
  }

  /// Show loading dialog
  void _showLoadingDialog(String message) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Show success dialog
  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: Text('Your subscription has been activated successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Navigate back or refresh UI
            },
            child: Text('Great!'),
          ),
        ],
      ),
    );
  }

  /// Show error message
  void _showError(String message) {
    showErrorSnackBar(message);
  }

  /// Handle authentication errors
  void _handleAuthError() {
    // Get.snackbar(
    //   'Session Expired',
    //   'Please login again to continue.',
    //   backgroundColor: Colors.orange[100],
    //   colorText: Colors.orange[800],
    //   icon: Icon(Icons.warning, color: Colors.orange),
    //   duration: Duration(seconds: 3),
    // );

    // Navigate to login after delay
    Future.delayed(Duration(seconds: 2), () {
      Get.offAllNamed('/nonvehiclelogin');
    });
  }

  /// Reset payment state
  void _resetPaymentState() {
    currentPlanId.value = '';
    currentOrderId.value = '';
    currentAmount.value = 0;
  }

  /// Get user phone from storage
  Future<String> _getUserPhone() async {
    // Implement based on your storage structure
    return '9999999999'; // Placeholder
  }

  /// Get user email from storage
  Future<String> _getUserEmail() async {
    // Implement based on your storage structure
    return 'user@example.com'; // Placeholder
  }

  /// Refresh subscription status (for pull-to-refresh)
  Future<void> refreshSubscriptionStatus() async {
    await loadSubscriptionStatus();
  }

  /// Check if subscription is active
  bool get hasActiveSubscription {
    return subscriptionStatus.value?.isActive ?? false;
  }

  /// Get subscription display status
  String get subscriptionDisplayStatus {
    final status = subscriptionStatus.value;
    if (status == null || !status.isActive) {
      return 'No Active Subscription';
    }
    return status.displayTitle;
  }

  /// Get subscription details for UI
  Map<String, String> get subscriptionDetails {
    final status = subscriptionStatus.value;
    if (status == null || !status.isActive) {
      return {
        'title': 'No Active Subscription',
        'subtitle': 'Select a plan below to get started.',
      };
    }

    return {
      'title': status.displayTitle,
      'subtitle': status.displaySubtitle,
      'startDate': 'Started: ${status.formattedStartDate}',
      'amount': status.plan != null ? '₹${status.plan!.rate}' : '',
    };
  }
}
