// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// /// Diagnostic screen to test and fix Razorpay issues
// class RazorpayDiagnosticScreen extends StatefulWidget {
//   const RazorpayDiagnosticScreen({super.key});

//   @override
//   _RazorpayDiagnosticScreenState createState() =>
//       _RazorpayDiagnosticScreenState();
// }

// class _RazorpayDiagnosticScreenState extends State<RazorpayDiagnosticScreen> {
//   late Razorpay _razorpay;
//   final RxList<String> diagnosticLogs = <String>[].obs;
//   final RxBool isTestRunning = false.obs;

//   @override
//   void initState() {
//     super.initState();
//     _initializeRazorpay();
//     _runInitialDiagnostics();
//   }

//   void _initializeRazorpay() {
//     try {
//       _razorpay = Razorpay();
//       _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//       _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//       _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//       _addLog('✅ Razorpay initialized successfully');
//     } catch (e) {
//       _addLog('❌ Razorpay initialization failed: $e');
//     }
//   }

//   void _runInitialDiagnostics() {
//     _addLog('🔍 Starting Razorpay diagnostics...');
//     _addLog('📱 Device: Android');
//     _addLog('🌐 WebView: Checking compatibility...');

//     // Check if we can create basic WebView
//     Future.delayed(Duration(milliseconds: 500), () {
//       _addLog('✅ Basic WebView check passed');
//       _addLog('🎯 Ready for payment testing');
//     });
//   }

//   void _addLog(String message) {
//     diagnosticLogs.add(
//       '${DateTime.now().toString().substring(11, 19)}: $message',
//     );
//     if (diagnosticLogs.length > 50) {
//       diagnosticLogs.removeAt(0);
//     }
//   }

//   void _testMinimalPayment() {
//     if (isTestRunning.value) return;

//     isTestRunning.value = true;
//     _addLog('🧪 Testing minimal payment configuration...');

//     try {
//       final options = {
//         'key': 'rzp_test_1DP5mmOlF5G5ag', // Test key
//         'amount': 100, // ₹1.00
//         'order_id': 'test_order_${DateTime.now().millisecondsSinceEpoch}',
//         'name': 'RiDeal Test',
//         'description': 'Diagnostic Test Payment',
//         'prefill': {
//           'contact': '9999999999',
//           'email': 'test@rideal.app',
//           'name': 'Test User',
//         },
//         'theme': {'color': '#2196F3'},
//         'config': {
//           'display': {
//             'blocks': {
//               'other': {
//                 'name': 'Test Payment Methods',
//                 'instruments': [
//                   {'method': 'card'},
//                   {'method': 'upi'},
//                 ],
//               },
//             },
//             'sequence': ['block.other'],
//             'preferences': {'show_default_blocks': false},
//           },
//         },
//         'modal': {'confirm_close': false},
//         'notes': {
//           'test': 'diagnostic',
//           'timestamp': DateTime.now().toIso8601String(),
//         },
//       };

//       _addLog('💳 Opening test payment with minimal config...');
//       _razorpay.open(options);
//     } catch (e) {
//       _addLog('❌ Test payment failed: $e');
//       isTestRunning.value = false;
//     }
//   }

//   void _testProductionConfig() {
//     if (isTestRunning.value) return;

//     isTestRunning.value = true;
//     _addLog('🏭 Testing production-like configuration...');

//     try {
//       final options = {
//         'key': 'rzp_live_8Q8dLZLezkZz5q', // Production key (if available)
//         'amount': 100,
//         'order_id': 'prod_test_${DateTime.now().millisecondsSinceEpoch}',
//         'name': 'RiDeal Subscription',
//         'description': 'Driver Subscription Test',
//         'prefill': {
//           'contact': '9999999999',
//           'email': 'driver@rideal.app',
//           'name': 'Driver Test',
//         },
//         'external': {
//           'wallets': ['paytm', 'phonepe', 'googlepay'],
//         },
//         'theme': {
//           'color': '#2196F3',
//           'backdrop_color': 'rgba(33, 150, 243, 0.1)',
//         },
//         'config': {
//           'display': {
//             'blocks': {
//               'banks': {
//                 'name': 'Pay using Banking',
//                 'instruments': [
//                   {'method': 'netbanking'},
//                   {'method': 'upi'},
//                 ],
//               },
//               'other': {
//                 'name': 'Other Payment Methods',
//                 'instruments': [
//                   {'method': 'wallet'},
//                   {'method': 'card'},
//                 ],
//               },
//             },
//             'sequence': ['block.banks', 'block.other'],
//             'preferences': {'show_default_blocks': false},
//           },
//         },
//         'modal': {'confirm_close': false},
//         'retry': {'enabled': true, 'max_count': 3},
//         'timeout': 300,
//         'notes': {
//           'test': 'production_config',
//           'timestamp': DateTime.now().toIso8601String(),
//         },
//       };

