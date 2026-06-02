// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/location_controller.dart';
// import '../controllers/navigation_controller.dart';
//
// class MapScreen extends StatelessWidget {
//   const MapScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final LocationController locationController = Get.put(LocationController());
//     final NavigationController navigationController = Get.put(NavigationController());
//
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: CustomScrollView(
//         slivers: [
//           // Custom App Bar with gradient (matching other screens)
//           SliverAppBar(
//             expandedHeight: 160,
//             backgroundColor: Colors.transparent,
//             // elevation: 0,
//             pinned: true,
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white),
//               onPressed: () => Get.back(),
//             ),
//             flexibleSpace: FlexibleSpaceBar(
//               background: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.orange[600]!, Colors.orange[400]!],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(25),
//                     bottomRight: Radius.circular(25),
//                   ),
//                 ),
//                 child: SafeArea(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Map View & Navigation',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Obx(() => Text(
//                           navigationController.isNavigating.value
//                             ? 'Navigation Active'
//                             : 'Ready to Navigate',
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 16,
//                           ),
//                         )),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           // Main Content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 children: [
//                   // Current Location Card
//                   _buildLocationCard(locationController),
//
//                   const SizedBox(height: 20),
//
//                   // Navigation Card
//                   _buildNavigationCard(navigationController, locationController),
//
//                   const SizedBox(height: 20),
//
//                   // Map Placeholder Card
//                   _buildMapCard(),
//
//                   const SizedBox(height: 20),
//
//                   // Quick Actions
//                   _buildQuickActions(navigationController, locationController),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLocationCard(LocationController locationController) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.location_on, color: Colors.blue[700], size: 24),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Current Location',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Obx(() {
//               if (locationController.isLoading.value) {
//                 return const Row(
//                   children: [
//                     SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                     SizedBox(width: 12),
//                     Text('Getting location...'),
//                   ],
//                 );
//               }
//
//               if (locationController.currentAddress.value.isEmpty) {
//                 return const Text(
//                   'Location not available',
//                   style: TextStyle(color: Colors.grey),
//                 );
//               }
//
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     locationController.currentAddress.value,
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 8),
//                   if (locationController.currentLatitude.value != 0.0)
//                     Text(
//                       'Lat: ${locationController.currentLatitude.value.toStringAsFixed(6)}, '
//                       'Lng: ${locationController.currentLongitude.value.toStringAsFixed(6)}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                 ],
//               );
//             }),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => locationController.getCurrentLocation(),
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Refresh Location'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[700],
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavigationCard(NavigationController navigationController, LocationController locationController) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.navigation, color: Colors.green[700], size: 24),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Navigation',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             Obx(() {
//               if (navigationController.isNavigating.value) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Navigation Status
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.directions, color: Colors.green[700], size: 16),
//                           const SizedBox(width: 6),
//                           Text(
//                             'Navigating',
//                             style: TextStyle(
//                               color: Colors.green[700],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Current Step
//                     Text(
//                       navigationController.currentStep.value,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Navigation Stats
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildNavStat(
//                             'Distance',
//                             navigationController.formattedRemainingDistance,
//                             Icons.straighten,
//                           ),
//                         ),
//                         Expanded(
//                           child: _buildNavStat(
//                             'ETA',
//                             navigationController.formattedEstimatedTime,
//                             Icons.access_time,
//                           ),
//                         ),
//                         Expanded(
//                           child: _buildNavStat(
//                             'Speed',
//                             '${navigationController.currentSpeed.value.toStringAsFixed(0)} km/h',
//                             Icons.speed,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Progress Bar
//                     LinearProgressIndicator(
//                       value: navigationController.navigationProgress.value,
//                       backgroundColor: Colors.grey[300],
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Stop Navigation Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: () => navigationController.stopNavigation(),
//                         icon: const Icon(Icons.stop),
//                         label: const Text('Stop Navigation'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red[600],
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               } else {
//                 return Column(
//                   children: [
//                     Text(
//                       'Enter destination to start navigation',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       decoration: InputDecoration(
//                         hintText: 'Enter destination address',
//                         prefixIcon: const Icon(Icons.search),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       onSubmitted: (address) => _startNavigationToAddress(
//                         address,
//                         navigationController,
//                         locationController,
//                       ),
//                     ),
//                   ],
//                 );
//               }
//             }),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavStat(String label, String value, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.grey[600], size: 20),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMapCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Container(
//         height: 200,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           color: Colors.grey[100],
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.map,
//                 size: 48,
//                 color: Colors.grey[400],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Interactive Map',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Google Maps integration coming soon',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[500],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickActions(NavigationController navigationController, LocationController locationController) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Quick Actions',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildQuickActionButton(
//                     'Share Location',
//                     Icons.share_location,
//                     Colors.blue,
//                     () => _shareCurrentLocation(locationController),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildQuickActionButton(
//                     'Update Location',
//                     Icons.my_location,
//                     Colors.green,
//                     () => navigationController.updateLocation(),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildQuickActionButton(
//                     'Emergency',
//                     Icons.emergency,
//                     Colors.red,
//                     () => _handleEmergency(),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildQuickActionButton(
//                     'Settings',
//                     Icons.settings,
//                     Colors.orange,
//                     () => _openMapSettings(),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickActionButton(
//     String label,
//     IconData icon,
//     Color color,
//     VoidCallback onPressed,
//   ) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color.withValues(alpha: 0.1),
//         foregroundColor: color,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//           side: BorderSide(color: color.withValues(alpha: 0.3)),
//         ),
//         padding: const EdgeInsets.symmetric(vertical: 16),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: 24),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _startNavigationToAddress(
//     String address,
//     NavigationController navigationController,
//     LocationController locationController,
//   ) async {
//     if (address.trim().isEmpty) {
//       Get.snackbar('Error', 'Please enter a destination address');
//       return;
//     }
//
//     Get.dialog(
//       const Center(
//         child: CircularProgressIndicator(),
//       ),
//       barrierDismissible: false,
//     );
//
//     try {
//       // This would typically use a geocoding service to convert address to coordinates
//       // For now, using mock coordinates
//       await navigationController.startNavigation(
//         latitude: 37.7749, // Mock coordinates for San Francisco
//         longitude: -122.4194,
//         address: address,
//       );
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to start navigation: $e');
//     } finally {
//       Get.back(); // Close loading dialog
//     }
//   }
//
//   void _shareCurrentLocation(LocationController locationController) {
//     if (locationController.currentLatitude.value == 0.0) {
//       Get.snackbar('Error', 'Current location not available');
//       return;
//     }
//
//     final location = '${locationController.currentLatitude.value},${locationController.currentLongitude.value}';
//     Get.snackbar(
//       'Location Shared',
//       'Location: $location\n${locationController.currentAddress.value}',
//       duration: const Duration(seconds: 5),
//     );
//   }
//
//   void _handleEmergency() {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Emergency'),
//         content: const Text('Emergency services will be contacted with your current location.'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               Get.snackbar('Emergency', 'Emergency services contacted');
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Confirm', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _openMapSettings() {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Map Settings',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: const Icon(Icons.map),
//               title: const Text('Map Type'),
//               subtitle: const Text('Normal'),
//               onTap: () {},
//             ),
//             ListTile(
//               leading: const Icon(Icons.traffic),
//               title: const Text('Show Traffic'),
//               trailing: Switch(
//                 value: true,
//                 onChanged: (value) {},
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.volume_up),
//               title: const Text('Voice Navigation'),
//               trailing: Switch(
//                 value: true,
//                 onChanged: (value) {},
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => Get.back(),
//                 child: const Text('Close'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
