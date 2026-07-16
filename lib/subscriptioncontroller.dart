import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/utils/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rideal_driver/subscriptionrepository.dart';
import 'package:rideal_driver/core/storage_helper.dart';
import '../core/token_manager.dart';
import 'package:crypto/crypto.dart';
import '../services/razorpay_payment_service.dart';
import 'models/active_subscription_model.dart';
import '../controllers/earnings_controller.dart';

class SubscriptionPlan {
  final String id;
  final String title;
  final int rate;
  final int durationInMonths;
  final int durationInDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.rate,
    required this.durationInMonths,
    this.durationInDays = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      rate: json['rate'] ?? 0,
      durationInMonths: json['durationInMonths'] ?? 0,
      durationInDays: json['durationInDays'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'rate': rate,
      'durationInMonths': durationInMonths,
      'durationInDays': durationInDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted monthly rate or daily rate
  String get formattedMonthlyRate {
    if (durationInMonths > 0) {
      if (durationInMonths <= 1) {
        return '₹$rate/month';
      }
      final monthlyRate = (rate / durationInMonths).round();
      return '₹$monthlyRate/month';
    } else if (durationInDays > 0) {
      final dailyRate = (rate / durationInDays).round();
      return '₹$dailyRate/day';
    }
    return '₹$rate';
  }

  /// Get formatted duration
  String get formattedDuration {
    if (durationInMonths > 0) {
      if (durationInMonths == 1) {
        return '1 Month';
      } else if (durationInMonths == 12) {
        return '1 Year';
      } else {
        return '$durationInMonths Months';
      }
    } else if (durationInDays > 0) {
      if (durationInDays == 1) {
        return '1 Day';
      } else {
        return '$durationInDays Days';
      }
    }
    return 'Custom Duration';
  }
}

class SubscriptionModel {
  final String planId;
  final DateTime startDate;
  final DateTime endDate;

  SubscriptionModel({
    required this.planId,
    required this.startDate,
    required this.endDate,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      planId: json['planId']?.toString() ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) {
      return Duration.zero;
    }
    return endDate.difference(now);
  }
}

class SubscriptionController extends GetxController {
  static SubscriptionController get instance => Get.find();

  // Razorpay configuration - CRITICAL: Add your actual key secret
  static const String _razorpayKeyId = 'rzp_live_RoLpvsh1Qs9Cfs';

  // Test mode configuration
  static const bool _isTestMode =
      false; // Set to true for simulation, false for real Razorpay
  late Razorpay _razorpay;
  late RazorpayPaymentService _paymentService;

  // Repository and dependencies
  final SubscriptionRepository _repository = SubscriptionRepository();
  final TokenManager _tokenManager = Get.find<TokenManager>();

  // Observable variables
  RxBool isLoading = false.obs;
  RxBool isProcessingPayment = false.obs;
  RxBool hasSubscription = false.obs;
  RxList<SubscriptionPlan> subscriptionPlans = <SubscriptionPlan>[].obs;
  RxString selectedPlanId = ''.obs;
  RxString currentOrderId = ''.obs;
  Rx<String?> orderId = Rx<String?>(null);
  Rx<String?> paymentId = Rx<String?>(null);
  Rx<String?> signature = Rx<String?>(null);
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;

  // Current subscription details
  RxBool subscriptionActive = false.obs;
  Rx<DateTime?> expiryDate = Rx<DateTime?>(null);
  RxString subscriptionStatus = 'inactive'.obs;
  Rx<SubscriptionModel?> currentSubscription = Rx<SubscriptionModel?>(null);

  // Active subscription from API
  Rxn<ActiveSubscriptionModel> activeSubscription =
      Rxn<ActiveSubscriptionModel>();

  // Current plan being processed
  SubscriptionPlan? _currentPlan;

  // Alias for backward compatibility
  bool get isSubscriptionActive => subscriptionActive.value;
  String? get driverId => _tokenManager.driverId;

  @override
  void onInit() {
    super.onInit();
    print('🔍 ===== DRIVER ID CHECK =====');
    print('Driver ID: $driverId');
    print('Driver ID length: ${driverId?.length}');
    print('Is empty: ${driverId?.isEmpty}');
    print('============================');

    // Ensure we always have some plans to show
    _createDefaultPlans();

    _initializeRazorpay();
    _paymentService = RazorpayPaymentService();
    loadSubscriptionStatus();
    loadSubscriptionPlans(); // This will replace default plans if API succeeds
  }

