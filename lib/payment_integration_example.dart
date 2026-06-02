// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'services/api_service.dart';
// import 'services/new_razorpay_service.dart';
// import 'controllers/payment_controller.dart';

// /// 🚀 COMPLETE FLUTTER + RAZORPAY + BACKEND INTEGRATION EXAMPLE
// ///
// /// This example shows how to use the complete payment system
// /// Follow this pattern in your existing app

// class PaymentIntegrationExample extends StatefulWidget {
//   const PaymentIntegrationExample({super.key});

//   @override
//   State<PaymentIntegrationExample> createState() =>
//       _PaymentIntegrationExampleState();
// }

// class _PaymentIntegrationExampleState extends State<PaymentIntegrationExample> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeServices();
//   }

//   /// Initialize all required services
//   void _initializeServices() {
//     // Initialize services in correct order
//     Get.put(ApiService(), permanent: true);
//     Get.put(RazorpayService(), permanent: true);
//     Get.put(PaymentController(), permanent: true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('RiDeal Payment Integration'),
//         backgroundColor: Colors.blue[700],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildQuickStartCard(),
//             const SizedBox(height: 20),
//             _buildTestButtons(),
//             const SizedBox(height: 20),
//             _buildStatusDisplay(),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Quick start information card
//   Widget _buildQuickStartCard() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.rocket_launch, color: Colors.blue[700]),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Quick Start Guide',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               '1. Tap "Buy Subscription" to start payment flow\n'
//               '2. Backend creates Razorpay order\n'
//               '3. Razorpay checkout opens\n'
//               '4. Payment success triggers verification\n'
//               '5. Backend verifies and activates subscription',
//               style: TextStyle(height: 1.4),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Test buttons for different scenarios
//   Widget _buildTestButtons() {
//     final PaymentController controller = Get.find<PaymentController>();

//     return Column(
//       children: [
//         // Test Pookie Plan Button
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton.icon(
//             onPressed: () => _testPookiePlan(controller),
//             icon: const Icon(Icons.star),
//             label: const Text('Test: Buy Pookie Plan (₹100)'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green[600],
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),