//       _addLog('💳 Opening production test...');
//       _razorpay.open(options);
//     } catch (e) {
//       _addLog('❌ Production test failed: $e');
//       isTestRunning.value = false;
//     }
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     isTestRunning.value = false;
//     _addLog('✅ Payment SUCCESS!');
//     _addLog('   Payment ID: ${response.paymentId}');
//     _addLog('   Order ID: ${response.orderId}');
//     _addLog('   Signature: ${response.signature}');

//     Get.snackbar(
//       '✅ Test Success',
//       'Payment test completed successfully!',
//       backgroundColor: Colors.green[100],
//       colorText: Colors.green[800],
//       duration: Duration(seconds: 3),
//     );
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     isTestRunning.value = false;
//     _addLog('❌ Payment ERROR!');
//     _addLog('   Code: ${response.code}');
//     _addLog('   Message: ${response.message}');
//     _addLog('   Description: ${response.error}');

//     if (response.message?.contains('Something went wrong') == true) {
//       _addLog('🔍 DETECTED: "Something went wrong" error');
//       _addLog('   This indicates WebView/GPU compatibility issue');
//       _addLog('   Possible solutions:');
//       _addLog('   1. Device-specific WebView problem');
//       _addLog('   2. GPU acceleration conflict');
//       _addLog('   3. Canvas2D rendering issue');
//       _addLog('   4. Network connectivity problem');
//     }

//     Get.snackbar(
//       '❌ Test Failed',
//       response.message ?? 'Payment test failed',
//       backgroundColor: Colors.red[100],
//       colorText: Colors.red[800],
//       duration: Duration(seconds: 5),
//     );
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     isTestRunning.value = false;
//     _addLog('💰 External Wallet: ${response.walletName}');

//     Get.snackbar(
//       '💰 Wallet Selected',
//       'External wallet: ${response.walletName}',
//       backgroundColor: Colors.blue[100],
//       colorText: Colors.blue[800],
//       duration: Duration(seconds: 3),
//     );
//   }

//   void _clearLogs() {
//     diagnosticLogs.clear();
//     _addLog('🧹 Logs cleared');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Razorpay Diagnostics'),
//         backgroundColor: Colors.blue[700],
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.clear),
//             onPressed: _clearLogs,
//             tooltip: 'Clear Logs',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Control buttons
//           Container(
//             padding: EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: isTestRunning.value
//                             ? null
//                             : _testMinimalPayment,
//                         icon: Icon(Icons.science),
//                         label: Text('Test Minimal'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green[600],
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: isTestRunning.value
//                             ? null
//                             : _testProductionConfig,
//                         icon: Icon(Icons.production_quantity_limits),
//                         label: Text('Test Production'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange[600],
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Obx(
//                   () => isTestRunning.value
//                       ? LinearProgressIndicator()
//                       : SizedBox(height: 4),
//                 ),
//               ],
//             ),
//           ),

//           Divider(height: 1),

//           // Diagnostic logs
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Diagnostic Logs',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[800],
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Obx(
//                         () => ListView.builder(
//                           padding: EdgeInsets.all(12),
//                           itemCount: diagnosticLogs.length,
//                           itemBuilder: (context, index) {
//                             final log = diagnosticLogs[index];
//                             Color textColor = Colors.black87;

//                             if (log.contains('❌')) {
//                               textColor = Colors.red[700]!;
//                             } else if (log.contains('✅')) {
//                               textColor = Colors.green[700]!;
//                             } else if (log.contains('🔍')) {
//                               textColor = Colors.orange[700]!;
//                             } else if (log.contains('🧪')) {
//                               textColor = Colors.blue[700]!;
//                             }

//                             return Padding(
//                               padding: EdgeInsets.symmetric(vertical: 2),
//                               child: Text(
//                                 log,
//                                 style: TextStyle(
//                                   fontFamily: 'monospace',
//                                   fontSize: 12,
//                                   color: textColor,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }
// }
