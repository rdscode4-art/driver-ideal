// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geocoding/geocoding.dart' as geocoding;
// import '../data/models/future_ride_models.dart';
//
// class FutureRideDetailsScreen extends StatefulWidget {
//   @override
//   _FutureRideDetailsScreenState createState() => _FutureRideDetailsScreenState();
// }
//
// class _FutureRideDetailsScreenState extends State<FutureRideDetailsScreen> {
//   GoogleMapController? _mapController;
//   FutureRide? ride;
//   Set<Marker> _markers = {};
//   LatLng? _pickupCoordinates;
//   LatLng? _dropoffCoordinates;
//   bool _isLoadingCoordinates = true;
//
//   @override
//   void initState() {
//     super.initState();
//     ride = Get.arguments as FutureRide?;
//     if (ride != null) {
//       _loadCoordinates();
//     }
//   }
//
//   Future<void> _loadCoordinates() async {
//     try {
//       setState(() {
//         _isLoadingCoordinates = true;
//       });
//
//       // Get coordinates for pickup location
//       List<geocoding.Location> pickupLocations = await geocoding.locationFromAddress(ride!.fromLocation.address);
//       if (pickupLocations.isNotEmpty) {
//         _pickupCoordinates = LatLng(pickupLocations.first.latitude, pickupLocations.first.longitude);
//       }
//
//       // Get coordinates for dropoff location
//       List<geocoding.Location> dropoffLocations = await geocoding.locationFromAddress(ride!.toLocation.address);
//       if (dropoffLocations.isNotEmpty) {
//         _dropoffCoordinates = LatLng(dropoffLocations.first.latitude, dropoffLocations.first.longitude);
//       }
//
//       _createMarkers();
//
//     } catch (e) {
//       print('Error loading coordinates: $e');
//       // Fallback to default coordinates from the ride object
//       _pickupCoordinates = LatLng(ride!.fromLocation.lat, ride!.fromLocation.lng);
//       _dropoffCoordinates = LatLng(ride!.toLocation.lat, ride!.toLocation.lng);
//       _createMarkers();
//     } finally {
//       setState(() {
//         _isLoadingCoordinates = false;
//       });
//     }
//   }
//
//   void _createMarkers() {
//     _markers.clear();
//
//     if (_pickupCoordinates != null) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId('pickup'),
//           position: _pickupCoordinates!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//           infoWindow: InfoWindow(
//             title: 'Pickup Location',
//             snippet: ride!.fromLocation.address,
//           ),
//         ),
//       );
//     }
//
//     if (_dropoffCoordinates != null) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId('dropoff'),
//           position: _dropoffCoordinates!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: InfoWindow(
//             title: 'Dropoff Location',
//             snippet: ride!.toLocation.address,
//           ),
//         ),
//       );
//     }
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     if (_pickupCoordinates != null && _dropoffCoordinates != null) {
//       _fitMarkersInView();
//     }
//   }
//
//   void _fitMarkersInView() {
//     if (_pickupCoordinates != null && _dropoffCoordinates != null) {
//       LatLngBounds bounds = LatLngBounds(
//         southwest: LatLng(
//           _pickupCoordinates!.latitude < _dropoffCoordinates!.latitude
//               ? _pickupCoordinates!.latitude
//               : _dropoffCoordinates!.latitude,
//           _pickupCoordinates!.longitude < _dropoffCoordinates!.longitude
//               ? _pickupCoordinates!.longitude
//               : _dropoffCoordinates!.longitude,
//         ),
//         northeast: LatLng(
//           _pickupCoordinates!.latitude > _dropoffCoordinates!.latitude
//               ? _pickupCoordinates!.latitude
//               : _dropoffCoordinates!.latitude,
//           _pickupCoordinates!.longitude > _dropoffCoordinates!.longitude
//               ? _pickupCoordinates!.longitude
//               : _dropoffCoordinates!.longitude,
//         ),
//       );
//
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 100.0),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (ride == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('Ride Details'),
//           backgroundColor: Colors.blue[700],
//         ),
//         body: Center(
//           child: Text('No ride data available'),
//         ),
//       );
//     }
//
//     return Scaffold(
//       body: Column(
//         children: [
//           // App Bar
//           Container(
//             height: MediaQuery.of(context).padding.top + 56,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blue[700]!, Colors.blue[600]!],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: SafeArea(
//               child: AppBar(
//                 title: Text(
//                   'Ride Details',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 backgroundColor: Colors.transparent,
//                 elevation: 0,
//                 leading: IconButton(
//                   icon: Icon(Icons.arrow_back, color: Colors.white),
//                   onPressed: () => Get.back(),
//                 ),
//               ),
//             ),
//           ),
//
//           // Map Section (Half Screen)
//           Expanded(
//             flex: 1,
//             child: Container(
//               width: double.infinity,
//               child: _isLoadingCoordinates
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(),
//                           SizedBox(height: 16),
//                           Text('Loading map...'),
//                         ],
//                       ),
//                     )
//                   : GoogleMap(
//                       onMapCreated: _onMapCreated,
//                       initialCameraPosition: CameraPosition(
//                         target: _pickupCoordinates ?? LatLng(28.6139, 77.2090), // Default to Delhi
//                         zoom: 12,
//                       ),
//                       markers: _markers,
//                       mapType: MapType.normal,
//                       myLocationEnabled: true,
//                       myLocationButtonEnabled: true,
//                       zoomControlsEnabled: false,
//                       compassEnabled: true,
//                       mapToolbarEnabled: false,
//                     ),
//             ),
//           ),
//
//           // Details Section (Half Screen)
//           Expanded(
//             flex: 1,
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//               ),
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Route Information
//                     _buildSectionCard(
//                       'Route Information',
//                       Icons.route,
//                       [
//                         _buildDetailRow(
//                           Icons.my_location,
//                           'Pickup',
//                           ride!.fromLocation.address,
//                           Colors.green,
//                         ),
//                         SizedBox(height: 12),
//                         _buildDetailRow(
//                           Icons.location_on,
//                           'Dropoff',
//                           ride!.toLocation.address,
//                           Colors.red,
//                         ),
//                       ],
//                     ),
//
//                     SizedBox(height: 16),
//
//                     // Schedule Information
//                     _buildSectionCard(
//                       'Schedule',
//                       Icons.schedule,
//                       [
//                         _buildDetailRow(
//                           Icons.calendar_today,
//                           'Date',
//                           '${ride!.date.day}/${ride!.date.month}/${ride!.date.year}',
//                           Colors.blue[700]!,
//                         ),
//                         SizedBox(height: 12),
//                         _buildDetailRow(
//                           Icons.access_time,
//                           'Time',
//                           ride!.time,
//                           Colors.blue[700]!,
//                         ),
//                       ],
//                     ),
//
//                     SizedBox(height: 16),
//
//                     // Vehicle Information
//                     _buildSectionCard(
//                       'Vehicle Details',
//                       Icons.directions_car,
//                       [
//                         _buildDetailRow(
//                           Icons.car_repair,
//                           'Vehicle',
//                           '${ride!.vehicle.name} (${ride!.vehicle.color})',
//                           Colors.purple,
//                         ),
//                         SizedBox(height: 12),
//                         _buildDetailRow(
//                           Icons.confirmation_number,
//                           'Number Plate',
//                           ride!.vehicle.numberPlate,
//                           Colors.purple,
//                         ),
//                       ],
//                     ),
//
//                     SizedBox(height: 16),
//
//                     // Ride Information
//                     _buildSectionCard(
//                       'Ride Information',
//                       Icons.info,
//                       [
//                         _buildDetailRow(
//                           Icons.currency_rupee,
//                           'Price per Seat',
//                           '₹${ride!.pricePerPassenger.toInt()}',
//                           Colors.green[700]!,
//                         ),
//                         SizedBox(height: 12),
//                         _buildDetailRow(
//                           Icons.event_seat,
//                           'Available Seats',
//                           '${ride!.passengersBooked.length} of ${ride!.maxPassengers} booked',
//                           Colors.orange[700]!,
//                         ),
//                         SizedBox(height: 12),
//                         _buildDetailRow(
//                           Icons.phone,
//                           'Driver Phone',
//                           ride!.driverPhone,
//                           Colors.blue[700]!,
//                         ),
//                       ],
//                     ),
//
//                     SizedBox(height: 16),
//
//                     // Status Badge
//                     Center(
//                       child: Container(
//                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                         decoration: BoxDecoration(
//                           color: ride!.status == 'active' ? Colors.green : Colors.orange,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           'Status: ${ride!.status.toUpperCase()}',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: Colors.blue[700], size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
//     return Row(
//       children: [
//         Icon(icon, color: iconColor, size: 18),
//         SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.black87,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