//         // Test API Connectivity
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: OutlinedButton.icon(
//             onPressed: () => _testAPIConnectivity(),
//             icon: const Icon(Icons.wifi),
//             label: const Text('Test API Connectivity'),
//           ),
//         ),
//         const SizedBox(height: 12),

//         // Manual Test with Custom Values
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton.icon(
//             onPressed: () => _showCustomPaymentDialog(controller),
//             icon: const Icon(Icons.settings),
//             label: const Text('Custom Payment Test'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange[600],
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   /// Status display with real-time updates
//   Widget _buildStatusDisplay() {
//     final PaymentController controller = Get.find<PaymentController>();

//     return Card(
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Payment Status',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Obx(
//               () => Column(
//                 children: [
//                   _buildStatusRow(
//                     'Status',
//                     controller.paymentStatus.value.name,
//                   ),
//                   _buildStatusRow(
//                     'Loading',
//                     controller.isLoading.value.toString(),
//                   ),
//                   _buildStatusRow(
//                     'Processing',
//                     controller.isProcessingPayment.value.toString(),
//                   ),
//                   if (controller.errorMessage.value.isNotEmpty)
//                     _buildStatusRow(
//                       'Error',
//                       controller.errorMessage.value,
//                       isError: true,
//                     ),
//                   if (controller.successMessage.value.isNotEmpty)
//                     _buildStatusRow(
//                       'Success',
//                       controller.successMessage.value,
//                       isSuccess: true,
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusRow(
//     String label,
//     String value, {
//     bool isError = false,
//     bool isSuccess = false,
//   }) {
//     Color textColor = Colors.black87;
//     if (isError) textColor = Colors.red;
//     if (isSuccess) textColor = Colors.green;

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//           Expanded(
//             child: Text(value, style: TextStyle(color: textColor)),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Test Pookie Plan purchase
//   Future<void> _testPookiePlan(PaymentController controller) async {
//     try {
//       await controller.buySubscription(
//         planType: 'Pookie plan',
//         amount: 100.0,
//         contact: '9876543210',
//         email: 'test@example.com',
//       );
//     } catch (e) {
//       _showErrorDialog('Test Failed', e.toString());
//     }
//   }

//   /// Test API connectivity
//   Future<void> _testAPIConnectivity() async {
//     try {
//       final apiService = Get.find<ApiService>();

//       // Show loading
//       Get.dialog(
//         const Center(child: CircularProgressIndicator()),
//         barrierDismissible: false,
//       );

//       // Test buy subscription API (this will fail but shows connectivity)
//       final response = await apiService.buySubscription(
//         driverId: "68df63a3085a93405fed4fe6",
//         planType: "Test Plan",
//         amount: 1.0,
//       );

//       Get.back(); // Close loading

//       if (response.isSuccess) {
//         _showSuccessDialog('API Test', 'Backend connection successful!');
//       } else {
//         _showInfoDialog('API Test', 'Backend responded: ${response.message}');
//       }
//     } catch (e) {
//       Get.back(); // Close loading
//       _showErrorDialog('API Test Failed', e.toString());
//     }
//   }

//   /// Show custom payment dialog
//   void _showCustomPaymentDialog(PaymentController controller) {
//     final planController = TextEditingController(text: 'Custom Plan');
//     final amountController = TextEditingController(text: '50');
//     final contactController = TextEditingController(text: '9876543210');
//     final emailController = TextEditingController(text: 'test@example.com');

//     Get.dialog(
//       AlertDialog(
//         title: const Text('Custom Payment Test'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: planController,
//                 decoration: const InputDecoration(
//                   labelText: 'Plan Type',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: amountController,
//                 decoration: const InputDecoration(
//                   labelText: 'Amount (₹)',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.number,
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: contactController,
//                 decoration: const InputDecoration(
//                   labelText: 'Contact',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               controller.buySubscription(
//                 planType: planController.text,
//                 amount: double.tryParse(amountController.text) ?? 0.0,
//                 contact: contactController.text,
//                 email: emailController.text,
//               );
//             },
//             child: const Text('Start Payment'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper methods for dialogs
//   void _showErrorDialog(String title, String message) {
//     Get.dialog(
//       AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('OK')),
//         ],
//       ),
//     );
//   }

//   void _showSuccessDialog(String title, String message) {
//     Get.dialog(
//       AlertDialog(
//         title: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.green),
//             const SizedBox(width: 8),
//             Text(title),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('OK')),
//         ],
//       ),
//     );
//   }

//   void _showInfoDialog(String title, String message) {
//     Get.dialog(
//       AlertDialog(
//         title: Row(
//           children: [
//             const Icon(Icons.info, color: Colors.blue),
//             const SizedBox(width: 8),
//             Text(title),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('OK')),
//         ],
//       ),
//     );
//   }
// }

// /// 📝 HOW TO USE IN YOUR EXISTING APP:

// // 1. Add this to your main.dart:
// /*
// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'RiDeal Driver',
//       home: PaymentIntegrationExample(), // Or your existing home screen
//     );
//   }
// }
// */

// // 2. In any screen where you want to add payment:
// /*
// class YourExistingScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ElevatedButton(
//         onPressed: () async {
//           // Initialize services if not already done
//           if (!Get.isRegistered<PaymentController>()) {
//             Get.put(ApiService());
//             Get.put(RazorpayService());
//             Get.put(PaymentController());
//           }
          
//           final controller = Get.find<PaymentController>();
          
//           // Start payment flow
//           await controller.buySubscription(
//             planType: 'Pookie plan',
//             amount: 100.0,
//             contact: 'USER_PHONE_NUMBER',
//             email: 'USER_EMAIL',
//           );
//         },
//         child: Text('Buy Subscription'),
//       ),
//     );
//   }
// }
// */

// // 3. cURL command for testing backend directly:
// /*
// curl --location 'https://backend.ridealmobility.com/verify-subscription-payment' \
// --header 'Content-Type: application/json' \
// --data '{
//   "driverId": "68df63a3085a93405fed4fe6",
//   "planId": "68ede14b0efa19665b81303e",
//   "razorpay_payment_id": "pay_PxQbA1K2Qv1234",
//   "razorpay_order_id": "order_RoKE9UrbjdZ6Y5",
//   "razorpay_signature": "b0d1ff44eaa4a67c3fc02459a123456789abcdfe"
// }'
// */
