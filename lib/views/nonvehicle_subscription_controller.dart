import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:rideal_driver/core/storage_helper.dart';
import 'package:rideal_driver/services/rideal_subscription_service.dart';
import 'package:rideal_driver/routes/app_pages.dart';
import '../core/token_manager.dart';
import 'package:http/http.dart' as http;
import '../core/utils/app_snackbar.dart';

class SubscriptionPlan {
  final String id;
  final String title;
  final int rate;
  final int durationInMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.rate,
    required this.durationInMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      rate: json['rate'] ?? 0,
      durationInMonths: json['durationInMonths'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'rate': rate,
      'durationInMonths': durationInMonths,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class NonVehicleSubscriptionController extends GetxController {
  // Razorpay Configuration
  static const String _razorpayKeyId = 'rzp_live_RoLpvsh1Qs9Cfs';

  late Razorpay _razorpay;

  // Base URL for non-vehicle APIs
  static const String baseUrl = 'https://backend.ridealmobility.com';

  // ❌ REMOVED: Auto-redirect flag causing immediate back navigation
  // var hasAutoRedirected = false;
  // Observable variables
  var subscriptionStatus = 'not_subscribed'.obs;
  var currentPlanId = ''.obs;
  var currentPlanName = ''.obs;
  var expiryDate = Rxn<DateTime>();
  var startDate = Rxn<DateTime>();

  var subscriptionPlans = <SubscriptionPlan>[].obs;
  var selectedPlanId = ''.obs;
  var currentOrderId = ''.obs;
  var currentRazorpayOrderId = ''.obs;

  var isLoading = false.obs;
  var isProcessingPayment = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Current plan being processed
  SubscriptionPlan? _currentPlan;

  // Driver details from TokenManager
  String? get driverId {
    final tokenManager = TokenManager.instance;
    final id = tokenManager.userId.value;
    print('🔍 Getting driver ID from TokenManager: $id');
    return id;
  }

  // Get driver details from StorageHelper
  Future<String> getDriverPhone() async {
    try {
      final userData = await StorageHelper.getUserData();
      if (userData != null && userData.isNotEmpty) {
        final Map<String, dynamic> userMap = json.decode(userData);
        final phone =
            userMap['phone'] ??
            userMap['mobile'] ??
            userMap['phoneNumber'] ??
            userMap['contactNumber'] ??
            '';
        print('📱 Retrieved phone from storage: $phone');
        return phone.toString();
      }
    } catch (e) {
      print('Error getting phone: $e');
    }
    return '';
  }

  Future<String> getDriverEmail() async {
    try {
      final userData = await StorageHelper.getUserData();
      if (userData != null && userData.isNotEmpty) {
        final Map<String, dynamic> userMap = json.decode(userData);
        final email = userMap['email'] ?? '';
        print('📧 Retrieved email from storage: $email');
        return email.toString();
      }
    } catch (e) {
      print('❌ Error getting email: $e');
    }
    return '';
  }

  Future<String> getDriverName() async {
    try {
      final userData = await StorageHelper.getUserData();
      if (userData != null && userData.isNotEmpty) {
        final Map<String, dynamic> userMap = json.decode(userData);
        final name =
            userMap['name'] ??
            userMap['fullName'] ??
            userMap['driverName'] ??
            'Driver';
        print('👤 Retrieved name from storage: $name');
        return name.toString();
      }
    } catch (e) {
      print('❌ Error getting name: $e');
    }
    return 'Driver';
  }

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();
    loadSubscriptionStatus();
    loadSubscriptionPlans();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  /// Initialize Razorpay
  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Handle Razorpay payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅ Payment Success!');
    print('Payment ID: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');

    // Check for null values that shouldn't happen
    if (response.paymentId == null) {
      print('❌ Payment ID is null - this is unexpected');
      _handlePurchaseError('Payment ID missing from Razorpay response');
      return;
    }

    // Validate that we have order ID stored
    if (currentRazorpayOrderId.value.isEmpty && currentOrderId.value.isEmpty) {
      print('❌ No order ID found in controller state');
      _handlePurchaseError('Order ID missing - please try again');
      return;
    }

    // Show immediate success feedback
    showSuccessSnackBar(
      'Verifying payment... Please wait',
      title: 'Payment Successful! ✅',
    );

    // Close any dialogs
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    // Show faster processing dialog
    _showFastProcessingDialog('Verifying payment...');

    // Verify payment immediately with null-safe API
    final orderIdToUse = response.orderId ?? currentRazorpayOrderId.value;
    final signatureToUse =
        response.signature ?? _generateFallbackSignature(response.paymentId!);

    // Final validation before verification
    if (orderIdToUse.isEmpty) {
      print('❌ No order ID available for verification');
      _handlePurchaseError('Order ID missing for verification');
      return;
    }

    _verifyPaymentWithOptimizedAPI(
      driverId: driverId!,
      planId: _currentPlan?.id ?? selectedPlanId.value,
      razorpayPaymentId: response.paymentId!,
      razorpayOrderId: orderIdToUse,
      razorpaySignature: signatureToUse,
    );
  }

  /// Handle Razorpay payment error
  /// Handle Razorpay payment error - Enhanced version
  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ ============ PAYMENT ERROR DETAILS ============');
    print('❌ Error Code: ${response.code}');
    print('❌ Error Message: ${response.message}');
    print('❌ Error Metadata: ${response.error}');
    print('❌ Full Response: $response');
    print('❌ ==============================================');

    isProcessingPayment.value = false;
    selectedPlanId.value = '';
    currentOrderId.value = '';

    // Show detailed error to user
    showErrorSnackBar('Payment Failed: ${response.message ?? "Unknown error"}');

    // Also show in dialog for better visibility
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('Payment Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error Code: ${response.code}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Message: ${response.message ?? "Unknown error"}'),
              if (response.error != null) ...[
                const SizedBox(height: 8),
                Text('Details: ${response.error}'),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: ${currentOrderId.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Driver ID: ${driverId ?? "N/A"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Plan ID: ${selectedPlanId.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Get.back();
              // Retry with the same plan
              final plan = subscriptionPlans.firstWhere(
                (p) => p.id == selectedPlanId.value,
                orElse: () => subscriptionPlans.first,
              );
              buySubscription(plan);
            },
            child: Text('Retry', style: TextStyle(color: Colors.orange[700])),
          ),
        ],
      ),
    );
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 External Wallet: ${response.walletName}');

