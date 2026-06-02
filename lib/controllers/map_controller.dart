import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../ride.dart';
import '../services/rides_api_service.dart';
import '../services/navigation_api_service.dart';
import '../data/models/navigation_response.dart';
import 'location_controller.dart';

class MapController extends GetxController {
  final RidesApiService _ridesApiService = RidesApiService();
  final NavigationApiService _navigationApiService = NavigationApiService();
  final LocationController _locationController = Get.find<LocationController>();

  // Map related observables
  Completer<GoogleMapController> mapController = Completer();
  var markers = <Marker>{}.obs;
  var isMapLoading = true.obs;
  var availableRides = <Ride>[].obs;
  var navigationRoutes = <NavigationResponse>[].obs;
  var selectedRide = Rxn<Ride>();

  // Navigation stats
  var isLoadingStats = false.obs;
  var totalRides = 0.obs;
  var completedRides = 0.obs;
  var cancelledRides = 0.obs;

  // Camera position
  var currentCameraPosition = const CameraPosition(
    target: LatLng(28.6139, 77.2090), // Default to Delhi
    zoom: 14.0,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _initializeMap();
    _loadNavigationStats();
  }

  void _initializeMap() async {
    await _getCurrentLocation();
    await loadPassengerPickupLocations();
    await loadNavigationPickupLocations();
  }

  Future<void> _getCurrentLocation() async {
    try {
      await _locationController.getCurrentLocation();

      if (_locationController.currentLatitude.value != 0.0 &&
          _locationController.currentLongitude.value != 0.0) {
        currentCameraPosition.value = CameraPosition(
          target: LatLng(
            _locationController.currentLatitude.value,
            _locationController.currentLongitude.value,
          ),
          zoom: 14.0,
        );

        // Add driver location marker
        _addDriverMarker();
      }
    } catch (e) {
      log('Error getting current location: $e');
    }
  }

