// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:rideal_driver/subscriptionrepository.dart';
// import 'package:rideal_driver/core/storage_helper.dart';

// // Simple subscription plan model
// class SubscriptionPlan {
//   final String id;
//   final String title;
//   final int rate;
//   final int durationInMonths;

//   SubscriptionPlan({
//     required this.id,
//     required this.title,
//     required this.rate,
//     required this.durationInMonths,
//   });

//   factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
//     return SubscriptionPlan(
//       id: json['_id']?.toString() ?? '',
//       title: json['title'] ?? '',
//       rate: json['rate'] ?? 0,
//       durationInMonths: json['durationInMonths'] ?? 0,
//     );
//   }
// }

// class SimpleSubscriptionController extends GetxController {
//   late Razorpay _razorpay;
//   final _repository = SubscriptionRepository();

//   // Observables
//   var isProcessingPayment = false.obs;
//   var hasSubscription = false.obs;
//   var subscriptionPlans = <SubscriptionPlan>[].obs;
//   var selectedPlanId = ''.obs;

//   // Driver data
//   String? driverId;
//   String? driverPhone;
//   String? driverEmail;
//   String? driverName;

//   // Current plan being processed
//   SubscriptionPlan? _currentPlan;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeRazorpay();
//     _loadDriverData();
//   }

//   void _initializeRazorpay() {
//     print('🚀 Initializing Simple Razorpay...');

//     _razorpay = Razorpay();

//     // Set up event listeners with proper debugging
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//     print('✅ Razorpay event listeners registered');
//     print('📋 Success: ${Razorpay.EVENT_PAYMENT_SUCCESS}');
//     print('❌ Error: ${Razorpay.EVENT_PAYMENT_ERROR}');
//     print('🏦 Wallet: ${Razorpay.EVENT_EXTERNAL_WALLET}');
//   }

//   void _loadDriverData() async {
//     try {
//       driverId = await StorageHelper.getDriverId();
//       // Use hardcoded values for testing
//       driverPhone = '9999999999';
//       driverEmail = 'driver@rideal.app';
//       driverName = 'Test Driver';

//       print('📱 Driver loaded: $driverName ($driverPhone)');
//     } catch (e) {
//       print('❌ Error loading driver data: $e');
//     }
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     print('\n🚨🚨🚨 RAZORPAY SUCCESS CALLBACK FIRED! 🚨🚨🚨');
//     print('💳 Payment ID: ${response.paymentId}');
//     print('📋 Order ID: ${response.orderId}');
//     print('🔐 Signature: ${response.signature}');
//     print('⏰ Time: ${DateTime.now().toIso8601String()}');
//     print('🎯 Plan: ${_currentPlan?.title ?? 'Unknown'}');
//     print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//     // Validate response
//     if (response.paymentId?.isEmpty == true ||
//         response.orderId?.isEmpty == true ||
//         response.signature?.isEmpty == true) {
//       print('❌ Invalid payment response - missing data');
//       Get.snackbar(
//         'Payment Error',
//         'Invalid payment response received',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[800],
//       );
//       return;
//     }

//     // Success UI
//     Get.snackbar(
//       '🎉 Payment Successful!',
//       'Payment ID: ${response.paymentId}\nVerifying with server...',
//       backgroundColor: Colors.green[100],
//       colorText: Colors.green[800],
//       duration: const Duration(seconds: 5),
//     );

//     // Start verification
//     _verifyPaymentWithServer(response);
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     print('\n🚨🚨🚨 RAZORPAY ERROR CALLBACK FIRED! 🚨🚨🚨');
//     print('❌ Error Code: ${response.code}');
//     print('📝 Error Message: ${response.message}');
//     print('⏰ Time: ${DateTime.now().toIso8601String()}');
//     print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//     isProcessingPayment.value = false;

//     // Show error to user
//     String errorMessage = response.message ?? 'Payment failed';