    showInfoSnackBar(
      'Payment via ${response.walletName}',
      title: 'External Wallet',
    );
  }

  /// Load current subscription status from API
  Future<void> loadSubscriptionStatus() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      if (driverId == null || driverId!.isEmpty) {
        print('❌ No driver ID found');
        subscriptionStatus.value = 'not_subscribed';
        return;
      }

      print('📡 Fetching subscription status for driver: $driverId');
      final response = await RidealSubscriptionService.getSubscriptionStatus(
        driverId!,
      );

      print('🔍 Service response: $response');

      if (response['success'] == true) {
        final data = response['data'];

        // 🔧 Handle API response format properly
        print('📊 Raw API data: $data');

        // Check if subscribed field exists and is true
        if (data['subscribed'] == true) {
          subscriptionStatus.value =
              'active'; // Set as active when subscribed is true
          print('✅ Found subscribed=true, setting status to active');
        } else {
          // Fallback to status field or default
          subscriptionStatus.value = data['status'] ?? 'not_subscribed';
          print(
            'ℹ️ Using status field or default: ${subscriptionStatus.value}',
          );
        }

        // Handle plan information from nested plan object
        if (data['plan'] != null) {
          final planData = data['plan'];
          currentPlanId.value = planData['_id'] ?? planData['id'] ?? '';
          currentPlanName.value =
              planData['title'] ?? planData['name'] ?? 'Subscription Plan';

          print('📦 Plan ID: ${currentPlanId.value}');
          print('📦 Plan Name: ${currentPlanName.value}');
        } else {
          // Fallback for direct fields
          currentPlanId.value = data['plan_id'] ?? data['planId'] ?? '';
          currentPlanName.value = data['plan_name'] ?? data['planName'] ?? '';
        }

        // Handle dates with multiple possible field names
        if (data['endDate'] != null) {
          expiryDate.value = DateTime.parse(data['endDate']);
          print('📅 Expiry date from endDate: ${expiryDate.value}');
        } else if (data['expiry_date'] != null || data['expiryDate'] != null) {
          expiryDate.value = DateTime.parse(
            data['expiry_date'] ?? data['expiryDate'],
          );
          print('📅 Expiry date from legacy field: ${expiryDate.value}');
        }

        if (data['startDate'] != null) {
          startDate.value = DateTime.parse(data['startDate']);
          print('📅 Start date from startDate: ${startDate.value}');
        } else if (data['start_date'] != null) {
          startDate.value = DateTime.parse(data['start_date']);
          print('📅 Start date from legacy field: ${startDate.value}');
        }

        print('✅ Subscription status: ${subscriptionStatus.value}');
        print('📦 Current plan: ${currentPlanName.value}');
      } else {
        throw Exception(
          response['message'] ?? 'Failed to load subscription status',
        );
      }
    } catch (e) {
      print('❌ Error loading subscription status: $e');

      hasError.value = true;
      errorMessage.value = e.toString();
      subscriptionStatus.value = 'not_subscribed';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load available subscription plans
  Future<void> loadSubscriptionPlans() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      print('📡 Fetching subscription plans...');
      final response = await RidealSubscriptionService.getSubscriptionPlans();

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> plansData = [];

        // Handle different response structures
        if (data is Map && data.containsKey('plans')) {
          plansData = data['plans'] ?? [];
        } else if (data is List) {
          plansData = data;
        }

        subscriptionPlans.value = plansData
            .map((json) => SubscriptionPlan.fromJson(json))
            .toList();

        print('✅ Loaded ${subscriptionPlans.length} subscription plans');
      } else {
        throw Exception(response['message'] ?? 'Failed to load plans');
      }
    } catch (e) {
      print('❌ Error loading subscription plans: $e');
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Buy subscription - Opens Razorpay payment
  /// Start subscription purchase with proper non-vehicle APIs
  Future<void> buySubscription(SubscriptionPlan plan) async {
    try {
      if (driverId == null || driverId!.isEmpty) {
        throw Exception('Driver ID not found. Please login again.');
      }

      print('\n🚀 ===== STARTING NON-VEHICLE SUBSCRIPTION PURCHASE =====');
      print('📦 Plan: ${plan.title}');
      print('💰 Amount: ₹${plan.rate}');
      print('👤 Driver ID: $driverId');
      print('🆔 Plan ID: ${plan.id}');

      isProcessingPayment.value = true;
      selectedPlanId.value = plan.id;
      _currentPlan = plan;
      hasError.value = false;

      // Get driver details for prefill
      final phone = await getDriverPhone();
      final email = await getDriverEmail();
      final name = await getDriverName();

      // Validate required details
      if (phone.isEmpty) {
        throw Exception('Phone number is required for payment');
      }

      // Show processing dialog
      _showProcessingDialog('Creating order...');

      // Step 1: Create order using exact API
      // curl --location 'https://backend.ridealmobility.com/api/non-vehicle-driver/buy-subscription'
      final orderResponse = await _createSubscriptionOrder(
        driverId: driverId!,
        planId: plan.id,
        amount: plan.rate * 100, // Convert to paise
      );

      if (orderResponse['success'] != true) {
        throw Exception(orderResponse['message'] ?? 'Failed to create order');
      }

      final orderData = orderResponse['data'];

      // Handle different response formats - server returns 'orderId' not 'razorpay_order_id'
      final razorpayOrderId =
          orderData['orderId']?.toString() ??
          orderData['razorpay_order_id']?.toString() ??
          '';

      // Server returns amount in rupees, but we need paise for Razorpay
      final serverAmount = orderData['amount'] as int? ?? 0;
      final amountInPaise = serverAmount * 100; // Convert rupees to paise

      // Use orderId as both order ID and razorpay order ID since server returns orderId
      currentOrderId.value = orderData['orderId']?.toString() ?? '';
      currentRazorpayOrderId.value = razorpayOrderId;

      // Validate that we got proper order details
      if (razorpayOrderId.isEmpty) {
        throw Exception('Order ID not received from server');
      }
      if (currentOrderId.value.isEmpty) {
        throw Exception('Order ID not received from server');
      }

      print('✅ Order created successfully');
      print('📋 Order ID: ${currentOrderId.value}');
      print('🔍 Razorpay Order ID: $razorpayOrderId');
      print('💰 Amount: $amountInPaise paise');
      print(
        '💰 Original Amount: ${orderData['amount']} ${orderData['currency']}',
      );

      // Close processing dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Step 2: Open Razorpay with proper configuration
      Map<String, dynamic> options = {
        'key': _razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'order_id': razorpayOrderId,
        'name': 'RiDeal - Non Vehicle Driver',
        'description': '${plan.title} Subscription',
        'retry': {'enabled': false},
        'send_sms_hash': true,
        'prefill': {
          'contact': phone,
          'email': email.isNotEmpty ? email : null,
          'name': name.isNotEmpty ? name : null,
        },
        'external': {
          'wallets': ['paytm', 'gpay', 'phonepe', 'amazon_pay'],
        },
        'theme': {'color': '#FF6600'},
        // Prevent redirect issues
        'redirect': false,
        'callback_url': null,
        'cancel_url': null,
      };

      print('🚀 Opening Razorpay payment gateway...');
      print('📱 Options: $options');

      _razorpay.open(options);
    } catch (e) {
      print('❌ Purchase error: $e');
      _handlePurchaseError(e.toString());
    }
  }

  /// Create subscription order using optimized non-vehicle API
  Future<Map<String, dynamic>> _createSubscriptionOrder({
    required String driverId,
    required String planId,
    required int amount,
  }) async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/api/non-vehicle-driver/buy-subscription';
      print('📡⚡ Fast creating order: $url');

      // Create HTTP client with timeout
      final client = http.Client();

      try {
        final response = await client
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'driverId': driverId,
                'planId': planId,
                'amount': amount, // Amount in paise
              }),
            )
            .timeout(
              const Duration(
                seconds: 8,
              ), // 🚀 8 second timeout for order creation
              onTimeout: () {
                throw Exception(
                  'Order creation timed out. Please check your internet connection.',
                );
              },
            );

        print('📥⚡ Fast Order Response Status: ${response.statusCode}');
        print('📥⚡ Fast Order Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('📊 Parsed Order Data: $data');

          // Debug the structure
          if (data is Map<String, dynamic>) {
            print('🔍 Available keys in response: ${data.keys.toList()}');
            if (data.containsKey('orderId')) {
              print('🔑 Found orderId: ${data['orderId']}');
            }
            if (data.containsKey('razorpay_order_id')) {
              print('🔑 Found razorpay_order_id: ${data['razorpay_order_id']}');
            }
            if (data.containsKey('amount')) {
              print(
                '🔑 Found amount: ${data['amount']} (will convert to paise)',
              );
            }
          }

          return {'success': true, 'data': data};
        } else {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to create order',
          };
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('❌ Order creation error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Load subscription plans with default fallback
  Future<void> setupSubscriptionPlans() async {
    print('🔄 Loading non-vehicle subscription plans...');
    isLoading.value = true;
    hasError.value = false;

    try {
      // For now, use default plans since API endpoint may not be ready
      _createDefaultPlans();
      print('✅ Using default non-vehicle subscription plans');
    } catch (e) {
      print('❌ Error loading plans: $e');
      _createDefaultPlans();
    } finally {
      isLoading.value = false;
    }
  }

  /// Create default non-vehicle subscription plans
  void _createDefaultPlans() {
    subscriptionPlans.value = [
      SubscriptionPlan(
        id: 'monthly_standard',
        title: 'Monthly Standard',
        rate: 199,
        durationInMonths: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      SubscriptionPlan(
        id: 'quarterly_pro',
        title: 'Quarterly Pro',
        rate: 499,
        durationInMonths: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      SubscriptionPlan(
        id: 'annual_premium',
        title: 'Annual Premium',
        rate: 1599,
        durationInMonths: 12,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    print(
      '📦 Created ${subscriptionPlans.length} default non-vehicle subscription plans',
    );
  }

  /// Generate fallback signature when Razorpay doesn't provide one
  String _generateFallbackSignature(String paymentId) {
    // Create a simple fallback signature using payment ID and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '${paymentId}_${currentRazorpayOrderId.value}_$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    print('🔧 Generated fallback signature for payment: $paymentId');
    return digest.toString();
  }

  /// Verify payment using optimized non-vehicle API with timeout
  /// Verify payment using optimized non-vehicle API with timeout
  Future<void> _verifyPaymentWithOptimizedAPI({
    required String driverId,
    required String planId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      print('🔍 Starting verification with:');
      print('   Driver ID: $driverId');
      print('   Plan ID: $planId');
      print('   Payment ID: $razorpayPaymentId');
      print('   Order ID: $razorpayOrderId');
      print('   Signature: $razorpaySignature');

      // Validate required fields before making API call
      if (razorpayOrderId.trim().isEmpty) {
        throw Exception('Razorpay Order ID is required for verification');
      }
      if (razorpayPaymentId.trim().isEmpty) {
        throw Exception('Razorpay Payment ID is required for verification');
      }
      if (driverId.trim().isEmpty) {
        throw Exception('Driver ID is required for verification');
      }
      if (planId.trim().isEmpty) {
        throw Exception('Plan ID is required for verification');
      }

      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = '$baseUrl/api/non-vehicle-driver/verify-payment';
      print('🔐⚡ Fast verifying payment: $url');

      // Create HTTP client with timeout
      final client = http.Client();

      try {
        final requestBody = {
          'driverId': driverId,
          'planId': planId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
        };

        print('📤 Request body: $requestBody');

        final response = await client
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(
                seconds: 10,
              ), // 🚀 10 second timeout instead of default 30+ seconds
              onTimeout: () {
                throw Exception(
                  'Payment verification timed out. Please check your internet connection.',
                );
              },
            );

        print('📥⚡ Fast Verification Response Status: ${response.statusCode}');
        print('📥⚡ Fast Verification Response Body: ${response.body}');

        if (Get.isDialogOpen == true) {
          Get.back(); // Close processing dialog
        }

        if (response.statusCode == 200) {
          print('✅⚡ Payment verified successfully in fast mode!');

          // Parse response for better handling
          try {
            final responseData = jsonDecode(response.body);
            print('📊 Parsed response: $responseData');
          } catch (e) {
            print('⚠️ Could not parse response as JSON: $e');
          }

          // 🚀 CRITICAL: Immediate status update for UI refresh
          print(
            '🔄 === TRIGGERING STATUS UPDATE AFTER PAYMENT VERIFICATION ===',
          );
          _quickUpdateSubscriptionStatus();

          // Reset payment state
          isProcessingPayment.value = false;
          selectedPlanId.value = '';
          currentOrderId.value = '';
          currentRazorpayOrderId.value = '';

          // Show success message immediately
          _showFastSuccessDialog();
        } else {
          try {
            final errorData = jsonDecode(response.body);
            final errorMessage =
                errorData['message'] ?? 'Payment verification failed';
            print('❌ Verification failed: $errorMessage');
            _handlePurchaseError('Verification failed: $errorMessage');
          } catch (e) {
            print(
              '❌ Verification failed with status ${response.statusCode}: ${response.body}',
            );
            _handlePurchaseError(
              'Verification failed with status ${response.statusCode}',
            );
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('❌ Verification error: $e');
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      _handlePurchaseError('Verification error: $e');
    }
  }

  /// Show processing dialog
  void _showProcessingDialog(String message) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange[700]),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 8),
              Text(
                'Please wait...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Show fast processing dialog with shorter message
  void _showFastProcessingDialog(String message) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.green[700],
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                'Almost done!',
                style: TextStyle(fontSize: 11, color: Colors.green[600]),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Quick update subscription status without full API call
  void _quickUpdateSubscriptionStatus() {
    print('⚡ === PAYMENT SUCCESS - UPDATING SUBSCRIPTION STATUS ===');

    // Update local state immediately to show "active" status
    subscriptionStatus.value =
        'active'; // Changed from 'subscribed' to 'active'
    currentPlanId.value = _currentPlan?.id ?? selectedPlanId.value;
    currentPlanName.value = _currentPlan?.title ?? '';

    // Set expiry date based on plan duration
    if (_currentPlan != null) {
      final now = DateTime.now();
      expiryDate.value = DateTime(
        now.year,
        now.month + _currentPlan!.durationInMonths,
        now.day,
      );
      startDate.value = now;

      print('📅 Set expiry date: ${expiryDate.value}');
      print('📅 Set start date: ${startDate.value}');
    }

    // Trigger immediate API refresh to sync with backend
    print('🚀 Triggering IMMEDIATE full status refresh from server...');
    loadSubscriptionStatus().then((_) {
      print('🎉 Status refresh completed after payment!');

      // Force UI update to ensure all widgets refresh
      update();

      // Show final success notification
      showSuccessSnackBar(
        'Welcome to ${currentPlanName.value}! Your subscription is now active.',
        title: '🎆 Subscription Activated!',
      );
    });

    print('⚡ Quick status update initiated!');
    print('📊 Status: ${subscriptionStatus.value}');
    print('📋 Plan: ${currentPlanName.value}');
  }

  /// Show fast success dialog
  void _showFastSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.rocket_launch, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('🎉 Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment verified! Subscription activated! 🚀'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    '${_currentPlan?.title ?? "Plan"} - ₹${_currentPlan?.rate ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (expiryDate.value != null)
                    Text(
                      'Valid until: ${expiryDate.value!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Quick navigation
              Get.offAllNamed(Routes.NONVEHICHLEDASHBOARD);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Go to Dashboard 🚀'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Handle purchase errors (enhanced)
  void _handlePurchaseError(String error) {
    print('❌ Purchase error: $error');

    if (Get.isDialogOpen == true) {
      Get.back();
    }

    isProcessingPayment.value = false;
    selectedPlanId.value = '';
    hasError.value = true;
    errorMessage.value = error;

    _showErrorSnackbar(error);
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    showErrorSnackBar(message);
  }

  /// Test method to check API response format
  Future<void> testOrderCreation() async {
    try {
      print('🧪 Testing order creation API...');

      if (driverId == null || driverId!.isEmpty) {
        print('❌ No driver ID for testing');
        return;
      }

      final testOrderResponse = await _createSubscriptionOrder(
        driverId: driverId!,
        planId: 'test_plan_id',
        amount: 10000, // ₹100 in paise
      );

      print('🧪 Test Order Response: $testOrderResponse');
    } catch (e) {
      print('❌ Test order creation failed: $e');
    }
  }

  /// Simulate successful payment (for testing)
  void simulateSuccessfulPayment() {
    print('🧪 Simulating successful payment...');

    subscriptionStatus.value = 'active';
    expiryDate.value = DateTime.now().add(const Duration(days: 30));

    showSuccessSnackBar(
      'Subscription activated in test mode',
      title: 'Test Mode',
    );

    Future.delayed(const Duration(seconds: 1), () {
      Get.offAllNamed(Routes.NONVEHICHLEDASHBOARD);
    });
  }

  /// Refresh subscription status (for pull-to-refresh)
  Future<void> refreshSubscriptionStatus() async {
    await loadSubscriptionStatus();
    if (subscriptionPlans.isEmpty) {
      await setupSubscriptionPlans();
    }
  }

  /// Check if subscription is active
  bool get isSubscriptionActive {
    final status = subscriptionStatus.value.toLowerCase();
    return status == 'active' || status == 'subscribed';
  }

  /// Get days remaining in subscription
  int? get daysRemaining {
    if (expiryDate.value == null) return null;
    final now = DateTime.now();
    final difference = expiryDate.value!.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }
}
