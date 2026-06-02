import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/rideal_subscription_service.dart';
import '../models/rideal_subscription_models.dart';
import '../core/storage_helper.dart';
import '../core/utils/app_snackbar.dart';

/// Complete Production-Ready Subscription Controller
/// Handles full Razorpay payment flow for non-vehicle drivers
class RidealSubscriptionController extends GetxController {
  late Razorpay _razorpay;

  // Observable variables for reactive UI
  var subscriptionStatus = Rxn<RidealSubscriptionStatus>();
  var availablePlans = <RidealSubscriptionPlan>[].obs;
  var isLoading = false.obs;
  var isCreatingOrder = false.obs;
  var isVerifyingPayment = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Current payment tracking
  var currentPlanId = ''.obs;
  var currentOrderId = ''.obs;
  var currentAmount = 0.obs;

  // Driver info cache
  String? _cachedDriverId;
  String? _cachedDriverName;
  String? _cachedDriverPhone;
  String? _cachedDriverEmail;

  @override
  void onInit() {
    super.onInit();
    print('🔄 RidealSubscriptionController initialized');
    _initializeRazorpay();
    _loadDriverInfo();
    loadSubscriptionStatus();
    _loadAvailablePlans();
  }

  @override
  void onClose() {
    print('🧹 Cleaning up RidealSubscriptionController');
    _razorpay.clear();
    super.onClose();
  }

  /// Initialize Razorpay SDK with event handlers
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

  /// Load driver information from storage
  Future<void> _loadDriverInfo() async {
    try {
      _cachedDriverId = await StorageHelper.getDriverId();
      // Get driver profile data if available
      final profileData = await StorageHelper.getDriverProfile();
      if (profileData != null) {
        _cachedDriverName = profileData['name'] ?? 'Driver';
        _cachedDriverPhone = profileData['phone'] ?? '9999999999';
        _cachedDriverEmail = profileData['email'] ?? 'driver@rideal.com';
      }
      print('👤 Driver info loaded: $_cachedDriverId');
    } catch (e) {
      print('⚠️ Failed to load driver info: $e');
    }
  }

  /// Load available subscription plans
  void _loadAvailablePlans() {
    // Load plans that match your UI exactly
    availablePlans.value = [
      RidealSubscriptionPlan(
        id: '68ede14b0efa19665b81303e', // Pookie Plan ID from your backend
        title: 'Pookie plan',
        rate: 1,
        durationInMonths: 3,
        isPopular: true,
        description: 'Special promotional plan',
        features: [
          'Unlimited ride requests',
          '24/7 Priority support',
          'Valid for 3 months',
          'Secure payment gateway',
        ],
      ),
      RidealSubscriptionPlan(
        id: 'premium_plan_id',
        title: 'Premium Plan',
        rate: 299,
        durationInMonths: 3,
        features: [
          'Unlimited ride requests',
          'Priority booking',
          'Premium support',
          '3 months validity',
        ],
      ),
    ];
    print('📋 Loaded ${availablePlans.length} subscription plans');
  }

