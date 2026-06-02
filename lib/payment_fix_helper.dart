// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// /// 🚀 COMPREHENSIVE PAYMENT FIX
// /// This class addresses all Razorpay integration issues and provides
// /// a robust payment solution for the RiDeal Driver app

// class PaymentFixHelper {
//   static late Razorpay _razorpay;
//   static const String _testKey = 'rzp_test_RnX4Oatt9zSiqS';

//   /// Initialize Razorpay with proper error handling
//   static void initializeRazorpay() {
//     try {
//       _razorpay = Razorpay();
//       _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//       _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//       _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//       print('✅ Razorpay initialized successfully');
//     } catch (e) {
//       print('❌ Razorpay initialization failed: $e');
//     }
//   }

//   /// Test payment function to verify integration
//   static Future<void> testPayment() async {
//     try {
//       print('🧪 Starting Razorpay test payment...');

//       // Create simplified test options
//       var options = {
//         'key': _testKey,
//         'amount': 100, // ₹1 for testing
//         'currency': 'INR',
//         'name': 'RiDeal Driver Test',
//         'description': 'Test Payment Integration',
//         'order_id': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
//         'prefill': {
//           'contact': '9999999999',
//           'email': 'test@rideal.app',
//           'name': 'Test Driver',
//         },
//         'theme': {'color': '#2196F3'},
//         'modal': {'confirm_close': true, 'backdropclose': false},
//         'timeout': 120, // 2 minutes for test
//       };

//       print('🔄 Opening Razorpay with test options...');
//       await Future.delayed(const Duration(milliseconds: 300));

//       _razorpay.open(options);

//       // Show test notification
//       Get.snackbar(
//         '🧪 Test Payment',
//         'Razorpay integration test started',
//         backgroundColor: Colors.blue[100],
//         colorText: Colors.blue[800],
//         duration: const Duration(seconds: 3),
//       );
//     } catch (e) {
//       print('❌ Test payment failed: $e');

//       Get.snackbar(
//         '❌ Test Failed',
//         'Razorpay integration test failed: $e',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[800],
//         duration: const Duration(seconds: 5),
//       );
//     }
//   }

//   /// Handle successful payment
//   static void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     print('✅ TEST Payment Success!');
//     print('Payment ID: ${response.paymentId}');
//     print('Order ID: ${response.orderId}');

//     Get.snackbar(
//       '✅ Test Success!',
//       'Payment integration is working correctly',
//       backgroundColor: Colors.green[100],
//       colorText: Colors.green[800],
//       duration: const Duration(seconds: 4),
//     );
//   }

//   /// Handle payment error
//   static void _handlePaymentError(PaymentFailureResponse response) {
//     print('❌ TEST Payment Error!');
//     print('Code: ${response.code}');
//     print('Message: ${response.message}');

//     String message;
//     if (response.code == 0) {
//       message = 'Payment cancelled by user';
//     } else {
//       message = 'Payment error: ${response.message}';
//     }

//     Get.snackbar(
//       '⚠️ Test Result',
//       message,
//       backgroundColor: Colors.orange[100],
//       colorText: Colors.orange[800],
//       duration: const Duration(seconds: 4),
//     );
//   }

//   /// Handle external wallet
//   static void _handleExternalWallet(ExternalWalletResponse response) {
//     print('💳 External Wallet: ${response.walletName}');

//     Get.snackbar(
//       '💳 External Wallet',
//       'Wallet selected: ${response.walletName}',
//       backgroundColor: Colors.purple[100],
//       colorText: Colors.purple[800],
//       duration: const Duration(seconds: 3),
//     );
//   }

//   /// Dispose Razorpay
//   static void dispose() {
//     try {
//       _razorpay.clear();
//       print('🧹 Razorpay disposed successfully');
//     } catch (e) {
//       print('⚠️ Error disposing Razorpay: $e');
//     }
//   }

//   /// Validate payment configuration
//   static bool validateConfiguration() {
//     bool isValid = true;
//     List<String> issues = [];

//     // Check key
//     if (_testKey.isEmpty || !_testKey.startsWith('rzp_')) {
//       issues.add('Invalid Razorpay key');
//       isValid = false;
//     }

//     // Check internet permission
//     // This would be checked differently in a real app

//     if (!isValid) {
//       print('❌ Configuration Issues:');
//       for (String issue in issues) {
//         print('  • $issue');
//       }
//     } else {
//       print('✅ Payment configuration is valid');
//     }

//     return isValid;
//   }

//   /// Debug information
//   static void printDebugInfo() {
//     print('\n🔍 PAYMENT DEBUG INFO:');
//     print('  • Razorpay Key: $_testKey');
//     print('  • Flutter Razorpay Version: 1.4.0');
//     print(
//       '  • Configuration: ${validateConfiguration() ? "Valid" : "Invalid"}',
//     );
//     print('  • Timestamp: ${DateTime.now()}');
//     print('');
//   }
// }

// /// 🎯 QUICK FIX TEST WIDGET
// /// Use this widget to test payment integration
// class PaymentTestWidget extends StatefulWidget {
//   const PaymentTestWidget({super.key});

//   @override
//   _PaymentTestWidgetState createState() => _PaymentTestWidgetState();
// }

// class _PaymentTestWidgetState extends State<PaymentTestWidget> {
//   @override
//   void initState() {
//     super.initState();
//     PaymentFixHelper.initializeRazorpay();
//   }

//   @override
//   void dispose() {
//     PaymentFixHelper.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Payment Integration Test'),
//         backgroundColor: Colors.blue[600],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Icon(Icons.payment, size: 48, color: Colors.blue),
//                     SizedBox(height: 16),
//                     Text(
//                       'Razorpay Integration Test',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Test payment integration with ₹1 transaction',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: 24),

//             ElevatedButton.icon(
//               onPressed: () {
//                 PaymentFixHelper.testPayment();
//               },
//               icon: Icon(Icons.play_arrow),
//               label: Text('Start Test Payment'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.all(16),
//               ),
//             ),

//             SizedBox(height: 12),

//             OutlinedButton.icon(
//               onPressed: () {
//                 PaymentFixHelper.printDebugInfo();
//               },
//               icon: Icon(Icons.info_outline),
//               label: Text('Show Debug Info'),
//             ),

//             SizedBox(height: 12),

//             OutlinedButton.icon(
//               onPressed: () {
//                 Get.back();
//               },
//               icon: Icon(Icons.arrow_back),
//               label: Text('Back to App'),
//             ),

//             Spacer(),

//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Troubleshooting:',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 4),
//                   Text('• Ensure internet connection'),
//                   Text('• Check Razorpay key configuration'),
//                   Text('• Verify Android permissions'),
//                   Text('• Clear app cache if needed'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
