// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'simple_subscription_controller.dart';

// class SimpleSubscriptionTestPage extends StatelessWidget {
//   const SimpleSubscriptionTestPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(SimpleSubscriptionController());
    
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Simple Subscription Test'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status
//             Obx(() => Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: controller.isProcessingPayment.value 
//                     ? Colors.orange.withOpacity(0.1)
//                     : Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 controller.isProcessingPayment.value 
//                     ? 'Processing Payment...'
//                     : 'Ready for Payment Test',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             )),
            
//             SizedBox(height: 20),
            
//             Text(
//               'Test Subscription Plans',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
            
//             SizedBox(height: 16),
            
//             // Test Plan 1
//             _buildPlanCard(
//               controller,
//               'Basic Plan',
//               '₹99',
//               '1 month',
//               SubscriptionPlan(
//                 id: 'basic_test',
//                 title: 'Basic Plan',
//                 rate: 99,
//                 durationInMonths: 1,
//               ),
//             ),
            
//             SizedBox(height: 12),
            
//             // Test Plan 2
//             _buildPlanCard(
//               controller,
//               'Premium Plan',
//               '₹199',
//               '3 months',
//               SubscriptionPlan(
//                 id: 'premium_test',
//                 title: 'Premium Plan',
//                 rate: 199,
//                 durationInMonths: 3,
//               ),
//             ),
            
//             Spacer(),
            
//             // Instructions
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Test Instructions:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     '1. Tap any plan to start payment\n'
//                     '2. Complete payment in Razorpay UI\n'
//                     '3. Check terminal for callback logs\n'
//                     '4. Success/error will show in snackbar',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildPlanCard(
//     SimpleSubscriptionController controller,
//     String title,
//     String price,
//     String duration,
//     SubscriptionPlan plan,
//   ) {
//     return Card(
//       elevation: 2,
//       child: InkWell(
//         onTap: () => controller.startPayment(plan),
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       duration,
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 price,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue[700],
//                 ),
//               ),
//               SizedBox(width: 8),
//               Icon(
//                 Icons.arrow_forward_ios,
//                 color: Colors.grey[400],
//                 size: 16,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }