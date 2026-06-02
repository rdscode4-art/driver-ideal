// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// void main() {
//   runApp(QuickPaymentTest());
// }

// class QuickPaymentTest extends StatelessWidget {
//   const QuickPaymentTest({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(title: 'Quick Payment Test', home: PaymentScreen());
//   }
// }

// class PaymentScreen extends StatefulWidget {
//   const PaymentScreen({super.key});

//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   late Razorpay _razorpay;
//   String _status = 'Ready to test';
//   final List<String> _logs = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeRazorpay();
//   }

//   void _addLog(String message) {
//     setState(() {
//       String timestamp = DateTime.now().toString().substring(11, 19);
//       _logs.insert(0, '[$timestamp] $message');
//       if (_logs.length > 10) _logs.removeLast();
//     });
//     print(message); // Also print to terminal
//   }

//   void _initializeRazorpay() {
//     _addLog('🚀 Initializing Razorpay...');

//     _razorpay = Razorpay();

//     // Critical: Set up event listeners
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
//       PaymentSuccessResponse response,
//     ) {
//       _addLog('🎉 SUCCESS CALLBACK FIRED!');
//       _addLog('💳 Payment ID: ${response.paymentId}');
//       _addLog('📋 Order ID: ${response.orderId}');
//       _addLog('🔐 Signature: ${response.signature}');

//       // TERMINAL OUTPUT FOR DEBUGGING
//       print('\n🚨🚨🚨 RAZORPAY SUCCESS CALLBACK 🚨🚨🚨');
//       print('PAYMENT_ID: ${response.paymentId}');
//       print('ORDER_ID: ${response.orderId}');
//       print('SIGNATURE: ${response.signature}');
//       print('TIMESTAMP: ${DateTime.now().millisecondsSinceEpoch}');
//       print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//       setState(() {
//         _status = 'Payment SUCCESS! Check terminal!';
//       });
//     });

//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (
//       PaymentFailureResponse response,
//     ) {
//       _addLog('❌ ERROR CALLBACK FIRED!');
//       _addLog('🚫 Code: ${response.code}');
//       _addLog('📝 Message: ${response.message}');

//       // TERMINAL OUTPUT FOR DEBUGGING
//       print('\n🚨🚨🚨 RAZORPAY ERROR CALLBACK 🚨🚨🚨');
//       print('ERROR_CODE: ${response.code}');
//       print('ERROR_MESSAGE: ${response.message}');
//       print('TIMESTAMP: ${DateTime.now().millisecondsSinceEpoch}');
//       print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//       setState(() {
//         _status = 'Payment ERROR! Check terminal!';
//       });
//     });

//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
//       ExternalWalletResponse response,
//     ) {
//       _addLog('🏦 WALLET CALLBACK FIRED!');
//       _addLog('💳 Wallet: ${response.walletName}');

//       // TERMINAL OUTPUT FOR DEBUGGING
//       print('\n🚨🚨🚨 RAZORPAY WALLET CALLBACK 🚨🚨🚨');
//       print('WALLET_NAME: ${response.walletName}');
//       print('TIMESTAMP: ${DateTime.now().millisecondsSinceEpoch}');
//       print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');

//       setState(() {
//         _status = 'External Wallet! Check terminal!';
//       });
//     });

//     _addLog('✅ Razorpay callbacks registered');
//     setState(() {
//       _status = 'Ready - Callbacks set up';
//     });
//   }

//   void _startTestPayment() {
//     _addLog('🚀 Starting test payment...');

//     var options = {
//       'key': 'rzp_test_1DP5mmOlF5G5ag', // Test key
//       'amount': 100, // ₹1.00 in paise
//       'name': 'RiDeal Driver Payment Test',
//       'description': 'Callback Debug Test - ₹1',
//       'order_id': 'test_order_${DateTime.now().millisecondsSinceEpoch}',
//       'prefill': {
//         'contact': '9999999999',
//         'email': 'test@rideal.app',
//         'name': 'Test Driver',
//       },
//       'theme': {'color': '#2196F3'},
//     };

//     try {
//       _razorpay.open(options);
//       _addLog('✅ Payment UI opened');
//       setState(() {
//         _status = 'Payment UI Open - Complete payment to test callbacks';
//       });
//     } catch (e) {
//       _addLog('❌ Error opening payment: $e');
//       setState(() {
//         _status = 'Error: $e';
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
//         title: Text('Quick Payment Test'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status Card
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.blue.withOpacity(0.3)),
//               ),
//               child: Text(
//                 'Status: $_status',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),

//             SizedBox(height: 20),

//             // Test Button
//             SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton(
//                 onPressed: _startTestPayment,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   textStyle: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 child: Text('🚀 TEST PAYMENT (₹1)'),
//               ),
//             ),

//             SizedBox(height: 20),

//             // Instructions
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '📋 Test Instructions:',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     '1. Tap the "TEST PAYMENT" button above\n'
//                     '2. Complete payment in Razorpay interface\n'
//                     '3. Check logs below AND terminal output\n'
//                     '4. Payment ID & signature should appear in BOTH',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),

//             SizedBox(height: 20),

//             // Logs Section
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '📄 Live Logs:',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     setState(() {
//                       _logs.clear();
//                     });
//                   },
//                   child: Text('Clear'),
//                 ),
//               ],
//             ),

//             SizedBox(height: 8),

//             // Logs List
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: _logs.isEmpty
//                     ? Center(
//                         child: Text(
//                           'No logs yet...\nStart a payment to see callback logs',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                       )
//                     : ListView.separated(
//                         itemCount: _logs.length,
//                         separatorBuilder: (context, index) =>
//                             SizedBox(height: 4),
//                         itemBuilder: (context, index) {
//                           return Text(
//                             _logs[index],
//                             style: TextStyle(
//                               fontFamily: 'monospace',
//                               fontSize: 12,
//                               color: _logs[index].contains('SUCCESS')
//                                   ? Colors.green[700]
//                                   : _logs[index].contains('ERROR')
//                                   ? Colors.red[700]
//                                   : Colors.black87,
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// 📱 HOW TO USE:
// /// 1. Add this widget to any screen where you want to test
// /// 2. Tap the "Test Payment Fix" button
// /// 3. It will open Razorpay with ₹1 test payment
// /// 4. You can cancel or complete the payment to test both flows

// /// 💡 EXAMPLE USAGE IN SUBSCRIPTION SCREEN:
// /// 
// /// class SubscriptionScreen extends StatelessWidget {
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     return Scaffold(
// ///       appBar: AppBar(title: Text('Subscription Plans')),
// ///       body: Column(
// ///         children: [
// ///           // Your existing subscription content
// ///           ...
// ///           
// ///           // Add test button for debugging
// ///           if (kDebugMode) // Only show in debug mode
// ///             QuickPaymentTestButton(),
// ///             
// ///           // Rest of your widgets
// ///           ...
// ///         ],
// ///       ),
// ///     );
// ///   }
// /// }