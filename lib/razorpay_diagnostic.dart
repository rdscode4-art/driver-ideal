// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'core/storage_helper.dart';

// /// 🔧 RAZORPAY DIAGNOSTIC TOOL
// class RazorpayDiagnostic {
//   static const String baseUrl = 'https://backend.ridealmobility.com';
//   static const String razorpayKey = 'rzp_test_RnX4Oatt9zSiqS';

//   /// Run complete diagnostic check
//   static Future<void> runCompleteDiagnostic() async {
//     print('\n🔬 RAZORPAY DIAGNOSTIC STARTED');
//     print('=' * 60);

//     final results = <String, dynamic>{};

//     // 1. Check Authentication
//     results['auth'] = await _checkAuthentication();

//     // 2. Check Backend Connectivity
//     results['backend'] = await _checkBackendConnectivity();

//     // 3. Test Order Creation API
//     results['order_creation'] = await _testOrderCreation();

//     // 4. Test Payment Verification API
//     results['payment_verification'] = await _testPaymentVerification();

//     // 5. Validate Razorpay Key
//     results['razorpay_key'] = _validateRazorpayKey();

//     // 6. Check Network Configuration
//     results['network'] = await _checkNetworkConfiguration();

//     // Show comprehensive results
//     _showDiagnosticResults(results);
//   }

//   /// Check authentication status
//   static Future<Map<String, dynamic>> _checkAuthentication() async {
//     try {
//       final token = await StorageHelper.getAuthToken();

//       if (token == null || token.isEmpty) {
//         return {
//           'status': 'FAIL',
//           'message': 'No authentication token found',
//           'recommendation': 'Please login again',
//         };
//       }

//       return {
//         'status': 'PASS',
//         'message': 'Authentication token found',
//         'token_length': token.length,
//       };
//     } catch (e) {
//       return {'status': 'FAIL', 'message': 'Error checking authentication: $e'};
//     }
//   }

//   /// Check backend connectivity
//   static Future<Map<String, dynamic>> _checkBackendConnectivity() async {
//     try {
//       print('🌐 Testing backend connectivity...');

