// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:flutter/material.dart';

// /// 🔍 Comprehensive Razorpay Signature Verification Debugger
// /// This tool helps debug signature verification issues between frontend and backend
// class RazorpaySignatureDebugger {
//   /// Test the exact signature from the logs
//   static void testSignatureFromLogs() {
//     print('\n🔍 ════════════════════════════════════════════════════════');
//     print('🔍     TESTING EXACT SIGNATURE FROM PAYMENT LOGS');
//     print('🔍 ════════════════════════════════════════════════════════');

//     // EXACT values from the logs
//     const String paymentId = 'pay_RpVweDlb36R4en';
//     const String orderId = 'order_RpVwHqT3BFcT7z';
//     const String receivedSignature =
//         'ee2f778230609534efbc686b5516d119901c1f089929954c0a3190bcea66dec4';

//     // Test Razorpay key - this should match what backend uses
//     const String razorpayKeySecret =
//         'KA9JhnjkJzA8abjYqEjLcDDr'; // Test key secret

//     print('📋 Testing with EXACT log values:');
//     print('   Payment ID: $paymentId');
//     print('   Order ID: $orderId');
//     print('   Received Signature: $receivedSignature');
//     print('   Signature Length: ${receivedSignature.length}');
//     print('   Secret Key: $razorpayKeySecret');

//     // STEP 1: Create the exact payload that Razorpay uses
//     final String razorpayPayload = '$orderId|$paymentId';
//     print('\n🔧 STEP 1: Create Razorpay Payload');
//     print('   Payload: "$razorpayPayload"');
//     print('   Payload Length: ${razorpayPayload.length}');

//     // STEP 2: Generate HMAC-SHA256 signature
//     print('\n🔧 STEP 2: Generate Expected Signature');
//     final expectedSignature = _generateHmacSha256(
//       razorpayPayload,
//       razorpayKeySecret,
//     );
//     print('   Expected: $expectedSignature');
//     print('   Expected Length: ${expectedSignature.length}');
//     print('   Received:  $receivedSignature');
//     print('   Received Length: ${receivedSignature.length}');

//     // STEP 3: Compare signatures
//     print('\n🔧 STEP 3: Compare Signatures');
//     final bool isMatch =
//         expectedSignature.toLowerCase() == receivedSignature.toLowerCase();

//     if (isMatch) {
//       print('✅ SIGNATURES MATCH! Frontend signature generation is CORRECT');
//       print('✅ The issue is likely in backend verification logic');
//     } else {
//       print('❌ SIGNATURES DO NOT MATCH');
//       print('❌ Frontend signature generation needs fixing');

//       // Character-by-character comparison
//       print('\n🔍 Character-by-character comparison:');
//       final expectedChars = expectedSignature.toLowerCase().split('');
//       final receivedChars = receivedSignature.toLowerCase().split('');

//       for (int i = 0; i < 64; i++) {
//         if (i < expectedChars.length && i < receivedChars.length) {
//           final match = expectedChars[i] == receivedChars[i];
//           final status = match ? '✅' : '❌';
//           print(
//             '   Position $i: Expected="${expectedChars[i]}" Received="${receivedChars[i]}" $status',
//           );

//           if (!match && i < 10) {
//             print('     ^^^ First difference found at position $i');
//             break;
//           }
//         }
//       }
//     }

//     // STEP 4: Test different payload formats (debugging)
//     print('\n🔧 STEP 4: Test Alternative Payload Formats');
//     _testAlternativeFormats(
//       paymentId,
//       orderId,
//       razorpayKeySecret,
//       receivedSignature,
//     );

//     print('\n🔍 ════════════════════════════════════════════════════════');
//   }

//   /// Test alternative payload formats to debug signature generation
//   static void _testAlternativeFormats(
//     String paymentId,
//     String orderId,
//     String secret,
//     String receivedSignature,
//   ) {
//     final Map<String, String> testFormats = {
//       'Standard (order|payment)': '$orderId|$paymentId',
//       'Reverse (payment|order)': '$paymentId|$orderId',
//       'Space separated': '$orderId $paymentId',
//       'Comma separated': '$orderId,$paymentId',
//       'No separator': '$orderId$paymentId',
//       'With razorpay_ prefix':
//           'razorpay_order_id=$orderId&razorpay_payment_id=$paymentId',
//     };

//     testFormats.forEach((description, payload) {
//       final signature = _generateHmacSha256(payload, secret);
//       final isMatch =
//           signature.toLowerCase() == receivedSignature.toLowerCase();
//       final status = isMatch ? '✅ MATCH' : '❌ NO MATCH';

//       print('   $description:');
//       print('     Payload: "$payload"');
//       print('     Signature: $signature');
//       print('     Status: $status');

//       if (isMatch) {
//         print('     🎯 FOUND MATCHING FORMAT: $description');
//       }
//     });
//   }