//     Get.snackbar(
//       '❌ Payment Failed',
//       'Error: $errorMessage\nCode: ${response.code}',
//       backgroundColor: Colors.red[100],
//       colorText: Colors.red[800],
//       duration: const Duration(seconds: 5),
//     );
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     print('\n🚨🚨🚨 RAZORPAY WALLET CALLBACK FIRED! 🚨🚨🚨');
//     print('🏦 Wallet Name: ${response.walletName}');
//     print('⏰ Time: ${DateTime.now().toIso8601String()}');
//     print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//     Get.snackbar(
//       '🏦 External Wallet',
//       'Opening ${response.walletName}...',
//       backgroundColor: Colors.blue[100],
//       colorText: Colors.blue[800],
//     );
//   }

//   Future<void> _verifyPaymentWithServer(PaymentSuccessResponse response) async {
//     try {
//       print('🔍 Verifying payment with server...');

//       final verifyResponse = await _repository.verifyPayment(
//         driverId: driverId!,
//         planId: selectedPlanId.value,
//         razorpayPaymentId: response.paymentId!,
//         razorpayOrderId: response.orderId!,
//         razorpaySignature: response.signature!,
//       );

//       if (verifyResponse['success'] == true) {
//         print('✅ Payment verified successfully!');
//         hasSubscription.value = true;
//         isProcessingPayment.value = false;

//         Get.snackbar(
//           '🎉 Subscription Activated!',
//           'Your subscription is now active',
//           backgroundColor: Colors.green[100],
//           colorText: Colors.green[800],
//           duration: const Duration(seconds: 5),
//         );
//       } else {
//         print('❌ Payment verification failed: ${verifyResponse['message']}');

//         Get.snackbar(
//           '❌ Verification Failed',
//           verifyResponse['message'] ?? 'Payment verification failed',
//           backgroundColor: Colors.red[100],
//           colorText: Colors.red[800],
//         );
//       }
//     } catch (e) {
//       print('❌ Verification error: $e');

//       Get.snackbar(
//         '❌ Verification Error',
//         'Failed to verify payment: $e',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[800],
//       );
//     }
//   }

//   Future<void> startPayment(SubscriptionPlan plan) async {
//     try {
//       print('\n🚀 ===== STARTING SIMPLE PAYMENT FLOW =====');
//       print('📦 Plan: ${plan.title}');
//       print('💰 Amount: ₹${plan.rate}');
//       print('👤 Driver: $driverName');

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

//       final orderId = response['orderId']?.toString() ?? '';
//       final amountInPaise = response['amount'] as int? ?? 0;

//       print('✅ Order created: $orderId');
//       print('💰 Amount: $amountInPaise paise');

//       // Prepare Razorpay options
//       var options = {
//         'key': 'rzp_test_1DP5mmOlF5G5ag', // Your Razorpay key
//         'amount': amountInPaise,
//         'currency': 'INR',
//         'order_id': orderId,
//         'name': 'RiDeal Driver',
//         'description': '${plan.title} Subscription',
//         'prefill': {
//           'contact': driverPhone ?? '9999999999',
//           'email': driverEmail ?? 'driver@rideal.app',
//           'name': driverName ?? 'Driver',
//         },
//         'theme': {'color': '#2196F3'},
//         'modal': {'confirm_close': true},
//         'notes': {
//           'driver_id': driverId,
//           'plan_type': plan.title,
//           'plan_id': plan.id,
//         },
//       };

//       print('🚀 Opening Razorpay checkout...');
//       print('📋 Options prepared:');
//       print('   Key: ${options['key']}');
//       print('   Amount: ${options['amount']} paise');
//       print('   Order ID: ${options['order_id']}');

//       final prefill = options['prefill'] as Map<String, dynamic>?;
//       if (prefill != null) {
//         print('   Name: ${prefill['name']}');
//         print('   Phone: ${prefill['contact']}');
//       }

//       // Open Razorpay checkout
//       _razorpay.open(options);

//       print('✅ Checkout opened - waiting for payment completion...');
//       print('🔔 Callbacks should fire when user completes/cancels payment');
//     } catch (e) {
//       print('❌ Payment start error: $e');

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

//   @override
//   void onClose() {
//     _razorpay.clear();
//     super.onClose();
//   }
// }
