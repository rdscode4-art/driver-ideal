// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// void main() {
//   runApp(RazorpayTestApp());
// }

// class RazorpayTestApp extends StatelessWidget {
//   const RazorpayTestApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(title: 'Razorpay Debug Test', home: PaymentTestScreen());
//   }
// }

// class PaymentTestScreen extends StatefulWidget {
//   const PaymentTestScreen({super.key});

//   @override
//   _PaymentTestScreenState createState() => _PaymentTestScreenState();
// }

// class _PaymentTestScreenState extends State<PaymentTestScreen> {
//   late Razorpay _razorpay;
//   String _status = 'Ready to test payment';
//   final List<String> _logs = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeRazorpay();
//   }

//   void _addLog(String message) {
//     setState(() {
//       String timestamp = DateTime.now().toIso8601String().substring(11, 19);
//       _logs.add('[$timestamp] $message');
//       print(message); // Also print to terminal
//     });
//   }

//   void _initializeRazorpay() {
//     _addLog('🚀 INITIALIZING RAZORPAY...');

//     _razorpay = Razorpay();

//     // CRITICAL: Set up event listeners
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//     _addLog('✅ Razorpay initialized with event listeners');
//     setState(() {
//       _status = 'Razorpay Ready - Callbacks Registered';
//     });
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     _addLog('🎉 SUCCESS CALLBACK FIRED!');
//     _addLog('💳 Payment ID: ${response.paymentId}');
//     _addLog('📋 Order ID: ${response.orderId}');
//     _addLog('🔐 Signature: ${response.signature}');

//     // TERMINAL OUTPUT
//     print('\n🚨🚨🚨 SUCCESS CALLBACK EXECUTED 🚨🚨🚨');
//     print('PAYMENT_ID: ${response.paymentId}');
//     print('ORDER_ID: ${response.orderId}');
//     print('SIGNATURE: ${response.signature}');
//     print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//     setState(() {
//       _status = 'Payment SUCCESS - Check logs and terminal!';
//     });
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     _addLog('❌ ERROR CALLBACK FIRED!');
//     _addLog('🚫 Error Code: ${response.code}');
//     _addLog('📝 Error Message: ${response.message}');

//     // TERMINAL OUTPUT
//     print('\n🚨🚨🚨 ERROR CALLBACK EXECUTED 🚨🚨🚨');
//     print('ERROR_CODE: ${response.code}');
//     print('ERROR_MESSAGE: ${response.message}');
//     print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//     setState(() {
//       _status = 'Payment ERROR - Check logs and terminal!';
//     });
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     _addLog('🏦 WALLET CALLBACK FIRED!');
//     _addLog('💳 Wallet: ${response.walletName}');

//     // TERMINAL OUTPUT
//     print('\n🚨🚨🚨 WALLET CALLBACK EXECUTED 🚨🚨🚨');
//     print('WALLET_NAME: ${response.walletName}');
//     print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//     setState(() {
//       _status = 'External WALLET - Check logs and terminal!';
//     });
//   }

//   void _startPayment() {
//     _addLog('🚀 OPENING RAZORPAY CHECKOUT...');

//     var options = {
//       'key': 'rzp_test_1DP5mmOlF5G5ag', // Test key
//       'amount': 100, // ₹1 in paise
//       'name': 'RiDeal Driver Test',
//       'description': 'Payment Callback Debug Test',
//       'order_id': 'test_order_${DateTime.now().millisecondsSinceEpoch}',
//       'prefill': {'contact': '9999999999', 'email': 'test@rideal.app'},
//     };

//     try {
//       _razorpay.open(options);
//       _addLog('✅ Checkout opened - waiting for user action...');
//       setState(() {
//         _status = 'Payment UI Open - Complete payment to test callbacks';
//       });
//     } catch (e) {
//       _addLog('❌ Failed to open checkout: $e');
//       setState(() {
//         _status = 'Error opening payment: $e';
//       });
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _razorpay.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Razorpay Callback Test'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 'Status: $_status',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),

//             SizedBox(height: 20),

//             // Test Payment Button
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _startPayment,
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//                 child: Text(
//                   'TEST PAYMENT (₹1)',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//             ),

//             SizedBox(height: 20),

//             // Clear Logs
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   _logs.clear();
//                 });
//               },
//               child: Text('Clear Logs'),
//             ),

//             SizedBox(height: 10),

//             // Logs
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: ListView.builder(
//                   itemCount: _logs.length,
//                   itemBuilder: (context, index) {
//                     return Padding(
//                       padding: EdgeInsets.only(bottom: 4),
//                       child: Text(
//                         _logs[index],
//                         style: TextStyle(fontFamily: 'monospace', fontSize: 12),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),

//             // Instructions
//             Padding(
//               padding: EdgeInsets.only(top: 16),
//               child: Text(
//                 'Instructions:\n'
//                 '1. Tap "TEST PAYMENT" button\n'
//                 '2. Complete payment in Razorpay UI\n'
//                 '3. Check logs here AND terminal output\n'
//                 '4. Payment ID & signature should appear in BOTH places',
//                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
