// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../controllers/subscription_controller.dart';
// import '../../models/subscription_status_model.dart';

// class SubscriptionPlansScreen extends StatefulWidget {
//   const SubscriptionPlansScreen({super.key});

//   @override
//   State<SubscriptionPlansScreen> createState() =>
//       _SubscriptionPlansScreenState();
// }

// class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
//   late final SSubscriptionController controller;
//   bool _isControllerOwned = false;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize controller once in initState with proper error handling
//     try {
//       // Try to find existing controller first
//       controller = Get.find<SSubscriptionController>();
//       _isControllerOwned = false;
//       print('✅ Found existing SubscriptionController');
//     } catch (e) {
//       // If not found, create new one
//       print('⚠️ SubscriptionController not found, creating new one');
//       controller = Get.put(SSubscriptionController(), permanent: false);
//       _isControllerOwned = true;
//     }

//     // Load subscription status after first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         controller.fetchSubscriptionStatus();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     // Clean up controller if we created it
//     if (_isControllerOwned) {
//       try {
//         Get.delete<SSubscriptionController>();
//         print('🗑️ Disposed SubscriptionController');
//       } catch (e) {
//         print('⚠️ Controller dispose failed: $e');
//       }
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Subscription Plans'),
//         backgroundColor: Colors.orange[700],
//         foregroundColor: Colors.white,
//         elevation: 0,
//         automaticallyImplyLeading: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             // Always allow back navigation
//             Navigator.of(context).pop();
//           },
//         ),
//         actions: [
//           Obx(() {
//             if (controller.activeSubscription.value != null) {
//               return Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Chip(
//                   label: const Text(
//                     'Active',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   backgroundColor: Colors.green[600],
//                   avatar: const Icon(
//                     Icons.check_circle,
//                     color: Colors.white,
//                     size: 16,
//                   ),
//                 ),
//               );
//             }
//             return const SizedBox.shrink();
//           }),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: controller.refreshSubscriptionStatus,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Subscription Status Card
//               _buildSubscriptionStatusCard(),
//               const SizedBox(height: 20),

//               // App Logo and Title
//               _buildHeaderSection(),
//               const SizedBox(height: 30),

//               // Available Plans (if no active subscription)
//               Obx(() {
//                 if (controller.activeSubscription.value == null) {
//                   return _buildAvailablePlans();
//                 }
//                 return const SizedBox.shrink();
//               }),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Build subscription status card
//   Widget _buildSubscriptionStatusCard() {
//     return Obx(() {
//       if (controller.isLoading.value) {
//         return _buildLoadingCard();
//       }

//       final subscription = controller.activeSubscription.value;

//       if (subscription != null) {
//         return _buildActiveSubscriptionCard(subscription);
//       } else {
//         return _buildNoSubscriptionCard();
//       }
//     });
//   }

//   /// Build loading card
//   Widget _buildLoadingCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: const Row(
//         children: [
//           CircularProgressIndicator(strokeWidth: 2),
//           SizedBox(width: 16),
//           Text(
//             'Checking subscription status...',
//             style: TextStyle(fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build active subscription card
//   Widget _buildActiveSubscriptionCard(SubscriptionStatusModel subscription) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//         border: Border.all(color: Colors.green[200]!, width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header row with plan name and status badge
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       subscription.planName ?? 'Unknown Plan',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '₹${subscription.planRate}',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green[700],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.green[600],
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.check_circle,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       subscription.status.toUpperCase(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Duration info
//           Row(
//             children: [
//               Icon(Icons.schedule, color: Colors.grey[600], size: 16),
//               const SizedBox(width: 8),
//               Text(
//                 '${subscription.daysRemaining} days remaining',
//                 style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),

//           // Expiry info
//           Row(
//             children: [
//               Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
//               const SizedBox(width: 8),
//               Text(
//                 'Expires on ${subscription.formattedEndDate}',
//                 style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Action buttons
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => Get.offAllNamed('/'),
//                   icon: const Icon(Icons.dashboard),
//                   label: const Text('Go to Dashboard'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green[600],
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               IconButton(
//                 onPressed: controller.refreshSubscriptionStatus,
//                 icon: const Icon(Icons.refresh),
//                 tooltip: 'Refresh Status',
//                 style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build no subscription card
//   Widget _buildNoSubscriptionCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue[200]!, width: 1),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'No Active Subscription',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[800],
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Select a plan below to get started.',
//                   style: TextStyle(fontSize: 14, color: Colors.blue[700]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build header section
//   Widget _buildHeaderSection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.orange[600]!, Colors.orange[700]!],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: [
//           // Logo would go here
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.directions_car,
//               color: Colors.orange,
//               size: 30,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Choose Your Plan',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Select the best plan for your needs',
//             style: TextStyle(fontSize: 16, color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build available plans section
//   Widget _buildAvailablePlans() {
//     // Mock plans data (replace with actual plans from API)
//     final plans = [
//       {'name': 'Pookie plan', 'price': 1, 'duration': '3 Months'},
//       {'name': 'Premium Plan', 'price': 250, 'duration': '3 Months'},
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Available Plans',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         ...plans.map((plan) => _buildPlanCard(plan)),
//       ],
//     );
//   }

//   /// Build individual plan card
//   Widget _buildPlanCard(Map<String, dynamic> plan) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 plan['name'],
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.green[100],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   plan['duration'],
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green[700],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '₹${plan['price']}',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.orange[700],
//             ),
//           ),
//           Text(
//             '₹${(plan['price'] / 3).toStringAsFixed(0)} per month',
//             style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () {
//                 // Handle plan selection
//                 Get.snackbar(
//                   'Plan Selected',
//                   'You selected ${plan['name']}',
//                   backgroundColor: Colors.orange[100],
//                   colorText: Colors.orange[800],
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange[700],
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.shopping_cart, size: 20),
//                   const SizedBox(width: 8),
//                   const Text(
//                     'Buy Subscription',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(width: 8),
//                   const Icon(Icons.arrow_forward, size: 20),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
