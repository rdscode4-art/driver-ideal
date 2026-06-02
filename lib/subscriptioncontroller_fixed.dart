// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:rideal_driver/subscriptionrepository.dart';
// import 'package:rideal_driver/core/storage_helper.dart';
// import '../core/token_manager.dart';

// class SubscriptionPlan {
//   final String id;
//   final String title;
//   final int rate;
//   final int durationInMonths;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   SubscriptionPlan({
//     required this.id,
//     required this.title,
//     required this.rate,
//     required this.durationInMonths,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
//     return SubscriptionPlan(
//       id: json['_id']?.toString() ?? '',
//       title: json['title'] ?? '',
//       rate: json['rate'] ?? 0,
//       durationInMonths: json['durationInMonths'] ?? 0,
//       createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
//       updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'title': title,
//       'rate': rate,
//       'durationInMonths': durationInMonths,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }
// }

// class SubscriptionController extends GetxController {
//   static SubscriptionController get instance => Get.find();

//   // Razorpay configuration
//   static const String _razorpayKeyId = 'rzp_test_RnX4Oatt9zSiqS';
//   late Razorpay _razorpay;

//   // Repository and dependencies
//   final SubscriptionRepository _repository = SubscriptionRepository();
//   final TokenManager _tokenManager = Get.find<TokenManager>();

//   // Observable variables
//   RxBool isLoading = false.obs;
//   RxBool isProcessingPayment = false.obs;
//   RxBool hasSubscription = false.obs;
//   RxList<SubscriptionPlan> subscriptionPlans = <SubscriptionPlan>[].obs;
//   RxString selectedPlanId = ''.obs;
//   RxString currentOrderId = ''.obs;
//   Rx<String?> orderId = Rx<String?>(null);
//   Rx<String?> paymentId = Rx<String?>(null);
//   Rx<String?> signature = Rx<String?>(null);
//   RxBool hasError = false.obs;
//   RxString errorMessage = ''.obs;

//   // Current subscription details
//   RxBool subscriptionActive = false.obs;
//   Rx<DateTime?> expiryDate = Rx<DateTime?>(null);
//   RxString subscriptionStatus = 'inactive'.obs;

//   // Current plan being processed
//   SubscriptionPlan? _currentPlan;

//   // Alias for backward compatibility
//   bool get isSubscriptionActive => subscriptionActive.value;
//   String? get driverId => _tokenManager.driverId;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeRazorpay();
//     loadSubscriptionStatus();
//     loadSubscriptionPlans();
//   }

//   void _initializeRazorpay() {
//     print('🚀 Initializing Razorpay for subscription payments...');

//     _razorpay = Razorpay();

//     // Set up event listeners with comprehensive debugging
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//     print('✅ Razorpay initialized with event listeners');
//     print('📋 Success Event: ${Razorpay.EVENT_PAYMENT_SUCCESS}');
//     print('❌ Error Event: ${Razorpay.EVENT_PAYMENT_ERROR}');
//     print('🏦 Wallet Event: ${Razorpay.EVENT_EXTERNAL_WALLET}');
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     print('\n🎉 ════════════════════════════════════════════════════════');
//     print('🎉         SUBSCRIPTION PAYMENT SUCCESS!');
//     print('🎉 ════════════════════════════════════════════════════════');
//     print('💳 Payment ID: ${response.paymentId}');
//     print('📋 Order ID: ${response.orderId}');
//     print('🔐 Signature: ${response.signature}');
//     print('📋 Plan: ${_currentPlan?.title ?? 'Unknown'}');
//     print('💰 Amount: ₹${_currentPlan?.rate ?? 0}');
//     print('⏰ Success Time: ${DateTime.now().toIso8601String()}');
//     print('🎉 ════════════════════════════════════════════════════════\n');

//     // Store payment details for verification
//     paymentId.value = response.paymentId;
//     orderId.value = response.orderId;
//     signature.value = response.signature;

//     // Validate payment response
//     if (response.paymentId?.isEmpty == true ||
//         response.orderId?.isEmpty == true ||
//         response.signature?.isEmpty == true) {
//       print('❌ INVALID RAZORPAY RESPONSE - Missing Required Fields');
//       Get.snackbar(
//         'Payment Error',
//         'Invalid payment response received. Please try again.',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[800],
//         duration: const Duration(seconds: 5),
//       );
//       return;
//     }

//     // Show success message
//     Get.snackbar(
//       '🎉 Payment Successful!',
//       'Payment ID: ${response.paymentId}\nVerifying with server...',
//       backgroundColor: Colors.green[100],
//       colorText: Colors.green[800],
//       duration: const Duration(seconds: 5),
//     );