  void _initializeRazorpay() {
    try {
      print('🚀 Initializing Razorpay for subscription payments...');

      // Clear any existing instance
      try {
        _razorpay.clear();
      } catch (e) {
        // Ignore if _razorpay is not yet initialized
      }

      _razorpay = Razorpay();

      // Set up event listeners with comprehensive debugging
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      print('✅ Razorpay initialized with event listeners');
      print('📋 Success Event: ${Razorpay.EVENT_PAYMENT_SUCCESS}');
      print('❌ Error Event: ${Razorpay.EVENT_PAYMENT_ERROR}');
      print('🏦 Wallet Event: ${Razorpay.EVENT_EXTERNAL_WALLET}');
    } catch (e) {
      print('❌ Failed to initialize Razorpay: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('\n🎉 ════════════════════════════════════════════════════════');
    print('🎉         SUBSCRIPTION PAYMENT SUCCESS!');
    print('🎉 ════════════════════════════════════════════════════════');
    print('💳 Payment ID: ${response.paymentId}');
    print('📋 Order ID: ${response.orderId}');
    print('🔐 Signature: ${response.signature}');
    print('📋 Plan: ${_currentPlan?.title ?? 'Unknown'}');
    print('💰 Amount: ₹${_currentPlan?.rate ?? 0}');
    print('⏰ Success Time: ${DateTime.now().toIso8601String()}');
    print('🎉 ════════════════════════════════════════════════════════\n');

    // IMPORTANT: Close any error dialogs that might have appeared due to redirect issues
    if (Get.isDialogOpen == true) {
      Get.back(); // Close any "Something went wrong" dialogs
    }

    // Store payment details for verification
    paymentId.value = response.paymentId;
    orderId.value = response.orderId;
    signature.value = response.signature;

    // Validate payment response
    if (response.paymentId?.isEmpty == true ||
        response.orderId?.isEmpty == true ||
        response.signature?.isEmpty == true) {
      print('❌ INVALID RAZORPAY RESPONSE - Missing Required Fields');
      showErrorSnackBar(
        'Invalid payment response received. Please try again.',
        title: 'Payment Error',
      );
      return;
    }

    // Show success message with better UI
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Flexible(child: Text('Payment Successful!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment ID: ${response.paymentId}'),
            const SizedBox(height: 8),
            Text('Order ID: ${response.orderId}'),
            const SizedBox(height: 16),
            Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(width: 12),
                Text('Verifying payment...'),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // Start payment verification
    _verifyPayment();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('\n❌ ════════════════════════════════════════════════════════');
    print('❌         SUBSCRIPTION PAYMENT FAILED!');
    print('❌ ════════════════════════════════════════════════════════');
    print('🚫 Error Code: ${response.code}');
    print('📝 Error Message: ${response.message}');
    print('⏰ Failure Time: ${DateTime.now().toIso8601String()}');
    print('❌ ════════════════════════════════════════════════════════\n');

    isProcessingPayment.value = false;

    // Close any loading dialogs
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    // Handle specific error codes
    String userMessage = response.message ?? 'Unknown payment error';
    String actionMessage = 'Try Again';

    // Common Razorpay error handling
    if (response.message?.contains('cancelled') == true ||
        response.message?.contains('user') == true) {
      userMessage = 'Payment was cancelled by you.';
      actionMessage = 'Retry Payment';
    }
    //else if (response.message?.contains('network') == true ||
    //     response.message?.contains('internet') == true) {
    //   userMessage =
    //       'Network error occurred. Please check your internet connection.';
    // }
    else if (response.message?.contains('credentials') == true ||
        response.message?.contains('key') == true) {
      userMessage =
          'Payment gateway configuration error. Please contact support.';
    }

    // Show enhanced error dialog
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment_outlined, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(child: Text('Payment Failed')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              userMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (response.code != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error Code: ${response.code}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Retry payment with same plan
              if (_currentPlan != null) {
                buySubscription(_currentPlan!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(actionMessage),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('\n🏦 ════════════════════════════════════════════════════════');
    print('🏦         EXTERNAL WALLET PAYMENT!');
    print('🏦 ════════════════════════════════════════════════════════');
    print('💳 Wallet Name: ${response.walletName}');
    print('⏰ Wallet Time: ${DateTime.now().toIso8601String()}');
    print('🏦 ════════════════════════════════════════════════════════\n');

    showSuccessSnackBar(
      'Opening ${response.walletName}...',
      title: '🏦 External Wallet',
    );
  }

  Future<void> loadSubscriptionStatus() async {
    try {
      print('📡 Checking subscription status from API...');

      if (driverId == null || driverId!.isEmpty) {
        print('⚠️ Driver ID not found, using local storage');
        await _loadFromLocalStorage();
        return;
      }

      // Call the API to get subscription status
      final response = await _repository.getSubscriptionStatus(driverId!);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final status = data['status'];

        print('📊 API Response Status: $status');

        if (status == 'active') {
          // Create ActiveSubscriptionModel from API response
          activeSubscription.value = ActiveSubscriptionModel.fromJson(data);

          subscriptionActive.value = true;
          hasSubscription.value = true;
          subscriptionStatus.value = 'active';

          // Parse expiry date
          if (data['expiry_date'] != null) {
            expiryDate.value = DateTime.parse(data['expiry_date']);
            print('✅ Subscription active until: ${expiryDate.value}');
          }

          // Save to local storage
          await _saveSubscriptionStatus(
            true,
            expiry: expiryDate.value,
            plan: _currentPlan,
          );

          print(
            '💎 Active subscription: ${activeSubscription.value?.planName} (₹${activeSubscription.value?.amount})',
          );
        } else {
          // No active subscription
          activeSubscription.value = null;
          subscriptionActive.value = false;
          hasSubscription.value = false;
          subscriptionStatus.value = status;

          print('❌ No active subscription found');
          await _clearSubscriptionData();
        }
      } else {
        print('⚠️ API call failed, falling back to local storage');
        await _loadFromLocalStorage();
      }
    } catch (e) {
      print('❌ Error loading subscription status: $e');
      await _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSubscription = prefs.getBool('subscription_active') ?? false;
      final savedExpiry = prefs.getString('subscription_expiry');

      subscriptionActive.value = savedSubscription;
      hasSubscription.value = savedSubscription;
      subscriptionStatus.value = savedSubscription ? 'active' : 'inactive';

      if (savedExpiry != null) {
        expiryDate.value = DateTime.parse(savedExpiry);

        // Check if subscription has expired
        if (expiryDate.value != null &&
            expiryDate.value!.isBefore(DateTime.now())) {
          subscriptionActive.value = false;
          hasSubscription.value = false;
          subscriptionStatus.value = 'expired';
          await _clearSubscriptionData();
        }
      }

      print('📊 Local Subscription Status: ${hasSubscription.value}');
      if (hasSubscription.value && expiryDate.value != null) {
        print('✅ Local subscription active until: ${expiryDate.value}');
      }
    } catch (e) {
      print('❌ Error loading from local storage: $e');
    }
  }

  // Replace your loadSubscriptionPlans() method with this fixed version

  Future<void> loadSubscriptionPlans() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      print('🔄 Loading subscription plans...');

      final response = await _repository.getSubscriptionPlans();

      print('🔍 Response received: ${response['success']}');
      print('🔍 Response data: ${response['data']}');

      if (response['success'] == true && response['data'] != null) {
        final plansData = response['data'];

        // ✅ CRITICAL FIX: Handle both List and Map responses
        List<dynamic> plansList;

        if (plansData is List) {
          plansList = plansData;
        } else if (plansData is Map && plansData.containsKey('plans')) {
          plansList = plansData['plans'] as List;
        } else {
          print('⚠️ Unexpected data format: ${plansData.runtimeType}');
          throw Exception('Invalid data format from API');
        }

        if (plansList.isNotEmpty) {
          subscriptionPlans.value = plansList
              .map(
                (plan) =>
                    SubscriptionPlan.fromJson(plan as Map<String, dynamic>),
              )
              .toList();

          print(
            '✅ Successfully loaded ${subscriptionPlans.length} plans from API',
          );

          // Debug: Print plan details
          for (var plan in subscriptionPlans) {
            print(
              '📋 Plan: ${plan.title} - ₹${plan.rate} for ${plan.durationInMonths} months',
            );
          }
        } else {
          print('⚠️ API returned empty plans list');
          throw Exception('No plans available');
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load plans');
      }
    } catch (e) {
      print('❌ Error loading subscription plans: $e');

      // ✅ FIX: Don't show error, use fallback plans
      hasError.value = false;

      // Ensure we have fallback plans
      if (subscriptionPlans.isEmpty) {
        print('📦 Creating fallback plans due to error');
        _createDefaultPlans();
      }

      // Show user-friendly notification only if we have a valid overlay
      try {
        showWarningSnackBar(
          'Using cached subscription plans. Pull to refresh when online.',
          title: '📶 Offline Mode',
        );
      } catch (overlayError) {
        print('⚠️ Could not show snackbar: $overlayError');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _createDefaultPlans() {
    subscriptionPlans.value = [
      SubscriptionPlan(
        id: 'monthly_basic',
        title: 'Monthly Basic',
        rate: 299,
        durationInMonths: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      SubscriptionPlan(
        id: 'quarterly_premium',
        title: 'Quarterly Premium',
        rate: 799,
        durationInMonths: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      SubscriptionPlan(
        id: 'annual_pro',
        title: 'Annual Pro',
        rate: 2999,
        durationInMonths: 12,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    print('📦 Created ${subscriptionPlans.length} default subscription plans');
  }

  Future<void> buySubscription(SubscriptionPlan plan, {String paymentMethod = 'online'}) async {
    try {
      if (driverId == null || driverId!.isEmpty) {
        throw Exception('Driver ID not found. Please login again.');
      }

      print('\n🚀 ===== STARTING SUBSCRIPTION PURCHASE =====');
      print('📦 Plan: ${plan.title}');
      print('💰 Amount: ₹${plan.rate}');
      print('💳 Payment Method: $paymentMethod');
      print('👤 Driver: $driverId');

      isProcessingPayment.value = true;
      selectedPlanId.value = plan.id;
      _currentPlan = plan;

      // Create order with backend
      print('📡 Creating order with backend...');
      final response = await _repository.buySubscription(
        driverId!,
        plan.id,
        planType: plan.title,
        amount: plan.rate * 100, // Convert to paise
        paymentMethod: paymentMethod,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to create order');
      }

      // Check if wallet payment was successful instantly
      if (paymentMethod == 'wallet') {
        print('✅ Wallet payment successful. Subscription activated immediately.');
        isProcessingPayment.value = false;
        
        // Optimistically update status to trigger auto-redirect
        subscriptionActive.value = true;
        subscriptionStatus.value = 'active';
        hasSubscription.value = true;
        
        showSuccessSnackBar('Subscription activated successfully via Wallet!', title: 'Payment Success');
        await loadSubscriptionStatus();
        return; // Skip Razorpay
      }

      final orderIdValue = response['orderId']?.toString() ?? '';
      final amountInPaise = response['amount'] as int? ?? 0;

      print('✅ Order created: $orderIdValue');
      print('💰 Amount: $amountInPaise paise');

      // Store order details
      orderId.value = orderIdValue;

      // Create Razorpay options with redirect prevention
      // ✅ CRITICAL FIX: These options prevent "Something went wrong" popup
      // by disabling all redirect attempts and URL-based navigation
      // ⚠️ NOTE: No closures/functions allowed - they can't be serialized across platform channels
      Map<String, dynamic> options = {
        'key': _razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'order_id': orderIdValue,
        'name': 'RiDeal',
        'description': plan.title,
        // CRITICAL: Prevent redirect issues
        'redirect': false,
        'retry': {'enabled': false},
        // Remove any URL-based redirects
        'callback_url': null,
        'cancel_url': null,
        // Ensure clean mobile experience
        'method': {
          'netbanking': true,
          'card': true,
          'wallet': true,
          'upi': true,
          'paylater': true,
        },
      };

      print('🚀 Opening Razorpay checkout...');
      print('📋 Enhanced Options (redirect=false):');
      print('   Key: ${options['key']}');
      print('   Amount: ${options['amount']} paise');
      print('   Order ID: ${options['order_id']}');
      print('   Redirect: ${options['redirect']}');
      print('   Retry: ${options['retry']}');
      print('   Methods: ${options['method'].keys.join(', ')}');
      print('🔧 Test Mode: $_isTestMode');
      print('🔍 Should Simulate: ${_shouldSimulatePayment()}');

      // Reinitialize Razorpay to ensure clean state
      _initializeRazorpay();

      // Show loading dialog
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Opening Payment Gateway...'),
              const SizedBox(height: 8),
              Text(
                'Please wait while we prepare your payment',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Add small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Close loading dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // CRITICAL FIX: Add payment simulation for testing
      if (_shouldSimulatePayment()) {
        print('🧪 SIMULATION MODE: Testing payment without Razorpay');
        _simulatePaymentSuccess();
        return;
      }

      print('💳 REAL RAZORPAY MODE: Opening actual payment gateway...');

      // Open Razorpay checkout with enhanced error handling
      try {
        print('🔍 About to open Razorpay with minimal options...');
        print('   Razorpay instance initialized');

        // Validate essential options
        if (options['key'] == null ||
            options['amount'] == null ||
            options['order_id'] == null) {
          throw Exception('Missing required payment options');
        }

        _razorpay.open(options);
        print(
          '✅ Checkout opened successfully - waiting for payment completion...',
        );
      } catch (e) {
        print('❌ Failed to open Razorpay checkout: $e');

        // Close loading dialog if open
        if (Get.isDialogOpen == true) {
          Get.back();
        }

        // Show fallback option for testing
        Get.dialog(
          AlertDialog(
            title: Text('Payment Gateway Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Razorpay checkout failed to open.'),
                const SizedBox(height: 16),
                Text('For testing, simulate payment success?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  isProcessingPayment.value = false;
                  selectedPlanId.value = '';
                  _currentPlan = null;
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // Simulate successful payment for testing
                  _simulatePaymentSuccess();
                },
                child: Text('Test Success'),
              ),
            ],
          ),
        );

        return;
      }
    } catch (e) {
      print('❌ Subscription purchase error: $e');

      isProcessingPayment.value = false;
      selectedPlanId.value = '';
      _currentPlan = null;

      String errorMessage = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Payment Error',
        errorMessage,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  Future<void> _verifyPayment() async {
    print('\n🔍 ════════════════════════════════════════════════════════');
    print('🔍           STARTING PAYMENT VERIFICATION');
    print('🔍 ════════════════════════════════════════════════════════');

    try {
      if (paymentId.value == null ||
          orderId.value == null ||
          signature.value == null) {
        throw Exception('Payment verification data missing');
      }

      print('📡 Calling backend verification API...');
      final response = await _repository.verifyPayment(
        driverId: driverId!,
        planId: selectedPlanId.value,
        razorpayPaymentId: paymentId.value!,
        razorpayOrderId: orderId.value!,
        razorpaySignature: signature.value!,
      );

      if (response['success'] == true) {
        print('🎉 Payment verified successfully!');

        // Parse subscription data from the actual backend response structure
        final subscriptionData = response['subscription'];
        DateTime? expiry;
        SubscriptionModel? subscription;

        if (subscriptionData != null) {
          try {
            subscription = SubscriptionModel.fromJson(subscriptionData);
            expiry = subscription.endDate;

            // Save the subscription model
            currentSubscription.value = subscription;

            print(
              '✅ Subscription parsed: ${subscription.planId} until ${subscription.endDate}',
            );
          } catch (e) {
            print('⚠️ Failed to parse subscription model: $e');
            // Fallback to manual parsing
            final endDateStr = subscriptionData['endDate'];
            if (endDateStr != null) {
              expiry = DateTime.tryParse(endDateStr);
            }
          }
        }

        await _saveSubscriptionStatus(true, expiry: expiry, plan: _currentPlan);
        await loadSubscriptionStatus();

        // Close any open dialogs
        if (Get.isDialogOpen == true) {
          Get.back();
        }

        // Show success dialog
        Get.dialog(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Flexible(child: Text('Subscription Activated!')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Your ${_currentPlan?.title ?? 'subscription'} is now active!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (expiry != null)
                  Text(
                    'Valid until: ${expiry.day}/${expiry.month}/${expiry.year}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  if (_tokenManager.isNonVehicleDriver) {
                    Get.offAllNamed('/nonvehichledashboard');
                  } else {
                    Get.offAllNamed('/dashboard');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Continue'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } else {
        throw Exception(response['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      print('❌ Payment verification failed: $e');

      // Close loading dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Enhanced error handling for different types of errors
      String userFriendlyMessage = 'Payment verification failed';
      String technicalDetails = e.toString();

      if (e.toString().contains('NoSuchMethodError')) {
        userFriendlyMessage = 'Invalid response format from server';
        technicalDetails =
            'The server response format has changed or is invalid';
      } else if (e.toString().contains('null')) {
        userFriendlyMessage = 'Missing payment information';
        technicalDetails = 'Required payment data was not received';
      } else if (e.toString().contains('signature')) {
        userFriendlyMessage = 'Payment signature verification failed';
        technicalDetails = 'Payment signature does not match';
      }

      // Show enhanced error dialog
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text('Payment Verification Failed')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payment, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                userFriendlyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                technicalDetails,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                // Retry verification
                _verifyPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry Verification'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } finally {
      isProcessingPayment.value = false;
      selectedPlanId.value = '';
      _currentPlan = null;
    }
  }

  Future<void> _saveSubscriptionStatus(
    bool active, {
    DateTime? expiry,
    SubscriptionPlan? plan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('subscription_active', active);

      if (expiry != null) {
        await prefs.setString('subscription_expiry', expiry.toIso8601String());
      }

      subscriptionActive.value = active;
      hasSubscription.value = active;
      expiryDate.value = expiry;

      // Update activeSubscription if we have an active plan
      if (active && plan != null) {
        activeSubscription.value = ActiveSubscriptionModel(
          planName: plan.title,
          amount: plan.rate, // int type as per model
          duration: plan.formattedDuration,
          status: 'active',
          expiry:
              expiry ??
              (plan.durationInMonths > 0
                  ? DateTime.now().add(
                      Duration(days: plan.durationInMonths * 30),
                    )
                  : DateTime.now().add(Duration(days: plan.durationInDays))),
        );
        print('💎 ActiveSubscription updated: ${plan.title} - ₹${plan.rate}');
      } else if (!active) {
        activeSubscription.value = null;
        print('❌ ActiveSubscription cleared');
      }

      print('💾 Subscription Status Saved: $active');
    } catch (e) {
      print('❌ Error saving subscription status: $e');
    }
  }

  Future<void> _clearSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('subscription_active');
      await prefs.remove('subscription_expiry');

      subscriptionActive.value = false;
      hasSubscription.value = false;
      expiryDate.value = null;
      activeSubscription.value = null;

      print('🗑️ All subscription data cleared');
    } catch (e) {
      print('❌ Error clearing subscription data: $e');
    }
  }

  // Helper methods for driver details
  Future<String> getDriverPhone() async {
    try {
      return await StorageHelper.getDriverPhone() ?? '9999999999';
    } catch (e) {
      return '9999999999';
    }
  }

  Future<String> getDriverEmail() async {
    try {
      return await StorageHelper.getDriverEmail() ?? 'driver@rideal.app';
    } catch (e) {
      return 'driver@rideal.app';
    }
  }

  Future<String> getDriverName() async {
    try {
      return await StorageHelper.getDriverName() ?? 'Driver';
    } catch (e) {
      return 'Driver';
    }
  }

  Future<bool> hasEnoughWalletBalance(double requiredAmount) async {
    try {
      final earningsController = Get.isRegistered<EarningsController>()
          ? Get.find<EarningsController>()
          : Get.put(EarningsController());
      await earningsController.fetchWalletData();
      return earningsController.walletBalance.value >= requiredAmount;
    } catch (e) {
      print('Error fetching wallet balance: $e');
      return false;
    }
  }

  bool canUploadProduct() {
    return hasSubscription.value && subscriptionActive.value;
  }

  // Check if should simulate payment (for debugging Razorpay issues)
  bool _shouldSimulatePayment() {
    // You can change this to true to test simulation mode
    // Or set to false to test real Razorpay integration
    return _isTestMode;
  }

  // Generate valid test signature for simulation
  String _generateTestSignature(String orderId, String paymentId) {
    if (_isTestMode) {
      // In test mode, generate a predictable signature for backend to recognize
      return 'test_signature_${orderId}_$paymentId';
    } else {
      // For production, use actual HMAC-SHA256 (requires real secret)
      final message = '$orderId|$paymentId';
      final key = utf8.encode(_razorpayKeyId);
      final bytes = utf8.encode(message);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      return digest.toString();
    }
  }

  // Simulate payment success for testing when Razorpay fails
  void _simulatePaymentSuccess() {
    print('🧪 ════════════════════════════════════════════════════════');
    print('🧪         SIMULATING PAYMENT SUCCESS FOR TESTING');
    print('🧪 ════════════════════════════════════════════════════════');

    // Simulate payment response
    final fakePaymentId = 'pay_test_${DateTime.now().millisecondsSinceEpoch}';
    final testSignature = _generateTestSignature(orderId.value!, fakePaymentId);

    print('💳 Fake Payment ID: $fakePaymentId');
    print('🔒 Test Signature: $testSignature');
    print('📋 Order ID: ${orderId.value}');
    print('🧪 Test Mode: $_isTestMode');

    // Set payment values
    paymentId.value = fakePaymentId;
    signature.value = testSignature;

    print('🧪 Starting simulated payment verification...');
    _verifyPayment();
  }

  // Alias for compatibility with subscription screen
  Future<void> refreshSubscriptionStatus() async {
    await loadSubscriptionStatus();
  }

  @override
  void onClose() {
    _razorpay.clear();
    _paymentService.dispose();
    super.onClose();
  }

  // PRODUCTION-READY PAYMENT METHOD
  Future<void> buySubscriptionWithRazorpay(SubscriptionPlan plan) async {
    try {
      isProcessingPayment.value = true;
      selectedPlanId.value = plan.id;
      _currentPlan = plan;

      print('💳 Starting production Razorpay payment for ${plan.title}');

      if (driverId == null) {
        throw Exception('Driver ID not found. Please login again.');
      }

      // Get driver details for prefill
      final driverName = await StorageHelper.getDriverName() ?? 'Driver';
      final driverEmail = await StorageHelper.getDriverEmail();
      final driverPhone = await StorageHelper.getDriverPhone();

      // Show loading dialog
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up payment...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Use the production payment service
      await _paymentService.processPayment(
        amount: plan.rate.toDouble(),
        description: '${plan.title} Subscription',
        driverId: driverId!,
        planId: plan.id,
        driverName: driverName,
        driverEmail: driverEmail,
        driverPhone: driverPhone,
        planType: plan.title, // Add explicit plan type
        onVerificationSuccess: (result) async {
          print('🎉 Payment and verification successful!');

          // Update subscription status
          // Parse from the actual backend response structure
          final subscriptionData = result['subscription'];
          DateTime? expiry;

          if (subscriptionData != null) {
            final endDateStr = subscriptionData['endDate'];
            if (endDateStr != null) {
              expiry = DateTime.tryParse(endDateStr);
            }
          }

          await _saveSubscriptionStatus(true, expiry: expiry, plan: plan);
          await loadSubscriptionStatus();

          // Close loading dialog
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          // Show success dialog
          _showPaymentSuccessDialog(plan, expiry);
        },
        onError: (error) {
          print('❌ Payment failed: $error');

          // Close loading dialog
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          // Show error dialog
          _showPaymentErrorDialog(error);
        },
      );

      // Close initial loading dialog when Razorpay opens
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    } catch (e) {
      print('❌ Payment setup failed: $e');

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      showErrorSnackBar('Failed to setup payment: $e', title: 'Payment Failed');
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void _showPaymentSuccessDialog(SubscriptionPlan plan, DateTime? expiry) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Flexible(child: Text('Payment Successful!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Your ${plan.title} subscription is now active!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (expiry != null)
              Text(
                'Valid until: ${expiry.day}/${expiry.month}/${expiry.year}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment secured by Razorpay',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPaymentErrorDialog(String error) {
    // Determine error type and provide helpful message
    String userFriendlyMessage = error;
    String troubleshootingTip = '';

    if (error.contains('NETWORK_ERROR') || error.contains('network')) {
      userFriendlyMessage = 'Network connection failed';
      troubleshootingTip =
          'Please check your internet connection and try again.';
    } else if (error.contains('cancelled') ||
        error.contains('PAYMENT_CANCELLED')) {
      userFriendlyMessage = 'Payment was cancelled';
      troubleshootingTip = 'You can retry the payment anytime.';
    } else if (error.contains('signature') ||
        error.contains('VERIFICATION_FAILED')) {
      userFriendlyMessage = 'Payment verification failed';
      troubleshootingTip =
          'If amount was deducted, it will be refunded within 5-7 working days.';
    } else if (error.contains('insufficient') ||
        error.contains('INSUFFICIENT_BALANCE')) {
      userFriendlyMessage = 'Insufficient balance';
      troubleshootingTip =
          'Please check your account balance or try a different payment method.';
    }

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(child: Text('Payment Failed')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.payment, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              userFriendlyMessage,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (troubleshootingTip.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                troubleshootingTip,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need help? Contact support with your order details.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Close')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Retry payment
              buySubscriptionWithRazorpay(_currentPlan!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
