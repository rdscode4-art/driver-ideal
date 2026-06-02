import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rideal_driver/models/non_vehicle_subscription_status.dart';
import 'package:rideal_driver/subscriptionrepository.dart';
import '../models/subscription_status_model.dart';
import '../services/subscription_service.dart';
import '../core/token_manager.dart';
import '../core/storage_helper.dart';
import '../core/utils/app_snackbar.dart';

class SSubscriptionController extends GetxController {
  static SSubscriptionController get instance => Get.find();

  // Services
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SubscriptionRepository _repository = SubscriptionRepository();
  final TokenManager _tokenManager = Get.find<TokenManager>();

  // Razorpay
  static const String _razorpayKeyId = 'rzp_live_RoLpvsh1Qs9Cfs';
  late Razorpay _razorpay;

  // Observable variables
  final RxList<SubscriptionPlan> availablePlans = <SubscriptionPlan>[].obs;
  final RxBool isLoadingPlans = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final Rxn<SubscriptionStatusModel> activeSubscription = Rxn<SubscriptionStatusModel>();
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;
  final RxString selectedPlanId = ''.obs;

  // Payment tracking
  SubscriptionPlan? _currentPlan;
  Rx<String?> paymentId = Rx<String?>(null);
  Rx<String?> orderId = Rx<String?>(null);
  Rx<String?> signature = Rx<String?>(null);