  void _addDriverMarker() {
    final driverMarker = Marker(
      markerId: const MarkerId('driver_location'),
      position: LatLng(
        _locationController.currentLatitude.value,
        _locationController.currentLongitude.value,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(
        title: 'Your Location',
        snippet: 'Current driver position',
      ),
    );

    markers.add(driverMarker);
  }

  Future<void> loadPassengerPickupLocations() async {
    try {
      isMapLoading.value = true;
      log('🗺️ Loading passenger pickup locations from rides API...');

      final response = await _ridesApiService.getAvailableRides();

      if (response['success'] == true) {
        final ridesList = response['rides'] as List<Ride>;
        availableRides.value = ridesList;

        // Clear existing pickup markers (keep driver marker)
        markers.removeWhere((marker) => marker.markerId.value.startsWith('pickup_'));

        // Add green markers for passenger pickup locations
        for (var ride in ridesList) {
          if (ride.pickupLatitude != null && ride.pickupLongitude != null) {
            await _addPassengerPickupMarker(ride);
          }
        }

        log('🗺️ Added ${ridesList.length} passenger pickup markers from rides API');
      } else {
        log('❌ Failed to load passenger pickup locations: ${response['message']}');
      }
    } catch (e) {
      log('❌ Error loading passenger pickup locations: $e');
    }
  }

  /// Load pickup locations from navigation API with coordinate data
  Future<void> loadNavigationPickupLocations() async {
    try {
      log('🧭 Loading pickup locations from navigation API...');

      // Get current driver location as reference point
      final driverLat = _locationController.currentLatitude.value;
      final driverLng = _locationController.currentLongitude.value;

      if (driverLat == 0.0 || driverLng == 0.0) {
        log('❌ Driver location not available for navigation API');
        return;
      }

      // For each available ride, get navigation data to fetch precise coordinates
      final List<NavigationResponse> routes = [];

      for (var ride in availableRides) {
        try {
          // Get navigation data from driver location to pickup location
          final navResponse = await _navigationApiService.getNavigationData(
            origin: '$driverLat,$driverLng',
            destination: ride.pickupLocation,
          );

          if (navResponse['success'] == true && navResponse['data'] != null) {
            final navigationData = NavigationResponse.fromJson(navResponse['data']);
            routes.add(navigationData);

            // Add marker using navigation API coordinates if available
            if (navigationData.destinationLatitude != null &&
                navigationData.destinationLongitude != null) {
              await _addNavigationPickupMarker(ride, navigationData);
            }

            log('🧭 Added navigation pickup marker for ride ${ride.id}');
          }
        } catch (e) {
          log('❌ Error getting navigation data for ride ${ride.id}: $e');
          // Continue with other rides if one fails
        }
      }

      navigationRoutes.value = routes;
      log('🧭 Loaded ${routes.length} navigation routes');
    } catch (e) {
      log('❌ Error loading navigation pickup locations: $e');
    } finally {
      isMapLoading.value = false;
    }
  }

  Future<void> _addPassengerPickupMarker(Ride ride) async {
    try {
      // Choose marker color based on whether ride has multiple stops
      final markerColor = ride.isMultiStop
          ? BitmapDescriptor.hueOrange  // Orange for multi-stop rides
          : BitmapDescriptor.hueGreen;  // Green for regular rides

      final marker = Marker(
        markerId: MarkerId('pickup_${ride.id}'),
        position: LatLng(ride.pickupLatitude!, ride.pickupLongitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: ride.isMultiStop ? 'Multi-Stop Pickup' : 'Pickup Location',
          snippet: '${ride.pickupLocation}\n₹${ride.estimatedFare.toStringAsFixed(0)} • ${ride.rideType}${ride.isMultiStop ? ' • ${ride.stops!.length} stops' : ''}',
        ),
        onTap: () => _onPickupMarkerTapped(ride),
      );

      markers.add(marker);
    } catch (e) {
      log('Error adding pickup marker for ride ${ride.id}: $e');
    }
  }

  Future<void> _addNavigationPickupMarker(Ride ride, NavigationResponse navigation) async {
    try {
      // Choose marker color based on whether ride has multiple stops
      final markerColor = ride.isMultiStop
          ? BitmapDescriptor.hueOrange  // Orange for multi-stop rides
          : BitmapDescriptor.hueGreen;  // Green for regular rides

      final marker = Marker(
        markerId: MarkerId('nav_pickup_${ride.id}'),
        position: LatLng(
          navigation.destinationLatitude!,
          navigation.destinationLongitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: ride.isMultiStop ? 'Multi-Stop Pickup (Navigation)' : 'Pickup Location (Navigation)',
          snippet: '${ride.pickupLocation}\n₹${ride.estimatedFare.toStringAsFixed(0)} • ${ride.rideType}${ride.isMultiStop ? ' • ${ride.stops!.length} stops' : ''}\nDistance: ${navigation.distance} • ETA: ${navigation.duration}',
        ),
        onTap: () => _onNavigationPickupMarkerTapped(ride, navigation),
      );

      markers.add(marker);
    } catch (e) {
      log('Error adding navigation pickup marker for ride ${ride.id}: $e');
    }
  }

  void _onPickupMarkerTapped(Ride ride) {
    selectedRide.value = ride;
    _showRideDetailsBottomSheet(ride);
  }

  void _onNavigationPickupMarkerTapped(Ride ride, NavigationResponse navigation) {
    selectedRide.value = ride;
    _showNavigationRideDetailsBottomSheet(ride, navigation);
  }

  void _showRideDetailsBottomSheet(Ride ride) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ride details
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Ride Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRideDetailRow('Pickup', ride.pickupLocation, Icons.my_location),
            const SizedBox(height: 8),
            _buildRideDetailRow('Dropoff', ride.dropoffLocation, Icons.location_on),
            const SizedBox(height: 8),
            _buildRideDetailRow('Fare', '₹${ride.estimatedFare.toStringAsFixed(0)}', Icons.payment),
            const SizedBox(height: 8),
            _buildRideDetailRow('Vehicle', ride.rideType.toUpperCase(), Icons.directions_car),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRide(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept Ride'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showNavigationRideDetailsBottomSheet(Ride ride, NavigationResponse navigation) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ride details with navigation info
            Row(
              children: [
                Icon(Icons.navigation, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Navigation Pickup Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRideDetailRow('Pickup', ride.pickupLocation, Icons.my_location),
            const SizedBox(height: 8),
            _buildRideDetailRow('Dropoff', ride.dropoffLocation, Icons.location_on),
            const SizedBox(height: 8),
            _buildRideDetailRow('Fare', '₹${ride.estimatedFare.toStringAsFixed(0)}', Icons.payment),
            const SizedBox(height: 8),
            _buildRideDetailRow('Vehicle', ride.rideType.toUpperCase(), Icons.directions_car),

            // Navigation details
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.navigation, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Navigation Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRideDetailRow('Distance', navigation.distance, Icons.straighten),
                  const SizedBox(height: 4),
                  _buildRideDetailRow('ETA', navigation.duration, Icons.access_time),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRide(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept Ride'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildRideDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptRide(Ride ride) async {
    try {
      Get.back(); // Close bottom sheet

      // Show loading dialog
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Accepting ride...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final response = await _ridesApiService.acceptRide(ride.id);

      Get.back(); // Close loading dialog

      if (response['success'] == true) {
        Get.snackbar(
          'Success',
          'Ride accepted successfully!',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );

        // Remove the accepted ride marker
        markers.removeWhere((marker) => marker.markerId.value == 'pickup_${ride.id}');

        // Refresh the pickup locations
        await loadPassengerPickupLocations();
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to accept ride',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Network error while accepting ride',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
    isMapLoading.value = false;
  }

  Future<void> animateToLocation(double latitude, double longitude) async {
    final controller = await mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(latitude, longitude)),
    );
  }

  Future<void> animateToRide(Ride ride) async {
    if (ride.pickupLatitude != null && ride.pickupLongitude != null) {
      await animateToLocation(ride.pickupLatitude!, ride.pickupLongitude!);
      selectedRide.value = ride;
    }
  }

  Future<void> _loadNavigationStats() async {
    try {
      isLoadingStats.value = true;

      // Calculate stats from available rides
      totalRides.value = availableRides.length;
      completedRides.value = availableRides.where((ride) => ride.status == 'completed').length;
      cancelledRides.value = availableRides.where((ride) => ride.status == 'cancelled').length;

    } catch (e) {
      log('Error loading navigation stats: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> refreshMap() async {
    await loadPassengerPickupLocations();
    await loadNavigationPickupLocations();
    await _getCurrentLocation();
    await _loadNavigationStats();
  }

}