//     // Start payment verification
//     _verifyPayment();
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     print('\n❌ ════════════════════════════════════════════════════════');
//     print('❌         SUBSCRIPTION PAYMENT FAILED!');
//     print('❌ ════════════════════════════════════════════════════════');
//     print('🚫 Error Code: ${response.code}');
//     print('📝 Error Message: ${response.message}');
//     print('⏰ Failure Time: ${DateTime.now().toIso8601String()}');
//     print('❌ ════════════════════════════════════════════════════════\n');

//     isProcessingPayment.value = false;

//     // Show user-friendly error message
//     Get.snackbar(
//       '❌ Payment Failed',
//       'Error: ${response.message ?? 'Unknown error'}\nCode: ${response.code}',
//       backgroundColor: Colors.red[100],
//       colorText: Colors.red[800],
//       duration: const Duration(seconds: 5),
//     );
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     print('\n🏦 ════════════════════════════════════════════════════════');
//     print('🏦         EXTERNAL WALLET PAYMENT!');
//     print('🏦 ════════════════════════════════════════════════════════');
//     print('💳 Wallet Name: ${response.walletName}');
//     print('⏰ Wallet Time: ${DateTime.now().toIso8601String()}');
//     print('🏦 ════════════════════════════════════════════════════════\n');

//     Get.snackbar(
//       '🏦 External Wallet',
//       'Opening ${response.walletName}...',
//       backgroundColor: Colors.blue[100],
//       colorText: Colors.blue[800],
//     );
//   }

//   Future<void> loadSubscriptionStatus() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedSubscription = prefs.getBool('subscription_active') ?? false;
//       final savedExpiry = prefs.getString('subscription_expiry');

//       subscriptionActive.value = savedSubscription;
//       hasSubscription.value = savedSubscription;

//       if (savedExpiry != null) {
//         expiryDate.value = DateTime.parse(savedExpiry);

//         // Check if subscription has expired
//         if (expiryDate.value != null &&
//             expiryDate.value!.isBefore(DateTime.now())) {
//           subscriptionActive.value = false;
//           hasSubscription.value = false;
//           await _clearSubscriptionData();
//         }
//       }

//       print('📊 Subscription Status Loaded: ${hasSubscription.value}');
//       if (hasSubscription.value && expiryDate.value != null) {
//         print('✅ Subscription active until: ${expiryDate.value}');
//       }
//     } catch (e) {
//       print('❌ Error loading subscription status: $e');
//     }
//   }

//   Future<void> loadSubscriptionPlans() async {
//     try {
//       isLoading.value = true;
//       hasError.value = false;

//       print('🔄 Loading subscription plans...');
//       final response = await _repository.getSubscriptionPlans();

//       if (response['success'] == true && response['data'] != null) {
//         final List<dynamic> plansData = response['data'];
//         subscriptionPlans.value = plansData
//             .map((plan) => SubscriptionPlan.fromJson(plan))
//             .toList();

//         print(
//           '✅ Successfully loaded ${subscriptionPlans.length} subscription plans',
//         );

//         // Debug: Print plan details
//         for (var plan in subscriptionPlans) {
//           print(
//             '📋 Plan: ${plan.title} - ₹${plan.rate} for ${plan.durationInMonths} months',
//           );
//         }
//       } else {
//         throw Exception(response['message'] ?? 'Failed to load plans');
//       }
//     } catch (e) {
//       print('❌ Error loading subscription plans: $e');
//       hasError.value = true;
//       errorMessage.value =
//           'Failed to load subscription plans. Please check your internet connection and try again.';

//       // Show user-friendly error
//       Get.snackbar(
//         '⚠️ Connection Issue',
//         'Unable to load subscription plans. Please try again.',
//         backgroundColor: Colors.orange[100],
//         colorText: Colors.orange[800],
//       );

//       // Create default plans as fallback
      
//     } finally {
//       isLoading.value = false;
//     }
//   }

 
//   Future<void> buySubscription(SubscriptionPlan plan) async {
//     try {
//       if (driverId == null || driverId!.isEmpty) {
//         throw Exception('Driver ID not found. Please login again.');
//       }

//       print('\n🚀 ===== STARTING SUBSCRIPTION PURCHASE =====');
//       print('📦 Plan: ${plan.title}');
//       print('💰 Amount: ₹${plan.rate}');
//       print('👤 Driver: $driverId');

//       isProcessingPayment.value = true;
//       selectedPlanId.value = plan.id;
//       _currentPlan = plan;

//       // Create order with backend
//       print('📡 Creating order with backend...');
//       final response = await _repository.buySubscription(
//         driverId!,
//         plan.id,
//         planType: plan.title,
//         amount: plan.rate * 100, // Convert to paise
//       );

//       if (response['success'] != true) {
//         throw Exception(response['message'] ?? 'Failed to create order');
//       }

//       final orderIdValue = response['orderId']?.toString() ?? '';
//       final amountInPaise = response['amount'] as int? ?? 0;

//       print('✅ Order created: $orderIdValue');
//       print('💰 Amount: $amountInPaise paise');

