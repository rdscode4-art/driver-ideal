// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// /// Enhanced error diagnostic and fix utility
// /// Addresses both Razorpay closure errors and ongoing ride check failures
// class PaymentErrorFixer {
//   /// Fix Razorpay closure serialization errors
//   static Map<String, dynamic> getSafeRazorpayOptions({
//     required String keyId,
//     required int amount,
//     required String orderId,
//     required String phone,
//     required String email,
//     required String name,
//     required String planTitle,
//     required String driverId,
//   }) {
//     print('🔧 Creating safe Razorpay options without closures...');

//     // Return only serializable options - NO CLOSURES
//     return {
//       'key': keyId,
//       'amount': amount,
//       'currency': 'INR',
//       'name': 'RiDeal Driver',
//       'description': 'Subscription: $planTitle',
//       'order_id': orderId,
//       'timeout': 300, // 5 minutes - reasonable timeout
//       'prefill': {'contact': phone, 'email': email, 'name': name},
//       'theme': {'color': '#2196F3'},
//       'modal': {
//         'confirm_close': true,
//         'backdropclose': false,
//         'escape': false,
//         'handleback': true,
//       },
//       'retry': {'enabled': true, 'max_count': 2},
//       'method': {'upi': true, 'card': true, 'netbanking': true, 'wallet': true},
//       'notes': {'driver_id': driverId, 'plan_type': planTitle},
//     };
//   }

//   /// Test Razorpay configuration safety
//   static bool testRazorpayConfigSafety(Map<String, dynamic> options) {
//     try {
//       // Try to encode the options as JSON to test serialization
//       final jsonString = jsonEncode(options);
//       print('✅ Razorpay options are serializable');
//       print('📝 Options size: ${jsonString.length} characters');
//       return true;
//     } catch (e) {
//       print('❌ Razorpay options contain non-serializable data: $e');
//       return false;
//     }
//   }

//   /// Enhanced error handling for payment failures
//   static void handlePaymentError({
//     required int errorCode,
//     required String? errorMessage,
//     required VoidCallback onRetryRazorpay,
//     required VoidCallback onTryUPI,
//     required VoidCallback onCancel,
//   }) {
//     print('🚨 Payment Error Handler Called');
//     print('   Error Code: $errorCode');
//     print('   Error Message: $errorMessage');

//     String friendlyMessage;
//     bool showAlternatives = false;

//     switch (errorCode) {
//       case 0: // Payment cancelled
//         friendlyMessage = 'Payment was cancelled. Would you like to try again?';
//         showAlternatives = true;
//         break;
//       case 1: // Network error
//         friendlyMessage =
//             'Network error detected. Please check your connection.';
//         showAlternatives = true;
//         break;
//       case 2: // Payment failed
//         friendlyMessage =
//             'Payment processing failed. Please try an alternative method.';
//         showAlternatives = true;
//         break;
//       case 3: // Invalid credentials
//         friendlyMessage =
//             'Payment gateway configuration issue. Please try UPI payment.';
//         showAlternatives = true;
//         break;
//       default:
//         friendlyMessage = errorMessage ?? 'An unknown payment error occurred.';
//         showAlternatives = true;
//     }

//     // Show error dialog with alternatives
//     if (showAlternatives) {
//       _showPaymentErrorDialog(
//         friendlyMessage,
//         onRetryRazorpay,
//         onTryUPI,
//         onCancel,
//       );
//     } else {
//       // Just show simple message for cancellation
//       print('ℹ️ Payment cancelled by user');
//     }
//   }

//   /// Show payment error dialog with alternatives
//   static void _showPaymentErrorDialog(
//     String message,
//     VoidCallback onRetryRazorpay,
//     VoidCallback onTryUPI,
//     VoidCallback onCancel,
//   ) {
//     // This would be implemented in the actual controller
//     // Here we just print the options
//     print('💬 Would show error dialog with message: $message');
//     print('   Options: Retry Razorpay | Try UPI | Cancel');
//   }

//   /// Run comprehensive payment diagnostic
//   static Future<void> runPaymentDiagnostic() async {
//     print('🔍 === PAYMENT SYSTEM DIAGNOSTIC ===');
//     print('📅 ${DateTime.now()}');
//     print('');

//     // Test 1: Razorpay Configuration Safety
//     print('🧪 TEST 1: Razorpay Configuration Safety');
//     final testOptions = getSafeRazorpayOptions(
//       keyId: 'rzp_test_example',
//       amount: 100,
//       orderId: 'order_test123',
//       phone: '9999999999',
//       email: 'test@example.com',
//       name: 'Test User',
//       planTitle: 'Test Plan',
//       driverId: 'driver123',
//     );

