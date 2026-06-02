// import 'package:rideal_driver/core/token_manager.dart';
// import 'package:rideal_driver/subscriptionscreen.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// class SubscriptionStatus {
//   final bool subscribe;
//   final Plan? planId;
//   final DateTime? startDate;
//   final DateTime? endDate;

//   SubscriptionStatus({
//     required this.subscribe,
//     this.planId,
//     this.startDate,
//     this.endDate,
//   });

//   factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
//     return SubscriptionStatus(
//       subscribe: json['subscribe'],
//       planId: json['subscription'] != null
//           ? Plan.fromJson(json['subscription']['planId'])
//           : null,
//       startDate: json['subscription'] != null
//           ? DateTime.parse(json['subscription']['startDate'])
//           : null,
//       endDate: json['subscription'] != null
//           ? DateTime.parse(json['subscription']['endDate'])
//           : null,
//     );
//   }
// }
// class SubscriptionStatusScreen extends StatefulWidget {
//   const SubscriptionStatusScreen({super.key});

//   @override
//   _SubscriptionStatusScreenState createState() =>
//       _SubscriptionStatusScreenState();
// }

// class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
//   SubscriptionStatus? status;
//   bool isLoading = true;
//   String? errorMessage;
//   // ✅ FIX 1: Get token VALUE, not the Rx object
//     final token = TokenManager.instance.authToken.value;
    
//     // ✅ FIX 2: Get driver ID from TokenManager
//     final driverId = TokenManager.instance.userId.value;
    

//   @override
//   void initState() {
//     super.initState();
//     fetchSubscriptionStatus();
//   }

//   Future<void> fetchSubscriptionStatus() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       final response = await http.get(
//         Uri.parse(
//             'https://backend.ridealmobility.com/subscription-status?driverId=$driverId'),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success']) {
//           setState(() {
//             status = SubscriptionStatus.fromJson(data);
//             isLoading = false;
//           });
//         } else {
//           setState(() {
//             errorMessage = 'Failed to load subscription status';
//             isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           errorMessage = 'Server error: ${response.statusCode}';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error: $e';
//         isLoading = false;
//       });
//     }
//   }

//   String formatDate(DateTime? date) {
//     if (date == null) return 'N/A';
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   int getDaysRemaining(DateTime? endDate) {
//     if (endDate == null) return 0;
//     return endDate.difference(DateTime.now()).inDays;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Subscription Status'),
//         elevation: 0,
//         backgroundColor: Colors.green[600],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : errorMessage != null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.error_outline, size: 60, color: Colors.red),
//                       const SizedBox(height: 16),
//                       Text(errorMessage!,
//                           style: const TextStyle(color: Colors.red)),
//                       const SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: fetchSubscriptionStatus,
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 )
//               : status == null
//                   ? const Center(child: Text('No subscription data'))
//                   : SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(30),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: status!.subscribe
//                                     ? [Colors.green[600]!, Colors.green[800]!]
//                                     : [Colors.orange[600]!, Colors.orange[800]!],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: const BorderRadius.only(
//                                 bottomLeft: Radius.circular(30),
//                                 bottomRight: Radius.circular(30),
//                               ),
//                             ),
//                             child: Column(
//                               children: [
//                                 Icon(
//                                   status!.subscribe
//                                       ? Icons.check_circle
//                                       : Icons.info,
//                                   color: Colors.white,
//                                   size: 80,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   status!.subscribe
//                                       ? 'Active Subscription'
//                                       : 'No Active Subscription',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 26,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 if (status!.subscribe &&
//                                     status!.endDate != null)
//                                   Padding(
//                                     padding: const EdgeInsets.only(top: 8),
//                                     child: Text(
//                                       '${getDaysRemaining(status!.endDate)} days remaining',
//                                       style: const TextStyle(
//                                         color: Colors.white70,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ),
//                           if (status!.subscribe && status!.planId != null)
//                             Padding(
//                               padding: const EdgeInsets.all(20),
//                               child: Column(
//                                 children: [
//                                   Card(
//                                     elevation: 4,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(16),
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(20),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             'Plan Details',
//                                             style: TextStyle(
//                                               fontSize: 20,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.orange[800],
//                                             ),
//                                           ),
//                                           const SizedBox(height: 20),
//                                           InfoRow(
//                                             icon: Icons.card_membership,
//                                             label: 'Plan',
//                                             value: status!.planId!.title,
//                                           ),
//                                           const Divider(height: 30),
//                                           InfoRow(
//                                             icon: Icons.currency_rupee,
//                                             label: 'Rate',
//                                             value:
//                                                 '₹${status!.planId!.rate}/month',
//                                           ),
//                                           const Divider(height: 30),
//                                           InfoRow(
//                                             icon: Icons.access_time,
//                                             label: 'Duration',
//                                             value:
//                                                 '${status!.planId!.durationInMonths} months',
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Card(
//                                     elevation: 4,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(16),
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(20),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             'Subscription Period',
//                                             style: TextStyle(
//                                               fontSize: 20,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.orange[800],
//                                             ),
//                                           ),
//                                           const SizedBox(height: 20),
//                                           InfoRow(
//                                             icon: Icons.play_circle_outline,
//                                             label: 'Start Date',
//                                             value: formatDate(status!.startDate),
//                                           ),
//                                           const Divider(height: 30),
//                                           InfoRow(
//                                             icon: Icons.event,
//                                             label: 'End Date',
//                                             value: formatDate(status!.endDate),
//                                           ),
//                                           const Divider(height: 30),
//                                           InfoRow(
//                                             icon: Icons.timer,
//                                             label: 'Days Remaining',
//                                             value:
//                                                 '${getDaysRemaining(status!.endDate)} days',
//                                             valueColor: Colors.green[700],
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           if (!status!.subscribe)
//                             Padding(
//                               padding: const EdgeInsets.all(20),
//                               child: Column(
//                                 children: [
//                                   Icon(Icons.shopping_cart,
//                                       size: 80, color: Colors.grey[400]),
//                                   const SizedBox(height: 20),
//                                   Text(
//                                     'You don\'t have an active subscription',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       color: Colors.grey[600],
//                                     ),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: 30),
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       Navigator.pop(context);
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.blue[700],
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 40,
//                                         vertical: 16,
//                                       ),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                     child: const Text(
//                                       'Browse Plans',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//     );
//   }
// }
// class InfoRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color? valueColor;

//   const InfoRow({super.key, 
//     required this.icon,
//     required this.label,
//     required this.value,
//     this.valueColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.green[50],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: Colors.green[700], size: 24),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: valueColor ?? Colors.grey[800],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }