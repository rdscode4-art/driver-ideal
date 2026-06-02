import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/new_razorpay_service.dart';
import '../services/api_service.dart';
import '../core/token_manager.dart';
import '../core/utils/app_snackbar.dart';

/// 🎮 Payment Controller with GetX State Management
class PaymentController extends GetxController {
  // Services
  final RazorpayService _razorpayService = Get.find<RazorpayService>();
  final ApiService _apiService = Get.find<ApiService>();
  final TokenManager _tokenManager = Get.find<TokenManager>();

  // Observable state variables
  final isLoading = false.obs;
  final isProcessingPayment = false.obs;
  final paymentStatus = PaymentStatus.idle.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;

  // Current subscription data
  final currentDriverId = ''.obs;
  final selectedPlan = Rxn<SubscriptionPlan>();
  final paymentAmount = 0.0.obs;

  // Payment session data
  final currentOrderId = ''.obs;
  final currentPlanId = ''.obs;
  final paymentId = ''.obs;

  // Plans
  final availablePlans = <SubscriptionPlan>[].obs;
  final isLoadingPlans = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    _setupPaymentCallbacks();
    // Auto-fetch plans on init
    fetchAvailablePlans();
  }

  @override
  void onClose() {
    cleanupPaymentSession();
    super.onClose();
  }

  /// ⭐ Initialize controller with CORRECT driver data
  Future<void> _initializeController() async {
    try {
      log('🔍 ===== INITIALIZING PAYMENT CONTROLLER =====');
      
      String? driverId = _tokenManager.driverId;
      log('📱 TokenManager Driver ID: $driverId');

      if (driverId == null || driverId.isEmpty) {
        log('⚠️ TokenManager empty, checking SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        
        driverId = prefs.getString('user_id');
        log('📦 SharedPrefs user_id: $driverId');
        
        if (driverId == null || driverId.isEmpty) {
          driverId = prefs.getString('driver_id');
          log('📦 SharedPrefs driver_id: $driverId');
        }
        
        if (driverId != null && driverId.isNotEmpty) {
          log('🔄 Syncing driver ID to TokenManager...');
          await _tokenManager.updateUserId(driverId);
        }
      }

      if (driverId != null && driverId.isNotEmpty) {
        currentDriverId.value = driverId;
        log('✅ PaymentController initialized for driver: ${currentDriverId.value}');
        log('✅ Driver ID length: ${driverId.length}');
      } else {
        log('❌ NO DRIVER ID FOUND!');
        currentDriverId.value = '';
      }
      
      log('===== INITIALIZATION COMPLETE =====\n');
    } catch (e) {
      log('❌ Error initializing PaymentController: $e');
      currentDriverId.value = '';
    }
  }

  /// Setup payment success/failure callbacks
  void _setupPaymentCallbacks() {
    _razorpayService.onSuccess = (PaymentSuccessResponse response) {
      log('✅ Payment callback - Success received');
      paymentStatus.value = PaymentStatus.success;
      paymentId.value = response.paymentId ?? '';
      successMessage.value = 'Payment completed successfully!';
    };

    _razorpayService.onFailure = (PaymentFailureResponse response) {
      log('❌ Payment callback - Failure received');
      paymentStatus.value = PaymentStatus.failed;
      errorMessage.value = response.message ?? 'Payment failed';
      isProcessingPayment.value = false;
    };

    _razorpayService.onExternalWallet = (ExternalWalletResponse response) {
      log('🏦 Payment callback - External wallet: ${response.walletName}');
      paymentStatus.value = PaymentStatus.externalWallet;
    };
  }

  /// 📱 Fetch Available Subscription Plans from Backend
  Future<void> fetchAvailablePlans() async {
    try {
      isLoadingPlans.value = true;
      log('📋 Fetching subscription plans from backend...');
      
      final response = await _apiService.get('/api');
      log('📥 API Response Status: ${response.statusCode}');
      log('📥 API Response: ${response.data}');
      
      if (response.isSuccess && response.data != null) {
        final responseData = response.data;
        
        if (responseData != null) {
          List<dynamic> plansList = [];
          
          // Response format: {"success": true, "plans": [...]}
          if (responseData.containsKey('plans')) {
            final plansValue = responseData['plans'];
            if (plansValue is List) {
              plansList = plansValue;
            }
          } else if (responseData.containsKey('data')) {
            final dataValue = responseData['data'];
            if (dataValue is List) {
              plansList = dataValue;
            }
          } else {
            log('⚠️ Unexpected response structure: $responseData');
          }
                  
          if (plansList.isNotEmpty) {
            availablePlans.value = plansList.map((planData) {
              final plan = planData as Map<String, dynamic>;
              
              return SubscriptionPlan(
                id: plan['_id']?.toString() ?? '', // ✅ MongoDB ObjectId
                name: plan['title'] ?? 'Unknown Plan',
                amount: (plan['rate'] ?? 0).toDouble(),
                description: 'RiDeal ${plan['title']} Subscription',
                duration: '${plan['durationInMonths'] ?? 0} months',
                features: [
                  'Unlimited ride requests',
                  'Priority support',
                  'Valid for ${plan['durationInMonths'] ?? 0} months',
                ],
              );
            }).toList();
            
            log('✅ Loaded ${availablePlans.length} plans successfully');
            
            // Debug log each plan
            for (var plan in availablePlans) {
              log('   📦 ${plan.name} (ID: ${plan.id}) - ₹${plan.amount} (${plan.duration})');
            }
          } else {
            log('⚠️ Plans list is empty');
            availablePlans.value = [];
            _showError('No subscription plans available at the moment');
          }
        } else {
          log('⚠️ Response data is null');
          availablePlans.value = [];
          _showError('Failed to load subscription plans');
        }
      } else {
        log('❌ API call failed: ${response.message}');
        availablePlans.value = [];
        _showError('Failed to load subscription plans: ${response.message}');
      }
    } catch (e, stackTrace) {
      log('❌ Error fetching plans: $e');
      log('❌ Stack trace: $stackTrace');
      availablePlans.value = [];
      _showError('Error loading plans: $e');
    } finally {
      isLoadingPlans.value = false;
    }
  }

  /// 🛒 Start Subscription Purchase Flow
  /// ✅ FIXED: Now uses planId instead of planType
  Future<void> buySubscription({
    required String planId,  // ✅ Changed from planType to planId
    required String planName, // ✅ Added for display purposes
    required double amount,
    String? contact,
    String? email,
  }) async {
    try {
      log('🛒 ════════════════════════════════════════════════════════');
      log('🛒           STARTING PAYMENT CONTROLLER FLOW');
      log('🛒 ════════════════════════════════════════════════════════');

      _resetPaymentState();

      if (currentDriverId.value.isEmpty) {
        log('⚠️ Driver ID empty, re-initializing...');
        await _initializeController();
      }

      if (currentDriverId.value.isEmpty) {
        throw Exception('Driver ID not found. Please login again.');
      }

      if (currentDriverId.value.length != 24) {
        log('⚠️ Invalid driver ID format: ${currentDriverId.value}');
        throw Exception('Invalid driver ID. Please login again.');
      }

      // ✅ Validate planId format (MongoDB ObjectId)
      if (planId.length != 24) {
        log('⚠️ Invalid plan ID format: $planId');
        throw Exception('Invalid plan ID format');
      }

      if (amount <= 0) {
        throw Exception('Invalid amount: ₹$amount');
      }

      isLoading.value = true;
      isProcessingPayment.value = true;
      paymentStatus.value = PaymentStatus.processing;
      paymentAmount.value = amount;

      selectedPlan.value = SubscriptionPlan(
        id: planId,  // ✅ Store the plan ID
        name: planName,
        amount: amount,
        description: 'RiDeal $planName Subscription',
      );

      log('👤 Driver ID: ${currentDriverId.value}');
      log('🆔 Plan ID: $planId');  // ✅ Log plan ID
      log('📦 Plan Name: $planName');
      log('💰 Amount: ₹$amount');

      // ✅ Pass planId instead of planType
      await _razorpayService.buySubscription(
        driverId: currentDriverId.value,
        planId: planId,  // ✅ Changed from planType to planId
        amount: amount,
        contact: contact,
        email: email,
      );
    } catch (e) {
      log('❌ Error in buySubscription: $e');

      isLoading.value = false;
      isProcessingPayment.value = false;
      paymentStatus.value = PaymentStatus.failed;
      errorMessage.value = e.toString();

      _showError('Failed to start payment: $e');
    }
  }

  /// 🔄 Retry Failed Payment
  Future<void> retryPayment() async {
    if (selectedPlan.value != null) {
      await buySubscription(
        planId: selectedPlan.value!.id ?? '',  // ✅ Use plan ID
        planName: selectedPlan.value!.name,
        amount: selectedPlan.value!.amount,
      );
    } else {
      _showError('No plan selected to retry');
    }
  }

  /// 🏥 Check Payment Status
  Future<void> checkPaymentStatus() async {
    try {
      if (paymentId.value.isEmpty || currentOrderId.value.isEmpty) {
        log('⚠️ No payment ID or order ID to check status');
        return;
      }

      isLoading.value = true;
      log('🔍 Checking payment status for: ${paymentId.value}');
      isLoading.value = false;
    } catch (e) {
      log('❌ Error checking payment status: $e');
      isLoading.value = false;
      _showError('Failed to check payment status: $e');
    }
  }

  /// 🧹 Clean Up Payment Session
  void cleanupPaymentSession() {
    _resetPaymentState();
    _razorpayService.cleanupSession();
    log('🧹 Payment session cleaned up');
  }

  /// Reset payment state to initial values
  void _resetPaymentState() {
    isLoading.value = false;
    isProcessingPayment.value = false;
    paymentStatus.value = PaymentStatus.idle;
    errorMessage.value = '';
    successMessage.value = '';
    currentOrderId.value = '';
    currentPlanId.value = '';
    paymentId.value = '';
  }

  /// Set selected plan
  void selectPlan(SubscriptionPlan plan) {
    selectedPlan.value = plan;
    paymentAmount.value = plan.amount;
    log('📦 Plan selected: ${plan.name} (ID: ${plan.id}) - ₹${plan.amount}');
  }

  /// Show error message
  void _showError(String message) {
    showErrorSnackBar(
      message,
      title: 'Payment Error',
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    showSuccessSnackBar(
      message,
      title: 'Payment Success',
    );
  }

  /// Get current payment session debug info
  Map<String, dynamic> getDebugInfo() {
    return {
      'driverId': currentDriverId.value,
      'paymentStatus': paymentStatus.value.name,
      'isLoading': isLoading.value,
      'isProcessingPayment': isProcessingPayment.value,
      'selectedPlan': selectedPlan.value?.toJson(),
      'paymentAmount': paymentAmount.value,
      'errorMessage': errorMessage.value,
      'successMessage': successMessage.value,
      'plansCount': availablePlans.length,
      'razorpaySession': _razorpayService.getSessionInfo(),
    };
  }
}

/// 📦 Subscription Plan Model
class SubscriptionPlan {
  final String? id;
  final String name;
  final double amount;
  final String description;
  final String? duration;
  final List<String>? features;

  SubscriptionPlan({
    this.id,
    required this.name,
    required this.amount,
    required this.description,
    this.duration,
    this.features,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'description': description,
      'duration': duration,
      'features': features,
    };
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? json['title'] ?? 'Unknown Plan',
      amount: (json['amount'] ?? json['rate'] ?? 0).toDouble(),
      description: json['description'] ?? 'RiDeal Subscription',
      duration: json['duration'] ?? 
                (json['durationInMonths'] != null 
                  ? '${json['durationInMonths']} months' 
                  : null),
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : null,
    );
  }
}

/// 🎭 Payment Status Enum
enum PaymentStatus {
  idle,
  processing,
  success,
  failed,
  externalWallet,
  verifying,
}