//     final isConfigSafe = testRazorpayConfigSafety(testOptions);
//     print('   Result: ${isConfigSafe ? "✅ PASS" : "❌ FAIL"}');
//     print('');

//     // Test 2: Network Connectivity
//     print('🧪 TEST 2: Network Connectivity');
//     final isNetworkOk = await testNetworkConnectivity();
//     print('   Result: ${isNetworkOk ? "✅ PASS" : "❌ FAIL"}');
//     print('');

//     // Test 3: Backend API Health
//     print('🧪 TEST 3: Backend API Health');
//     final isBackendOk = await testBackendHealth();
//     print('   Result: ${isBackendOk ? "✅ PASS" : "❌ FAIL"}');
//     print('');

//     // Overall Result
//     final overallPass = isConfigSafe && isNetworkOk && isBackendOk;
//     print(
//       '📊 OVERALL RESULT: ${overallPass ? "✅ ALL TESTS PASS" : "⚠️ ISSUES DETECTED"}',
//     );

//     if (!overallPass) {
//       print('');
//       print('💡 RECOMMENDATIONS:');
//       if (!isConfigSafe) {
//         print('   • Fix Razorpay configuration (remove closures)');
//       }
//       if (!isNetworkOk) print('   • Check network connection');
//       if (!isBackendOk) print('   • Verify backend API endpoints');
//     }

//     print('');
//     print('🔍 === END DIAGNOSTIC ===');
//   }

//   /// Test network connectivity
//   static Future<bool> testNetworkConnectivity() async {
//     try {
//       final response = await http
//           .get(Uri.parse('https://www.google.com'))
//           .timeout(const Duration(seconds: 5));

//       return response.statusCode == 200;
//     } catch (e) {
//       print('   Network test failed: $e');
//       return false;
//     }
//   }

//   /// Test backend API health
//   static Future<bool> testBackendHealth() async {
//     try {
//       final response = await http
//           .get(Uri.parse('https://backend.ridealmobility.com/health'))
//           .timeout(const Duration(seconds: 10));

//       return response.statusCode == 200;
//     } catch (e) {
//       print('   Backend health check failed: $e');
//       // Try alternative endpoint
//       try {
//         final altResponse = await http
//             .get(Uri.parse('https://backend.ridealmobility.com/status'))
//             .timeout(const Duration(seconds: 5));
//         return altResponse.statusCode == 200;
//       } catch (e2) {
//         print('   Alternative endpoint also failed: $e2');
//         return false;
//       }
//     }
//   }

//   /// Generate safe Razorpay options for production use
//   static Map<String, dynamic> generateProductionRazorpayOptions({
//     required String razorpayKey,
//     required String orderId,
//     required int amountInPaise,
//     required String userPhone,
//     required String userEmail,
//     required String userName,
//     required String planTitle,
//     required String driverId,
//   }) {
//     // Validate inputs
//     if (razorpayKey.isEmpty || !razorpayKey.startsWith('rzp_')) {
//       throw ArgumentError('Invalid Razorpay key: $razorpayKey');
//     }

//     if (orderId.isEmpty || !orderId.startsWith('order_')) {
//       throw ArgumentError('Invalid order ID: $orderId');
//     }

//     if (amountInPaise <= 0) {
//       throw ArgumentError('Invalid amount: $amountInPaise');
//     }

//     // Clean phone number
//     final cleanPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');
//     final validPhone = cleanPhone.length >= 10
//         ? cleanPhone.substring(cleanPhone.length - 10)
//         : '9999999999';

//     // Generate safe options
//     final options = getSafeRazorpayOptions(
//       keyId: razorpayKey,
//       amount: amountInPaise,
//       orderId: orderId,
//       phone: validPhone,
//       email: userEmail.trim().isEmpty ? 'driver@rideal.app' : userEmail.trim(),
//       name: userName.trim().isEmpty ? 'Driver' : userName.trim(),
//       planTitle: planTitle,
//       driverId: driverId,
//     );

//     // Validate safety
//     if (!testRazorpayConfigSafety(options)) {
//       throw StateError(
//         'Generated Razorpay options are not safe for serialization',
//       );
//     }

//     print('✅ Generated safe Razorpay options for production');
//     return options;
//   }
// }
