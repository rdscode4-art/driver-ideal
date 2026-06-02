// // Payment Gateway Integration Test - Native Razorpay Implementation
// // This file tests the complete payment flow using native Razorpay SDK

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// class PaymentGatewayTest extends StatefulWidget {
//   const PaymentGatewayTest({super.key});

//   @override
//   State<PaymentGatewayTest> createState() => _PaymentGatewayTestState();
// }

// class _PaymentGatewayTestState extends State<PaymentGatewayTest> {
//   late Razorpay _razorpay;
//   String _result = 'Test not started yet';
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeRazorpay();
//   }

//   void _initializeRazorpay() {
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//     setState(() {
//       _result = '✅ Razorpay SDK initialized successfully';
//     });

//     print('🔥 Razorpay SDK Test Initialized');
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     print('✅ TEST PAYMENT SUCCESS!');
//     print('Payment ID: ${response.paymentId}');
//     print('Order ID: ${response.orderId}');
//     print('Signature: ${response.signature}');

//     setState(() {
//       _result =
//           '''✅ PAYMENT SUCCESS!
// Payment ID: ${response.paymentId}
// Order ID: ${response.orderId}
// Signature: ${response.signature}''';
//       _isProcessing = false;
//     });

//     Get.snackbar(
//       '✅ Test Payment Success',
//       'Native Razorpay working perfectly!',
//       backgroundColor: Colors.green[100],
//       colorText: Colors.green[800],
//       duration: const Duration(seconds: 3),
//     );
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     print('❌ TEST PAYMENT ERROR!');
//     print('Error Code: ${response.code}');
//     print('Error Message: ${response.message}');
//     print('Error Details: ${response.error}');

//     setState(() {
//       _result =
//           '''❌ PAYMENT ERROR:
// Code: ${response.code}
// Message: ${response.message}
// Details: ${response.error}''';
//       _isProcessing = false;
//     });

//     Get.snackbar(
//       '❌ Test Payment Error',
//       'Code: ${response.code} - ${response.message}',
//       backgroundColor: Colors.red[100],
//       colorText: Colors.red[800],
//       duration: const Duration(seconds: 5),
//     );
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     print('💳 External Wallet: ${response.walletName}');

//     setState(() {
//       _result = '💳 External Wallet Selected: ${response.walletName}';
//       _isProcessing = false;
//     });
//   }

//   void _startPaymentTest() {
//     setState(() {
//       _isProcessing = true;
//       _result = '🚀 Starting payment test...';
//     });

//     print('🚀 Starting Native Razorpay Payment Test...');

//     var options = {
//       'key': 'rzp_test_RnX4Oatt9zSiqS', // Test key from SubscriptionController
//       'amount': 100, // ₹1 in paise
//       'currency': 'INR',
//       'name': 'Rideal Driver - Payment Test',
//       'description': 'Testing Native Razorpay Integration',
//       'order_id': 'order_test_${DateTime.now().millisecondsSinceEpoch}',
//       'timeout': 300,
//       'prefill': {
//         'contact': '9999999999',
//         'email': 'test@rideal.app',
//         'name': 'Test Driver',
//       },
//       'theme': {'color': '#667eea'},
//       'retry': {'enabled': true, 'max_count': 3},
//     };

//     try {
//       _razorpay.open(options);
//       print('✅ Razorpay payment window opened successfully');
//     } catch (e) {
//       print('❌ Error opening Razorpay: $e');
//       setState(() {
//         _result = '❌ Error opening Razorpay: $e';
//         _isProcessing = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Payment Gateway Test'),
//         backgroundColor: Colors.blue[700],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '🧪 Native Razorpay Integration Test',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'This test validates the native Razorpay SDK integration without WebView.',
//                       style: Theme.of(context).textTheme.bodyMedium,
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             ElevatedButton(
//               onPressed: _isProcessing ? null : _startPaymentTest,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue[700],
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: _isProcessing
//                   ? const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(color: Colors.white),
//                         ),
//                         SizedBox(width: 12),
//                         Text('Processing Payment...'),
//                       ],
//                     )
//                   : const Text(
//                       '💳 Start Payment Test (₹1)',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//             ),

//             const SizedBox(height: 24),

//             Expanded(
//               child: Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '📊 Test Result:',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 12),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Text(
//                             _result,
//                             style: const TextStyle(
//                               fontFamily: 'monospace',
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             Text(
//               'Instructions:\n• Tap "Start Payment Test" to open Razorpay\n• Use test card: 4111 1111 1111 1111\n• Use any future expiry date and CVV\n• Or try UPI for real payment flow',
//               style: Theme.of(
//                 context,
//               ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
