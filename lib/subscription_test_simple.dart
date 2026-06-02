// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:rideal_driver/subscriptioncontroller.dart';

// class SubscriptionTestScreen extends StatelessWidget {
//   const SubscriptionTestScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Subscription Test'),
//         backgroundColor: Colors.blue[700],
//         foregroundColor: Colors.white,
//       ),
//       body: GetBuilder<SubscriptionController>(
//         init: SubscriptionController(),
//         builder: (controller) {
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Status Card
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Subscription Status',
//                           style: Theme.of(context).textTheme.headlineSmall,
//                         ),
//                         const SizedBox(height: 8),
//                         Obx(
//                           () => Row(
//                             children: [
//                               Icon(
//                                 controller.hasSubscription.value
//                                     ? Icons.check_circle
//                                     : Icons.cancel,
//                                 color: controller.hasSubscription.value
//                                     ? Colors.green
//                                     : Colors.red,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 controller.hasSubscription.value
//                                     ? 'Active'
//                                     : 'Inactive',
//                                 style: TextStyle(
//                                   color: controller.hasSubscription.value
//                                       ? Colors.green
//                                       : Colors.red,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Obx(() {
//                           if (controller.expiryDate.value != null) {
//                             return Text(
//                               'Expires: ${controller.expiryDate.value}',
//                             );
//                           }
//                           return const SizedBox.shrink();
//                         }),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Payment Details Card
//                 Obx(
//                   () => Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Last Payment Details',
//                             style: Theme.of(context).textTheme.headlineSmall,
//                           ),
//                           const SizedBox(height: 8),
//                           if (controller.paymentId.value != null) ...[
//                             Text('Payment ID: ${controller.paymentId.value}'),
//                             const SizedBox(height: 4),
//                             Text('Order ID: ${controller.orderId.value}'),
//                             const SizedBox(height: 4),
//                             Text('Signature: ${controller.signature.value}'),
//                           ] else ...[
//                             const Text('No payment completed yet'),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Test Button
//                 ElevatedButton(
//                   onPressed: () {
//                     // Test payment callback manually
//                     print('🧪 Manual Test Button Pressed');
//                     Get.snackbar(
//                       '🧪 Test',
//                       'Check terminal for payment callback logs',
//                       backgroundColor: Colors.blue[100],
//                       colorText: Colors.blue[800],
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[700],
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Test Payment Callback'),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