//       final response = await http
//           .get(Uri.parse('$baseUrl/api'))
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200 || response.statusCode == 404) {
//         return {
//           'status': 'PASS',
//           'message': 'Backend is reachable',
//           'response_code': response.statusCode,
//         };
//       } else {
//         return {
//           'status': 'FAIL',
//           'message': 'Backend returned ${response.statusCode}',
//         };
//       }
//     } catch (e) {
//       return {'status': 'FAIL', 'message': 'Backend connectivity failed: $e'};
//     }
//   }

//   /// Test order creation with real API call
//   static Future<Map<String, dynamic>> _testOrderCreation() async {
//     try {
//       print('💳 Testing order creation API...');

//       final token = await StorageHelper.getAuthToken();
//       if (token == null) {
//         return {
//           'status': 'SKIP',
//           'message': 'No auth token - skipping API test',
//         };
//       }

//       // Get real driver ID from token/storage
//       final driverId = await _getDriverId();
//       if (driverId == null) {
//         return {
//           'status': 'FAIL',
//           'message': 'No driver ID found - please login again',
//         };
//       }

//       // Test buy-subscription API with real data format
//       final response = await http
//           .post(
//             Uri.parse('$baseUrl/buy-subscription'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode({
//               'driverId': driverId,
//               'planType': 'Diagnostic Test Plan',
//               'amount': 1, // Minimal amount for testing
//             }),
//           )
//           .timeout(const Duration(seconds: 15));

//       print('API Response: ${response.statusCode}');
//       print('Response Body:cgi zicgzi ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         try {
//           final responseData = json.decode(response.body);

//           // Check if we got proper order response
//           if (responseData['orderId'] != null) {
//             return {
//               'status': 'PASS',
//               'message':
//                   'Order creation API working - Order ID: ${responseData['orderId']}',
//               'order_id': responseData['orderId'],
//               'amount': responseData['amount'],
//             };
//           } else {
//             return {
//               'status': 'WARNING',
//               'message': 'API responded but no order ID returned',
//               'response': responseData,
//             };
//           }
//         } catch (e) {
//           return {
//             'status': 'WARNING',
//             'message': 'API responded but invalid JSON format',
//             'raw_response': response.body,
//           };
//         }
//       } else {
//         return {
//           'status': 'FAIL',
//           'message': 'API returned ${response.statusCode}: ${response.body}',
//         };
//       }
//     } catch (e) {
//       return {'status': 'FAIL', 'message': 'API test failed: $e'};
//     }
//   }

//   /// Test payment verification API
//   static Future<Map<String, dynamic>> _testPaymentVerification() async {
//     try {
//       print('🔒 Testing payment verification API...');

//       final driverId = await _getDriverId();
//       if (driverId == null) {
//         return {
//           'status': 'SKIP',
//           'message': 'No driver ID - skipping verification test',
//         };
//       }

//       // Test verify-subscription-payment API with sample data
//       final response = await http
//           .post(
//             Uri.parse('$baseUrl/verify-subscription-payment'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode({
//               'driverId': driverId,
//               'planId': '68ede14b0efa19665b81303e', // Sample plan ID
//               'razorpay_payment_id': 'pay_DIAGNOSTIC_TEST',
//               'razorpay_order_id': 'order_DIAGNOSTIC_TEST',
//               'razorpay_signature': 'diagnostic_test_signature',
//             }),
//           )
//           .timeout(const Duration(seconds: 15));

//       print('Verification API Response: ${response.statusCode}');

//       if (response.statusCode == 200 || response.statusCode == 400) {
//         // 400 is expected for test data, but API is reachable
//         return {
//           'status': 'PASS',
//           'message': 'Payment verification API is reachable',
//           'response_code': response.statusCode,
//         };
//       } else {
//         return {
//           'status': 'FAIL',
//           'message': 'Verification API returned ${response.statusCode}',
//         };
//       }
//     } catch (e) {
//       return {
//         'status': 'FAIL',
//         'message': 'Payment verification test failed: $e',
//       };
//     }
//   }

//   /// Get driver ID from storage/token
//   static Future<String?> _getDriverId() async {
//     try {
//       final userData = await StorageHelper.getUserData();
//       if (userData != null) {
//         final data = json.decode(userData);
//         return data['id']?.toString() ?? data['driverId']?.toString();
//       }
//       return null;
//     } catch (e) {
//       print('Error getting driver ID: $e');
//       return null;
//     }
//   }

//   /// Validate Razorpay key format
//   static Map<String, dynamic> _validateRazorpayKey() {
//     if (razorpayKey.isEmpty) {
//       return {'status': 'FAIL', 'message': 'Razorpay key is empty'};
//     }

//     if (!razorpayKey.startsWith('rzp_')) {
//       return {
//         'status': 'FAIL',
//         'message': 'Invalid Razorpay key format - must start with rzp_',
//       };
//     }

//     if (!razorpayKey.contains('test') && !razorpayKey.contains('live')) {
//       return {
//         'status': 'WARNING',
//         'message': 'Razorpay key format unusual - should contain test or live',
//       };
//     }

//     return {
//       'status': 'PASS',
//       'message':
//           'Razorpay key format is valid (${razorpayKey.contains('test') ? 'Test Mode' : 'Live Mode'})',
//       'key_type': razorpayKey.contains('test') ? 'Test' : 'Live',
//       'key_preview': '${razorpayKey.substring(0, 12)}...',
//     };
//   }

//   /// Check network configuration
//   static Future<Map<String, dynamic>> _checkNetworkConfiguration() async {
//     try {
//       // Test basic internet connectivity
//       final response = await http
//           .get(Uri.parse('https://httpbin.org/status/200'))
//           .timeout(const Duration(seconds: 5));

//       if (response.statusCode == 200) {
//         return {'status': 'PASS', 'message': 'Internet connectivity working'};
//       } else {
//         return {'status': 'FAIL', 'message': 'Internet test failed'};
//       }
//     } catch (e) {
//       return {'status': 'FAIL', 'message': 'Network connectivity issue: $e'};
//     }
//   }

//   /// Show comprehensive diagnostic results
//   static void _showDiagnosticResults(Map<String, dynamic> results) {
//     print('\n📊 DIAGNOSTIC RESULTS SUMMARY');
//     print('=' * 60);

//     int passCount = 0;
//     int failCount = 0;
//     int warningCount = 0;

//     results.forEach((test, result) {
//       final status = result['status'];
//       final message = result['message'];

//       String icon;
//       switch (status) {
//         case 'PASS':
//           icon = '✅';
//           passCount++;
//           break;
//         case 'FAIL':
//           icon = '❌';
//           failCount++;
//           break;
//         case 'WARNING':
//           icon = '⚠️';
//           warningCount++;
//           break;
//         default:
//           icon = 'ℹ️';
//       }

//       print('$icon ${test.toUpperCase()}: $message');
//     });

//     print('\n📈 SUMMARY:');
//     print('   ✅ Passed: $passCount');
//     print('   ❌ Failed: $failCount');
//     print('   ⚠️ Warnings: $warningCount');

//     // Overall assessment
//     if (failCount == 0) {
//       print('\n🎉 OVERALL: Payment gateway should work perfectly!');
//     } else {
//       print('\n⚠️ OVERALL: Some issues detected - check failed items');
//     }

//     // Show in app dialog
//     _showResultsDialog(results, passCount, failCount, warningCount);
//   }

//   /// Show results in app dialog
//   static void _showResultsDialog(
//     Map<String, dynamic> results,
//     int pass,
//     int fail,
//     int warn,
//   ) {
//     Get.dialog(
//       AlertDialog(
//         title: Row(
//           children: [
//             Icon(
//               fail == 0 ? Icons.check_circle : Icons.warning,
//               color: fail == 0 ? Colors.green : Colors.orange,
//             ),
//             const SizedBox(width: 8),
//             const Text('Payment Diagnostic'),
//           ],
//         ),
//         content: Container(
//           width: double.maxFinite,
//           constraints: const BoxConstraints(maxHeight: 400),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Summary
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       '✅ Pass: $pass',
//                       style: TextStyle(color: Colors.green[700]),
//                     ),
//                     Text(
//                       '❌ Fail: $fail',
//                       style: TextStyle(color: Colors.red[700]),
//                     ),
//                     Text(
//                       '⚠️ Warn: $warn',
//                       style: TextStyle(color: Colors.orange[700]),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Detailed results
//               Expanded(
//                 child: ListView(
//                   children: results.entries.map((entry) {
//                     final test = entry.key;
//                     final result = entry.value;
//                     final status = result['status'];
//                     final message = result['message'];

//                     Color color;
//                     IconData icon;

//                     switch (status) {
//                       case 'PASS':
//                         color = Colors.green;
//                         icon = Icons.check_circle;
//                         break;
//                       case 'FAIL':
//                         color = Colors.red;
//                         icon = Icons.error;
//                         break;
//                       default:
//                         color = Colors.orange;
//                         icon = Icons.warning;
//                     }

//                     return ListTile(
//                       leading: Icon(icon, color: color),
//                       title: Text(
//                         test.replaceAll('_', ' ').toUpperCase(),
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(message),
//                       dense: true,
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('Close')),
//           if (fail > 0)
//             ElevatedButton(
//               onPressed: () {
//                 Get.back();
//                 _showTroubleshootingGuide(results);
//               },
//               child: const Text('Get Help'),
//             ),
//         ],
//       ),
//     );
//   }

//   /// Show troubleshooting guide with specific recommendations
//   static void _showTroubleshootingGuide(Map<String, dynamic> results) {
//     final List<String> recommendations = [];

//     // Analyze specific failures and provide targeted recommendations
//     results.forEach((test, result) {
//       if (result['status'] == 'FAIL') {
//         switch (test) {
//           case 'auth':
//             recommendations.add(
//               '🔐 Login again to refresh authentication token',
//             );
//             break;
//           case 'backend':
//             recommendations.add('🌐 Check internet connection and try again');
//             break;
//           case 'order_creation':
//             recommendations.add(
//               '💳 Contact support - order creation API issue',
//             );
//             break;
//           case 'payment_verification':
//             recommendations.add('🔒 Payment verification service may be down');
//             break;
//           case 'razorpay_key':
//             recommendations.add('⚙️ Razorpay configuration needs updating');
//             break;
//           case 'network':
//             recommendations.add('📶 Check internet connectivity');
//             break;
//         }
//       }
//     });

//     if (recommendations.isEmpty) {
//       recommendations.addAll([
//         '🔄 Restart the app',
//         '📱 Clear app cache',
//         '🌐 Check internet connection',
//         '⚙️ Contact support if issues persist',
//       ]);
//     }

//     Get.dialog(
//       AlertDialog(
//         title: const Text('🛠️ Troubleshooting Guide'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Based on the diagnostic results, here are the recommended actions:',
//                 style: TextStyle(fontWeight: FontWeight.w500),
//               ),
//               const SizedBox(height: 16),
//               ...recommendations
//                   .map(
//                     (rec) => Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 4),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('• ', style: TextStyle(fontSize: 16)),
//                           Expanded(child: Text(rec)),
//                         ],
//                       ),
//                     ),
//                   )
//                   ,
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue[300]!),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Need More Help?',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue[800],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Contact support with your diagnostic results for faster resolution.',
//                       style: TextStyle(color: Colors.blue[700]),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('Got it')),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               // You can add contact support functionality here
//               Get.snackbar(
//                 'Support',
//                 'Contact support with your diagnostic results',
//                 backgroundColor: Colors.green[100],
//                 duration: const Duration(seconds: 3),
//               );
//             },
//             child: const Text('Contact Support'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Simple diagnostic button
// Widget buildDiagnosticButton() {
//   return Container(
//     margin: const EdgeInsets.all(16),
//     width: double.infinity,
//     child: ElevatedButton.icon(
//       onPressed: () => RazorpayDiagnostic.runCompleteDiagnostic(),
//       icon: const Icon(Icons.medical_services, color: Colors.white),
//       label: const Text(
//         'Run Payment Diagnostic',
//         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.red[600],
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     ),
//   );
// }