//       // Store order details
//       currentOrderId.value = orderIdValue;

//       // Get driver details
//       final phone = await getDriverPhone();
//       final email = await getDriverEmail();
//       final name = await getDriverName();

//       // Prepare Razorpay options
//       var options = {
//         'key': _razorpayKeyId,
//         'amount': amountInPaise,
//         'currency': 'INR',
//         'order_id': orderIdValue,
//         'name': 'RiDeal Driver',
//         'description': '${plan.title} Subscription',
//         'prefill': {'contact': phone, 'email': email, 'name': name},
//         'theme': {'color': '#2196F3'},
//         'notes': {
//           'driver_id': driverId,
//           'plan_type': plan.title,
//           'plan_id': plan.id,
//         },
//       };

//       print('🚀 Opening Razorpay checkout...');
//       print('📋 Final Options:');
//       print('   Key: ${options['key']}');
//       print('   Amount: ${options['amount']} paise');
//       print('   Order ID: ${options['order_id']}');

//       // Open Razorpay checkout
//       _razorpay.open(options);

//       print('✅ Checkout opened - waiting for payment completion...');
//     } catch (e) {
//       print('❌ Subscription purchase error: $e');

//       isProcessingPayment.value = false;
//       selectedPlanId.value = '';
//       _currentPlan = null;

//       Get.snackbar(
//         '❌ Payment Error',
//         'Failed to start payment: $e',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[800],
//       );
//     }
//   }

//   Future<void> _verifyPayment() async {
//     print('\n🔍 ════════════════════════════════════════════════════════');
//     print('🔍           STARTING PAYMENT VERIFICATION');
//     print('🔍 ════════════════════════════════════════════════════════');

//     try {
//       if (paymentId.value == null ||
//           orderId.value == null ||
//           signature.value == null) {
//         throw Exception('Payment verification data missing');
//       }

//       print('📡 Calling backend verification API...');
//       final response = await _repository.verifyPayment(
//         driverId: driverId!,
//         planId: selectedPlanId.value,
//         razorpayPaymentId: paymentId.value!,
//         razorpayOrderId: orderId.value!,
//         razorpaySignature: signature.value!,
//       );

//       if (response['success'] == true) {
//         print('🎉 Payment verified successfully!');

//         final expiryDateStr = response['data']['expiryDate'];
//         DateTime? expiry;
//         if (expiryDateStr != null) {
//           expiry = DateTime.tryParse(expiryDateStr);
//         }

//         await _saveSubscriptionStatus(true, expiry: expiry);
//         await loadSubscriptionStatus();

//         Get.snackbar(
//           '🎉 Subscription Activated!',
//           'Your subscription is now active!',
//           backgroundColor: Colors.green[100],
//           colorText: Colors.green[800],
//           duration: const Duration(seconds: 5),
//         );
//       } else {
//         throw Exception(response['message'] ?? 'Payment verification failed');
//       }
//     } catch (e) {
//       print('❌ Payment verification failed: $e');

//       Get.snackbar(
//         '❌ Verification Failed',
//         'Payment verification failed: $e',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[800],
//       );
//     } finally {
//       isProcessingPayment.value = false;
//       selectedPlanId.value = '';
//       _currentPlan = null;
//     }
//   }

//   Future<void> _saveSubscriptionStatus(bool active, {DateTime? expiry}) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('subscription_active', active);

//       if (expiry != null) {
//         await prefs.setString('subscription_expiry', expiry.toIso8601String());
//       }

//       subscriptionActive.value = active;
//       hasSubscription.value = active;
//       expiryDate.value = expiry;

//       print('💾 Subscription Status Saved: $active');
//     } catch (e) {
//       print('❌ Error saving subscription status: $e');
//     }
//   }

//   Future<void> _clearSubscriptionData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('subscription_active');
//       await prefs.remove('subscription_expiry');

//       subscriptionActive.value = false;
//       hasSubscription.value = false;
//       expiryDate.value = null;
//     } catch (e) {
//       print('❌ Error clearing subscription data: $e');
//     }
//   }

//   // Helper methods for driver details
//   Future<String> getDriverPhone() async {
//     try {
//       return await StorageHelper.getDriverPhone() ?? '9999999999';
//     } catch (e) {
//       return '9999999999';
//     }
//   }

//   Future<String> getDriverEmail() async {
//     try {
//       return await StorageHelper.getDriverEmail() ?? 'driver@rideal.app';
//     } catch (e) {
//       return 'driver@rideal.app';
//     }
//   }

//   Future<String> getDriverName() async {
//     try {
//       return await StorageHelper.getDriverName() ?? 'Driver';
//     } catch (e) {
//       return 'Driver';
//     }
//   }

//   bool canUploadProduct() {
//     return hasSubscription.value && subscriptionActive.value;
//   }

//   @override
//   void onClose() {
//     _razorpay.clear();
//     super.onClose();
//   }
// }
