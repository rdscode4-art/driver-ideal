// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:rideal_driver/controllers/rides_controller.dart';
// import 'package:rideal_driver/ride.dart';

// class AvailableRidesScreen extends StatelessWidget {
//   const AvailableRidesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final RidesController ridesController = Get.put(RidesController());

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'Available Rides',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.orange[600], // Changed from blue to orange
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => ridesController.refreshRides(),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         if (ridesController.isLoading.value) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!), // Changed from blue to orange
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Loading available rides...',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (ridesController.hasError.value) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.error_outline,
//                   size: 64,
//                   color: Colors.red[400],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Error Loading Rides',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   ridesController.errorMessage.value,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () => ridesController.refreshRides(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange[600], // Changed from blue to orange
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (ridesController.rides.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.local_taxi,
//                   size: 64,
//                   color: Colors.grey[400],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No Available Rides',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'There are no rides available at the moment.',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () => ridesController.refreshRides(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange[600], // Changed from blue to orange
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   ),
//                   child: const Text('Refresh'),
//                 ),
//               ],
//             ),
//           );
//         }

//         return Column(
//           children: [
//             // Summary header
//             Obx(() => Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.orange[600]!, Colors.orange[700]!], // Changed from blue to orange
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: _buildSummaryItem(
//                       'Total Rides',
//                       '${ridesController.totalRides}',
//                       Icons.local_taxi,
//                     ),
//                   ),
//                   Container(
//                     height: 40,
//                     width: 1,
//                     color: Colors.white30,
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildSummaryItem(
//                       'Avg. Fare',
//                       '₹${ridesController.averageFare.toStringAsFixed(0)}',
//                       Icons.account_balance_wallet,
//                     ),
//                   ),
//                 ],
//               ),
//             )),

//             // Rides list
//             Expanded(
//               child: RefreshIndicator(
//                 onRefresh: () => ridesController.refreshRides(),
//                 color: Colors.orange[600], // Orange refresh indicator
//                 child: ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: ridesController.rides.length,
//                   itemBuilder: (context, index) {
//                     final ride = ridesController.rides[index];
//                     return _buildRideCard(ride, ridesController);
//                   },
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildSummaryItem(String label, String value, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.white, size: 24),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white70,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRideCard(Ride ride, RidesController controller) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header row with ride type and fare
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: _getRideTypeColor(ride.rideType),
//                     borderRadius: BorderRadius.circular(6),
//                   ),

//                 ),
//                 Text(
//                   ride.formattedFare,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green[700],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Pickup and dropoff locations
//             _buildLocationRow(Icons.radio_button_checked, ride.pickupLocation, Colors.green),
//             const SizedBox(height: 8),
//             _buildLocationRow(Icons.location_on, ride.dropoffLocation, Colors.red),
//             const SizedBox(height: 12),

//             // Additional info row
//             Row(
//               children: [
//                 Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
//                 const SizedBox(width: 4),

//                 if (ride.numberOfPersons != null) ...[
//                   const SizedBox(width: 16),
//                   Icon(Icons.people, size: 14, color: Colors.grey[600]),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${ride.numberOfPersons} persons',
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                   ),
//                 ],
//                 if (ride.scheduledAt != null) ...[
//                   const SizedBox(width: 16),
//                   Icon(Icons.schedule, size: 14, color: Colors.orange[600]),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Scheduled',
//                     style: TextStyle(fontSize: 12, color: Colors.orange[600]),
//                   ),
//                 ],
//               ],
//             ),
//             const SizedBox(height: 16),

//             // Accept button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => controller.acceptRide(ride.id),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange[600], // Changed from blue to orange
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Accept Ride',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLocationRow(IconData icon, String location, Color color) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: color),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             location,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[800],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getRideTypeColor(String rideType) {
//     switch (rideType.toLowerCase()) {
//       case 'sedan':
//         return Colors.orange[600]!; // Changed from blue to orange to maintain consistency
//       case 'bike':
//         return Colors.orange[600]!;
//       case 'ev':
//         return Colors.green[600]!;
//       case 'suv':
//         return Colors.orange[700]!; // Changed from purple to darker orange
//       default:
//         return Colors.orange[500]!; // Changed from grey to lighter orange
//     }
//   }
// }