//   /// Generate HMAC-SHA256 signature using the exact Razorpay algorithm
//   static String _generateHmacSha256(String data, String secret) {
//     final secretBytes = utf8.encode(secret);
//     final dataBytes = utf8.encode(data);
//     final hmacSha256 = Hmac(sha256, secretBytes);
//     final digest = hmacSha256.convert(dataBytes);
//     return digest.toString();
//   }

//   /// Test with different secret keys (in case key mismatch)
//   static void testWithDifferentKeys() {
//     print('\n🔍 ════════════════════════════════════════════════════════');
//     print('🔍        TESTING WITH DIFFERENT SECRET KEYS');
//     print('🔍 ════════════════════════════════════════════════════════');

//     const String paymentId = 'pay_RpVweDlb36R4en';
//     const String orderId = 'order_RpVwHqT3BFcT7z';
//     const String receivedSignature =
//         'ee2f778230609534efbc686b5516d119901c1f089929954c0a3190bcea66dec4';
//     const String payload = '$orderId|$paymentId';

//     // Common test keys
//     final List<String> testKeys = [
//       'KA9JhnjkJzA8abjYqEjLcDDr', // Our current test key
//       'rzp_test_key_secret', // Generic test key
//       'test_secret_key', // Simple test key
//       'wrong_key_format', // Wrong format
//     ];

//     for (final key in testKeys) {
//       try {
//         final signature = _generateHmacSha256(payload, key);
//         final isMatch =
//             signature.toLowerCase() == receivedSignature.toLowerCase();
//         final status = isMatch ? '✅ MATCH FOUND!' : '❌ No match';

//         print('Key: "$key"');
//         print('   Generated: $signature');
//         print('   Status: $status');

//         if (isMatch) {
//           print('   🎯 CORRECT SECRET KEY IDENTIFIED: "$key"');
//         }
//       } catch (e) {
//         print('Key: "$key" - ERROR: $e');
//       }
//       print('');
//     }
//   }

//   /// Show detailed breakdown of signature verification process
//   static void showSignatureBreakdown() {
//     print('\n🔍 ════════════════════════════════════════════════════════');
//     print('🔍      RAZORPAY SIGNATURE VERIFICATION BREAKDOWN');
//     print('🔍 ════════════════════════════════════════════════════════');

//     print('\n📖 How Razorpay Signature Verification Works:');
//     print('   1. Razorpay sends: payment_id, order_id, signature');
//     print('   2. Create payload: "order_id|payment_id"');
//     print('   3. Generate HMAC-SHA256: HMAC(payload, secret_key)');
//     print('   4. Compare generated signature with received signature');
//     print('   5. Use timing-safe comparison to prevent timing attacks');

//     print('\n🔧 Implementation Requirements:');
//     print('   ✅ Payload format MUST be: "order_id|payment_id"');
//     print('   ✅ Use HMAC-SHA256 algorithm');
//     print('   ✅ Secret key must match Razorpay dashboard');
//     print('   ✅ Signature comparison must be case-insensitive');
//     print('   ✅ Use timing-safe comparison in production');

//     print('\n⚠️  Common Issues:');
//     print('   ❌ Wrong payload format (payment_id|order_id)');
//     print('   ❌ Different secret key between frontend/backend');
//     print('   ❌ Case-sensitive signature comparison');
//     print('   ❌ Including extra fields in payload');
//     print('   ❌ Not handling URL encoding properly');

//     print('\n🔍 ════════════════════════════════════════════════════════');
//   }

//   /// Create a visual widget for debugging in the app
//   static Widget createDebugWidget() {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Razorpay Signature Debugger'),
//         backgroundColor: Colors.blue[700],
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       '🔍 Signature Verification Test',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: () {
//                         testSignatureFromLogs();
//                       },
//                       child: const Text('Test Current Log Signature'),
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () {
//                         testWithDifferentKeys();
//                       },
//                       child: const Text('Test Different Secret Keys'),
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () {
//                         showSignatureBreakdown();
//                       },
//                       child: const Text('Show Verification Breakdown'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       '📋 Current Test Data',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildInfoRow('Payment ID', 'pay_RpVweDlb36R4en'),
//                     _buildInfoRow('Order ID', 'order_RpVwHqT3BFcT7z'),
//                     _buildInfoRow(
//                       'Signature',
//                       'ee2f778230609534efbc686b5516d119901c1f089929954c0a3190bcea66dec4',
//                     ),
//                     _buildInfoRow('Length', '64 characters'),
//                     _buildInfoRow('Status', 'Backend says: Invalid'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   static Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: SelectableText(
//               value,
//               style: const TextStyle(fontFamily: 'monospace'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// 🚨 EMERGENCY SIGNATURE VERIFICATION TEST
// /// Call this function immediately to test the signature from logs
// void debugRazorpaySignatureNow() {
//   print('\n🚨 EMERGENCY SIGNATURE VERIFICATION TEST');
//   RazorpaySignatureDebugger.testSignatureFromLogs();
//   RazorpaySignatureDebugger.testWithDifferentKeys();
//   RazorpaySignatureDebugger.showSignatureBreakdown();
// }