  /// 🔄 STEP 1: Load subscription status from backend
  Future<void> loadSubscriptionStatus() async {
    if (_cachedDriverId == null) {
      await _loadDriverInfo();
      if (_cachedDriverId == null) {
        print('❌ No driver ID found');
        _showError('Driver not logged in');
        return;
      }
    }

    try {
      isLoading.value = true;
      hasError.value = false;

      print('🔍 Loading subscription status for driver: $_cachedDriverId');
      final response = await RidealSubscriptionService.getSubscriptionStatus(
        _cachedDriverId!,
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
      subscriptionStatus.value = RidealSubscriptionStatus.empty();
    } finally {
      isLoading.value = false;
    }
  }

  /// 💳 STEP 2: Start complete subscription purchase flow
  Future<void> buySubscription(RidealSubscriptionPlan plan) async {
    if (_cachedDriverId == null) {
      _showError('Driver ID not found. Please login again.');
      return;
    }

    try {
      print('🛒 Starting purchase for plan: ${plan.title} (₹${plan.rate})');

      // Step 2.1: Create Razorpay order
      await _createRazorpayOrder(plan);
    } catch (e) {
      print('🔴 Error in buySubscription: $e');
      _showError('Failed to start payment: $e');
      _resetPaymentState();
    }
  }

  /// 📋 STEP 2.1: Create Razorpay order using your exact API
  Future<void> _createRazorpayOrder(RidealSubscriptionPlan plan) async {
    try {
      isCreatingOrder.value = true;
      _showLoadingDialog('Creating order...');

      print('💳 Creating order for plan: ${plan.title}');
      final response = await RidealSubscriptionService.createOrder(
        driverId: _cachedDriverId!,
        planId: plan.id,
        amount: plan.rate,
      );

      Get.back(); // Close loading dialog

      if (response['success'] == true) {
        final data = response['data'];
        final orderId = data['orderId'];
        final amount = data['amount'];

        if (orderId == null) {
          throw Exception('Order ID not received from backend');
        }

        // Store payment details for verification
        currentPlanId.value = plan.id;
        currentOrderId.value = orderId;
        currentAmount.value = amount ?? plan.rate;

        print('✅ Order created successfully: $orderId');

        // Step 2.2: Open Razorpay payment
        await _openRazorpayPayment(plan, orderId);
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

  /// 📱 STEP 2.2: Open Razorpay payment with exact options
  Future<void> _openRazorpayPayment(
    RidealSubscriptionPlan plan,
    String orderId,
  ) async {
    try {
      print('📱 Opening Razorpay payment for order: $orderId');

      final options = {
        'key': 'rzp_live_RoLpvsh1Qs9Cfs', // 🔧 REPLACE WITH YOUR ACTUAL KEY
        'amount': plan.rate * 100, // Convert to paise
        'currency': 'INR',
        'name': 'RiDeal',
        'description': 'Subscription: ${plan.title}',
        'order_id': orderId,
        'prefill': {
          'contact': _cachedDriverPhone ?? '9999999999',
          'email': _cachedDriverEmail ?? 'driver@rideal.com',
          'name': _cachedDriverName ?? 'Driver',
        },
        'theme': {
          'color': '#FF6B35', // Orange color from your UI
        },
        'retry': {'enabled': true, 'max_count': 3},
      };

      print('🚀 Opening Razorpay with options: $options');
      _razorpay.open(options);
    } catch (e) {
      print('🔴 Error opening Razorpay: $e');
      throw Exception('Failed to open payment: $e');
    }
  }

  /// ✅ STEP 3: Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('🟢 Payment Success: ${response.paymentId}');
    print('🟢 Order ID: ${response.orderId}');
    print('🟢 Signature: ${response.signature}');

    // Step 3.1: Verify payment with backend
    _verifyPaymentWithBackend(
      paymentId: response.paymentId!,
      orderId: response.orderId!,
      signature: response.signature!,
    );
  }

  /// 🔴 STEP 3: Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) {
    print('🔴 Payment Failed: ${response.code} - ${response.message}');

    _resetPaymentState();

    // Show user-friendly error message
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Payment Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error: ${response.message ?? 'Payment was cancelled'}'),
            const SizedBox(height: 8),
            Text(
              'Error Code: ${response.code ?? 'Unknown'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// 📱 Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('📱 External Wallet: ${response.walletName}');
    _showError('External wallet payments are not supported currently');
    _resetPaymentState();
  }

  /// ✅ STEP 4: Verify payment with your backend
  Future<void> _verifyPaymentWithBackend({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      isVerifyingPayment.value = true;
      _showLoadingDialog('Verifying payment...');

      print('🔍 Verifying payment: $paymentId');

      final response = await RidealSubscriptionService.verifyPayment(
        driverId: _cachedDriverId!,
        planId: currentPlanId.value,
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
      );

      Get.back(); // Close loading dialog

      if (response['success'] == true) {
        print('✅ Payment verified successfully');

        // Show success message
        _showSuccessDialog();

        // STEP 5: Refresh subscription status to update UI
        await _refreshSubscriptionAfterPayment();
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
    } finally {
      isVerifyingPayment.value = false;
      _resetPaymentState();
    }
  }

  /// 🔄 STEP 5: Refresh subscription status after successful payment
  Future<void> _refreshSubscriptionAfterPayment() async {
    print('🔄 Refreshing subscription status after payment...');

    // Wait a bit for backend to process
    await Future.delayed(const Duration(seconds: 2));

    // Reload subscription status
    await loadSubscriptionStatus();

    // Verify the subscription is now active
    if (subscriptionStatus.value?.isActive == true) {
      print('🎉 Subscription successfully activated!');
      _showSuccess('Subscription activated successfully!');
    } else {
      print('⚠️ Subscription not yet active, retrying...');
      // Retry once more after another delay
      await Future.delayed(const Duration(seconds: 3));
      await loadSubscriptionStatus();
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
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Show payment success dialog
  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('Payment Successful!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your subscription has been activated successfully.'),
            SizedBox(height: 8),
            Text('You can now access all premium features.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  /// Show error message
  void _showError(String message) {
    showErrorSnackBar(message, title: 'Error');
  }

  /// Show success message
  void _showSuccess(String message) {
    showSuccessSnackBar(message, title: 'Success');
  }

  /// Handle authentication errors (401)
  void _handleAuthError() {
    // Get.snackbar(
    //   'Session Expired',
    //   'Please login again to continue.',
    //   backgroundColor: Colors.orange[100],
    //   colorText: Colors.orange[800],
    //   icon: Icon(Icons.warning, color: Colors.orange[600]),
    //   duration: const Duration(seconds: 3),
    // );

    // Clear auth data and navigate to login
    StorageHelper.clearAuthToken();
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed('/nonvehiclelogin');
    });
  }

  /// Reset payment state
  void _resetPaymentState() {
    currentPlanId.value = '';
    currentOrderId.value = '';
    currentAmount.value = 0;
  }

  /// Refresh subscription status (for pull-to-refresh)
  Future<void> refreshSubscriptionStatus() async {
    await loadSubscriptionStatus();
  }

  /// Check if user has active subscription
  bool get hasActiveSubscription {
    return subscriptionStatus.value?.isActive ?? false;
  }

  /// Get current subscription display info
  Map<String, String> get subscriptionDisplayInfo {
    final status = subscriptionStatus.value;
    if (status == null || !status.isActive) {
      return {
        'title': 'No Active Subscription',
        'subtitle': 'Select a plan below to get started.',
        'status': 'inactive',
      };
    }

    return {
      'title': status.displayTitle,
      'subtitle': status.displaySubtitle,
      'status': 'active',
      'plan': status.plan?.title ?? '',
      'amount': '₹${status.plan?.rate ?? 0}',
      'duration': status.plan?.formattedDuration ?? '',
      'daysLeft': '${status.daysRemaining} days',
    };
  }
}