  // Getter for driver ID
  String? get driverId => _tokenManager.driverId;

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();
    fetchSubscriptionStatus();
    fetchAvailablePlans();
  }

  /// Initialize Razorpay
  void _initializeRazorpay() {
    print('🚀 Initializing Razorpay...');
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    print('✅ Razorpay initialized');
  }

  /// Fetch available subscription plans
  Future<void> fetchAvailablePlans() async {
    try {
      print('📋 Fetching available plans...');
      isLoadingPlans.value = true;
      
      final response = await _repository.getSubscriptionPlans();
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> plansData = response['data'];
        availablePlans.value = plansData
            .map((plan) => SubscriptionPlan.fromJson(plan))
            .toList();
        
        print('✅ Loaded ${availablePlans.length} plans');
        for (var plan in availablePlans) {
          print('   📦 ${plan.title} - ${plan.formattedPrice}');
        }
      } else {
        throw Exception('Failed to load plans');
      }
    } catch (e) {
      print('❌ Error fetching plans: $e');
      _showError('Failed to load subscription plans');
      _createDefaultPlans();
    } finally {
      isLoadingPlans.value = false;
    }
  }

  /// Create default fallback plans
  void _createDefaultPlans() {
    availablePlans.value = [
      SubscriptionPlan(
        id: 'pookie_plan',
        title: 'Pookie Plan',
        rate: 1,
        durationInMonths: 3,
      ),
      SubscriptionPlan(
        id: 'premium_plan',
        title: 'Premium Plan',
        rate: 250,
        durationInMonths: 3,
      ),
    ];
    print('📦 Created fallback plans');
  }

  /// Fetch subscription status from API
  Future<void> fetchSubscriptionStatus() async {
    try {
      if (driverId == null || driverId!.isEmpty) {
        print('⚠️ Driver ID not found');
        _showError('Driver ID not found. Please login again.');
        return;
      }

      print('📡 Checking subscription for driver: $driverId');
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final subscription = await _subscriptionService.fetchSubscriptionStatus(driverId!);

      if (subscription != null && subscription.isActive) {
        activeSubscription.value = subscription;
        print('✅ Subscription active: ${subscription.planName}');
        
        // Silent status update
      } else {
        activeSubscription.value = null;
        print('❌ No active subscription');
      }
    } catch (e) {
      print('❌ Error fetching subscription: $e');
      _showError(e.toString());
      activeSubscription.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Buy subscription with Razorpay
  Future<void> buySubscription(SubscriptionPlan plan) async {
    try {
      if (driverId == null || driverId!.isEmpty) {
        _showError('Driver ID not found. Please login again.');
        return;
      }

      print('\n💳 ===== BUYING SUBSCRIPTION =====');
      print('📦 Plan: ${plan.title}');
      print('💰 Amount: ₹${plan.rate}');
      print('👤 Driver: $driverId');

      isProcessingPayment.value = true;
      selectedPlanId.value = plan.id;
      _currentPlan = plan;

      // Create order with backend
      print('📡 Creating Razorpay order...');
      final response = await _repository.buySubscription(
        driverId!,
        plan.id,
        planType: plan.title,
        amount: plan.rate * 100, // Convert to paise
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to create order');
      }

      final orderIdValue = response['orderId']?.toString() ?? '';
      final amountInPaise = response['amount'] as int? ?? 0;

      print('✅ Order created: $orderIdValue');
      orderId.value = orderIdValue;

      // Get driver details
      final phone = await _getDriverPhone();
      final email = await _getDriverEmail();
      final name = await _getDriverName();

      // Razorpay options
      var options = {
        'key': _razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'order_id': orderIdValue,
        'name': 'RiDeal Driver',
        'description': '${plan.title} Subscription',
        'prefill': {
          'contact': phone,
          'email': email,
          'name': name,
        },
        'theme': {'color': '#FF6B35'},
        'notes': {
          'driver_id': driverId,
          'plan_id': plan.id,
        },
      };

      print('🚀 Opening Razorpay checkout...');
      _razorpay.open(options);

    } catch (e) {
      print('❌ Error: $e');
      isProcessingPayment.value = false;
      selectedPlanId.value = '';
      _currentPlan = null;
      _showError('Payment initiation failed: $e');
    }
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('\n🎉 ===== PAYMENT SUCCESS =====');
    print('💳 Payment ID: ${response.paymentId}');
    print('📋 Order ID: ${response.orderId}');
    
    paymentId.value = response.paymentId;
    orderId.value = response.orderId;
    signature.value = response.signature;

    showInfoSnackBar(
      'Verifying payment...',
      title: '🎉 Payment Successful!',
    );

    _verifyPayment();
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('\n❌ ===== PAYMENT FAILED =====');
    print('🚫 Error: ${response.message}');
    
    isProcessingPayment.value = false;
    selectedPlanId.value = '';
    _currentPlan = null;

    showErrorSnackBar(
      response.message ?? 'Payment was cancelled or failed',
      title: '❌ Payment Failed',
    );
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🏦 External wallet: ${response.walletName}');
    showInfoSnackBar(
      'Opening ${response.walletName}...',
      title: '🏦 External Wallet',
    );
  }

  /// Verify payment with backend
  Future<void> _verifyPayment() async {
    try {
      print('🔍 Verifying payment...');

      final response = await _repository.verifyPayment(
        driverId: driverId!,
        planId: selectedPlanId.value,
        razorpayPaymentId: paymentId.value!,
        razorpayOrderId: orderId.value!,
        razorpaySignature: signature.value!,
      );

      if (response['success'] == true) {
        print('✅ Payment verified!');

        showSuccessSnackBar(
          'Your subscription is now active!',
          title: '🎉 Subscription Activated!',
        );

        // Refresh subscription status
        await fetchSubscriptionStatus();
      } else {
        throw Exception(response['message'] ?? 'Verification failed');
      }
    } catch (e) {
      print('❌ Verification failed: $e');
      _showError('Payment verification failed: $e');
    } finally {
      isProcessingPayment.value = false;
      selectedPlanId.value = '';
      _currentPlan = null;
    }
  }

  /// Helper methods
  Future<String> _getDriverPhone() async {
    return await StorageHelper.getDriverPhone() ?? '9999999999';
  }

  Future<String> _getDriverEmail() async {
    return await StorageHelper.getDriverEmail() ?? 'driver@rideal.app';
  }

  Future<String> _getDriverName() async {
    return await StorageHelper.getDriverName() ?? 'Driver';
  }

  /// Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    print('🔄 Refreshing...');
    await fetchSubscriptionStatus();
  }

  /// Check if user has active subscription
  bool get hasActiveSubscription {
    final subscription = activeSubscription.value;
    return subscription != null && subscription.isActive;
  }

  /// Show error message
  void _showError(String message) {
    hasError.value = true;
    errorMessage.value = message;

    showErrorSnackBar(
      message,
      title: '❌ Error',
    );
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}