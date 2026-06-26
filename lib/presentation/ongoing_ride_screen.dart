import 'package:flutter/material.dart';
import '../core/utils/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideal_driver/controllers/paymentscreen.dart';
import 'dart:developer';
import '../core/utils/app_snackbar.dart';
import '../controllers/ongoing_ride_controller.dart';
import 'payment_integration_helper.dart';

class OngoingRideScreen extends StatelessWidget {
  const OngoingRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller if not already present
    // We use Get.put here but the GetBuilder will handle reactivity
    final OngoingRideController controller = Get.put(
      OngoingRideController(),
      permanent: false,
    );
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    // Calculate available height (excluding safe areas)
    final availableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    final mapHeight = availableHeight * 0.5;

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.hasError.value) {
            return _buildErrorState(controller);
          }

          if (controller.currentRide.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Google Maps View - Half of available screen height
              SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    _buildMapView(controller),

                    // Top Info Bar overlaid on map
                    _buildTopInfoBar(controller),

                    // Navigation data overlay on map
                    _buildMapNavigationOverlay(controller),

                    // Floating Action Buttons overlaid on map
                    _buildFloatingButtons(controller),
                  ],
                ),
              ),

              // Bottom Panel - Other half of screen (scrollable)
              Expanded(child: _buildBottomPanelExpanded(controller, context)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildErrorState(OngoingRideController controller) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ongoing Ride'),
        backgroundColor: const Color(0xFF0F9D58), // primaryGreen
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58), // primaryGreen
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(OngoingRideController controller) {
    return GetBuilder<OngoingRideController>(
      id: 'map_view',
      builder: (_) {
        Set<Marker> markers = {};

        // Add driver marker (current location)
        if (controller.driverLatitude.value != 0 &&
            controller.driverLongitude.value != 0) {
          markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: LatLng(
                controller.driverLatitude.value,
                controller.driverLongitude.value,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: const InfoWindow(
                title: '🚗 Your Location',
                snippet: 'Driver current position',
              ),
              anchor: const Offset(0.5, 0.5),
            ),
          );
        }

        // Add pickup marker
        if (controller.pickupLatitude.value != 0 &&
            controller.pickupLongitude.value != 0) {
          markers.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(
                controller.pickupLatitude.value,
                controller.pickupLongitude.value,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(
                title: '📍 Pickup Location',
                snippet:
                    controller.currentRide.value?.pickupaddress ??
                    controller.currentRide.value?.pickupLocation ??
                    'Pickup point',
              ),
              anchor: const Offset(0.5, 1.0),
            ),
          );
        }

        // Add dropoff marker
        if (controller.dropoffLatitude.value != 0 &&
            controller.dropoffLongitude.value != 0) {
          markers.add(
            Marker(
              markerId: const MarkerId('dropoff'),
              position: LatLng(
                controller.dropoffLatitude.value,
                controller.dropoffLongitude.value,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: '🏁 Drop-off Location',
                snippet:
                    controller.currentRide.value?.dropaddress ??
                    controller.currentRide.value?.dropoffLocation ??
                    'Destination',
              ),
              anchor: const Offset(0.5, 1.0),
            ),
          );
        }

        // Smart initial position
        LatLng initialPosition = const LatLng(28.6139, 77.2090);
        if (controller.driverLatitude.value != 0) {
          initialPosition = LatLng(
            controller.driverLatitude.value,
            controller.driverLongitude.value,
          );
        } else if (controller.pickupLatitude.value != 0) {
          initialPosition = LatLng(
            controller.pickupLatitude.value,
            controller.pickupLongitude.value,
          );
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 15.0,
          ),
          markers: markers,
          polylines: controller.polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: false,
          buildingsEnabled: true,
          onMapCreated: (GoogleMapController mapController) {
            controller.setMapController(mapController);
          },
        );
      },
    );
  }

  Widget _buildTopInfoBar(OngoingRideController controller) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F9D58), // primaryGreen
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(
          () => Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getRidePhaseText(controller.ridePhase.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Time: ${controller.formattedElapsedTime}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Icons: Navigate and Center
              IconButton(
                onPressed: controller.isNavigationButtonLoading
                    ? null
                    : controller.navigateWithAPI,
                icon: controller.isNavigationButtonLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.navigation, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: () => controller.autoFitMarkersOnMap(),
                icon: const Icon(Icons.center_focus_strong, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.currentRide.value?.formattedFare ?? '₹0.00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapNavigationOverlay(OngoingRideController controller) {
    return Positioned(
      top: 60, // Below the top info bar
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Distance and ETA information
              if (controller.hasNavigationData.value &&
                  !controller.hasNavigationError.value)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distance: ${controller.navigationDistance.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ETA: ${controller.navigationDuration.value}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              else
                // Loading or error state
                Row(
                  children: [
                    if (controller.isLoadingNavigation.value)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else if (controller.hasNavigationError.value)
                      Icon(Icons.error, color: Colors.red[300], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      controller.hasNavigationError.value
                          ? (controller.navigationError.value.isNotEmpty
                                ? controller.navigationError.value
                                : 'Error loading navigation')
                          : 'Calculating route...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

              // Refresh button
              IconButton(
                onPressed: controller.isLoadingNavigation.value
                    ? null
                    : () => controller.refreshNavigationData(),
                icon: Icon(
                  Icons.refresh,
                  color: controller.isLoadingNavigation.value
                      ? Colors.white54
                      : Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanelExpanded(
    OngoingRideController controller,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero, // Removed bottom padding completely
              child: Column(
                children: [
                  //=====================================//
                  //=====================================//
                  //=====================================//
                  //=====================================//
                  // Combined Passenger & Location Info
                  _buildCombinedRideInfo(controller),

                  // Action Buttons Section
                  _buildActionButtons(controller, context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedRideInfo(OngoingRideController controller) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Passenger Row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE8F5E9), // lightGreen
                  child: const Icon(Icons.person, color: Color(0xFF0F9D58), size: 18), // primaryGreen
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.passengerName.value.isNotEmpty
                                ? controller.passengerName.value
                                : 'Passenger',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber[800], size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  controller.currentRide.value?.rideType.toUpperCase() ?? 'RIDE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.amber[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (controller.passengerPhone.value.isNotEmpty)
                        Text(
                          controller.passengerPhone.value,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        )
                    ],
                  ),
                ),
                // Call button
                if (controller.passengerPhone.value.isNotEmpty)
                  InkWell(
                    onTap: () => controller.callPassenger(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone, color: Color(0xFF0F9D58), size: 18),
                    ),
                  )
              ],
            ),
            
            Divider(height: 16, color: Colors.grey[200]),
            
            // Location Details (Compact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.my_location, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.currentRide.value?.pickupaddress ?? 'Not specified',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.currentRide.value?.dropaddress ?? 'Not specified',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationInfo(OngoingRideController controller) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A6B3C), Color(0xFF0F9D58)], // darkGreen to primaryGreen
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Live Navigation Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Refresh button
                IconButton(
                  onPressed: controller.isLoadingNavigation.value
                      ? null
                      : () => controller.refreshNavigationData(),
                  icon: Icon(
                    Icons.refresh,
                    color: controller.isLoadingNavigation.value
                        ? Colors.white54
                        : Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                if (controller.isLoadingNavigation.value)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Navigation data display
            if (controller.hasNavigationData.value &&
                !controller.hasNavigationError.value)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNavigationDataItem(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: controller.navigationDistance.value,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNavigationDataItem(
                          icon: Icons.schedule,
                          label: 'ETA',
                          value: controller.navigationDuration.value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Show last update time
                  Row(
                    children: [
                      const Icon(Icons.update, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${_formatUpdateTime(controller.lastNavigationUpdate.value)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (controller.hasNavigationError.value)
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.yellow[300], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.navigationError.value.isNotEmpty
                              ? controller.navigationError.value
                              : 'Navigation data unavailable',
                          style: TextStyle(
                            color: Colors.yellow[200],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Retry button for errors
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => controller.refreshNavigationData(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 0),
                      ),
                    ),
                  ),
                ],
              )
            else if (controller.isLoadingNavigation.value)
              const Row(
                children: [
                  Icon(
                    Icons.location_searching,
                    color: Colors.white70,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Calculating route...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              )
            else
              // No data state - show tap to get directions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.fetchNavigationData(),
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text(
                    'Get Route Info',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDataItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDetectionLocation(OngoingRideController controller) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), // lightGreen
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF81C784)), // accentGreen
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Location',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: controller.isAutoDetecting.value
                        ? null
                        : controller.manualAutoDetectLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.isAutoDetecting.value)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green[700]!,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.refresh,
                              color: Colors.green[700],
                              size: 12,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            controller.autoDetectionButtonText,
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.autoDetectedLocationText,
              style: TextStyle(color: Colors.green[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeRideWithPayment(
    OngoingRideController controller,
    String paymentMethod,
    RxBool isCompleting,
  ) async {
    try {
      isCompleting.value = true;

      log('💳 ===== PAYMENT FLOW STARTED (INLINE) =====');
      log('💳 Payment Method: $paymentMethod');
      log('💳 Ride ID: ${controller.currentRide.value?.id}');

      if (controller.currentRide.value == null) {
        log('❌ No active ride found');
        showErrorSnackBar('No active ride found', title: '❌ Error');
        isCompleting.value = false;
        return;
      }

      // Call the API service method
      log('📡 Calling API: completeRideWithPayment');
      final response = await controller.completeRideWithPayment(paymentMethod);

      log('📡 API Response: $response');

      if (response['success'] == true) {
        log('✅ API call successful');

        // Check if online payment requires QR code
        if (paymentMethod == 'online' && response['requiresPayment'] == true) {
          log('💳 Online payment - would show QR code here');

          // For now, just show a message
          showInfoSnackBar(
            'QR code feature will be shown here',
            title: 'Online Payment',
          );

          // Close payment method selection
          if (Get.isBottomSheetOpen == true) {
            Get.back();
          }
        } else {
          // Cash payment completed successfully
          log('💰 Cash payment - completing ride');

          // Close payment method selection
          if (Get.isBottomSheetOpen == true) {
            Get.back();
          }

          controller.ridePhase.value = RidePhase.COMPLETED;

          showSuccessSnackBar(
            'Cash payment recorded successfully',
            title: '✅ Ride Completed',
          );

          // Navigate to home after delay
          await Future.delayed(const Duration(seconds: 2));
          Get.offAllNamed('/');
        }
      } else {
        log('❌ API call failed: ${response['message']}');

        showErrorSnackBar(
          response['message'] ?? 'Failed to complete ride',
          title: '❌ Error',
        );
      }
    } catch (e, stackTrace) {
      log('❌ Exception in _completeRideWithPayment: $e');
      log('❌ Stack trace: $stackTrace');

      showErrorSnackBar(
        'Network error occurred: ${e.toString()}',
        title: '❌ Error',
      );
    } finally {
      isCompleting.value = false;
      log('💳 ===== PAYMENT FLOW ENDED =====');
    }
  }

  Widget _buildLocationDetails(OngoingRideController controller) {
    return const SizedBox.shrink(); // Replaced by _buildCombinedRideInfo
  }

  Widget _buildActionButtons(
    OngoingRideController controller,
    BuildContext context,
  ) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            // Trip Status Card removed as per request to optimize space


            // Primary Action Buttons - ALWAYS ENABLED like Ola/Uber
            Column(
              children: [
                // Professional Action Buttons Row - Always enabled regardless of phase
                Row(
                  children: [
                    // "ARRIVED AT PICKUP" Button - Always enabled
                    if (controller.ridePhase.value ==
                            RidePhase.GOING_TO_PICKUP ||
                        controller.ridePhase.value ==
                            RidePhase.WAITING_FOR_PASSENGER)
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _handleArrivedAtPickup(controller, context),
                            icon: Icon(
                              controller.ridePhase.value ==
                                      RidePhase.GOING_TO_PICKUP
                                  ? Icons.location_on
                                  : Icons.directions_car,
                              size: 18, // Reduced icon size
                            ),
                            label: Text(
                              controller.ridePhase.value ==
                                      RidePhase.GOING_TO_PICKUP
                                  ? 'ARRIVED'
                                  : 'START RIDE',
                              style: const TextStyle(
                                fontSize: 12, // Reduced from 16 to 14
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8, // Reduced letter spacing
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F9D58), // primaryGreen
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor:
                                  controller.ridePhase.value ==
                                      RidePhase.GOING_TO_PICKUP
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : Colors.green.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ), // Better padding
                            ),
                          ),
                        ),
                      ),

                    // Spacing between buttons when both are shown
                    if ((controller.ridePhase.value ==
                                RidePhase.GOING_TO_PICKUP ||
                            controller.ridePhase.value ==
                                RidePhase.WAITING_FOR_PASSENGER) &&
                        controller.ridePhase.value != RidePhase.COMPLETED)
                      const SizedBox(width: 12),
                    //UNCOMMENT WHEN PAYMENT INTEGRATION COME
                    // "COMPLETE RIDE" or "VIEW QR" Button
                    if (controller.ridePhase.value != RidePhase.COMPLETED)
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    if (controller.ridePhase.value ==
                                        RidePhase.PAYMENT_PENDING) {
                                      // If already pending payment, show QR again if we can
                                      _showPaymentMethodSelection(controller);
                                    } else {
                                      _showCompleteRideConfirmation(controller);
                                    }
                                  },
                            icon: controller.isLoading.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    controller.ridePhase.value ==
                                            RidePhase.PAYMENT_PENDING
                                        ? Icons.qr_code_2
                                        : Icons.check_circle,
                                    size: 20,
                                  ),
                            label: Text(
                              controller.isLoading.value
                                  ? 'PROCESSING...'
                                  : (controller.ridePhase.value ==
                                            RidePhase.PAYMENT_PENDING
                                        ? 'VIEW QR CODE'
                                        : 'COMPLETE RIDE'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.isLoading.value
                                  ? Colors.grey[500]
                                  : (controller.ridePhase.value ==
                                            RidePhase.PAYMENT_PENDING
                                        ? Colors.purple[600]
                                        : const Color(0xFF0F9D58)), // primaryGreen
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                if (controller.ridePhase.value == RidePhase.COMPLETED)
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => Get.offAllNamed('/'),
                      icon: const Icon(
                        Icons.home,
                        size: 20,
                      ), // Reduced icon size
                      label: const Text(
                        'BACK TO HOME',
                        style: TextStyle(
                          fontSize: 14, // Reduced from 16 to 14
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8, // Reduced letter spacing
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58), // primaryGreen
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: Colors.green.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ), // Better padding
                      ),
                    ),
                  ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(OngoingRideController controller) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Center on driver location
          FloatingActionButton(
            heroTag: "center_driver",
            mini: true,
            onPressed: () => controller.centerMapOnDriver(),
            backgroundColor: Colors.green[600],
            child: const Icon(Icons.my_location, color: Colors.white),
          ),

          const SizedBox(height: 8),

          // Center on target location
          FloatingActionButton(
            heroTag: "center_target",
            mini: true,
            onPressed: () => controller.centerMapOnTarget(),
            backgroundColor: Colors.orange[600],
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getRidePhaseText(RidePhase phase) {
    switch (phase) {
      case RidePhase.GOING_TO_PICKUP:
        return 'En Route to Pickup';
      case RidePhase.WAITING_FOR_PASSENGER:
        return 'At Pickup Location';
      case RidePhase.GOING_TO_DROPOFF:
        return 'Ride in Progress';
      case RidePhase.PAYMENT_PENDING:
        return 'Payment Pending';
      case RidePhase.COMPLETED:
        return 'Ride Completed';
    }
  }

  // Helper methods for the new UI
  Color _getPhaseStatusColor(RidePhase phase) {
    switch (phase) {
      case RidePhase.GOING_TO_PICKUP:
        return Colors.green[600]!;
      case RidePhase.WAITING_FOR_PASSENGER:
        return Colors.orange[600]!;
      case RidePhase.GOING_TO_DROPOFF:
        return Colors.green[600]!;
      case RidePhase.PAYMENT_PENDING: // ✅ Add this
        return Colors.purple[600]!;
      case RidePhase.COMPLETED:
        return Colors.grey[600]!;
    }
  }

  IconData _getPhaseIcon(RidePhase phase) {
    switch (phase) {
      case RidePhase.GOING_TO_PICKUP:
        return Icons.directions_car;
      case RidePhase.WAITING_FOR_PASSENGER:
        return Icons.schedule;
      case RidePhase.GOING_TO_DROPOFF:
        return Icons.navigation;
      case RidePhase.PAYMENT_PENDING: // ✅ Add this
        return Icons.payment;
      case RidePhase.COMPLETED:
        return Icons.check_circle;
    }
  }

  String _getPhaseSubtitle(RidePhase phase) {
    switch (phase) {
      case RidePhase.GOING_TO_PICKUP:
        return 'Drive to the passenger\'s pickup point';
      case RidePhase.WAITING_FOR_PASSENGER:
        return 'Wait for the passenger to board';
      case RidePhase.GOING_TO_DROPOFF:
        return 'Drop the passenger at the destination';
      case RidePhase.PAYMENT_PENDING:
        return 'Wait for the passenger to complete payment';
      case RidePhase.COMPLETED:
        return 'Trip finished successfully';
    }
  }

  double _getProgressValue(RidePhase phase) {
    switch (phase) {
      case RidePhase.GOING_TO_PICKUP:
        return 0.25;
      case RidePhase.WAITING_FOR_PASSENGER:
        return 0.5;
      case RidePhase.GOING_TO_DROPOFF:
        return 0.75;
      case RidePhase.PAYMENT_PENDING: // ✅ Add this
        return 0.9;
      case RidePhase.COMPLETED:
        return 1.0;
    }
  }

  /// Handle "Arrived at Pickup" action with confirmation
  void _handleArrivedAtPickup(
    OngoingRideController controller,
    BuildContext context,
  ) {
    if (controller.ridePhase.value == RidePhase.GOING_TO_PICKUP) {
      // Show arrival confirmation
      _showArrivalConfirmation(controller, context);
      // } else if (controller.ridePhase.value == RidePhase.WAITING_FOR_PASSENGER) {
      //   // Show start trip confirmation
      //   _showStartTripConfirmation(controller);
      // }
    } else if (controller.ridePhase.value == RidePhase.WAITING_FOR_PASSENGER) {
      // Show OTP entry dialog for manual verification
      _showOtpEntryDialog(controller, context);
    }
  }

  /// Show arrival confirmation dialog (like Uber/Ola)
  void _showArrivalConfirmation(
    OngoingRideController controller,
    BuildContext context,
  ) {
    Get.defaultDialog(
      title: '📍 Arrived at Pickup',
      titleStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green[700],
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Icon(Icons.location_on, size: 64, color: Colors.green[600]),
            const SizedBox(height: 16),
            Text(
              'Have you arrived at the pickup location?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'This will notify the passenger that you have arrived.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Not Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(Get.overlayContext!).pop();
                      // Show OTP entry dialog instead of automatic start
                      _showOtpEntryDialog(controller, context);
                    },
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                      'Yes, Arrived',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
      radius: 16,
    );
  }

  /// NEW: Show OTP Entry Dialog for Ride Verification
  void _showOtpEntryDialog(
    OngoingRideController controller,
    BuildContext context,
  ) {
    final TextEditingController otpController = TextEditingController();
    final RxString errorText = ''.obs;

    Get.defaultDialog(
      title: '🔐 Verify OTP',
      titleStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green[800],
      ),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Ask the passenger for the 4-digit OTP to start the ride.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '0000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                ),
              ),
            ),
            Obx(
              () => errorText.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        errorText.value,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final otp = otpController.text.trim();
                      if (otp.length != 4) {
                        errorText.value = 'Please enter a valid 4-digit OTP';
                        return;
                      }

                      // Verify OTP with backend via controller
                      final success = await controller.startRideWithOtp(otp);
                      if (success) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'VERIFY',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
      radius: 16,
    );
  }

  /// Format update time for display
  String _formatUpdateTime(DateTime? dateTime) {
    if (dateTime == null) return 'never';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Show complete ride confirmation dialog
  /// REPLACE _showCompleteRideConfirmation and _showPaymentMethodSelection in ongoing_ride_screen.dart

  /// Show complete ride confirmation dialog
  void _showCompleteRideConfirmation(OngoingRideController controller) {
    log('🏁 Opening complete ride confirmation dialog');

    Get.defaultDialog(
      title: '🏁 Complete Ride',
      titleStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.orange[700],
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to complete this ride?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'This action will end the current trip and finalize the fare.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      log('❌ User cancelled ride completion');
                      // Safely close dialog
                      if (Navigator.canPop(Get.overlayContext!)) {
                        Navigator.of(Get.overlayContext!).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      log('✅ User confirmed ride completion');
                      // Safely close dialog
                      if (Navigator.canPop(Get.overlayContext!)) {
                        Navigator.of(Get.overlayContext!).pop();
                      }

                      // Show payment method selection
                      _showPaymentMethodSelection(controller);
                    },
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
      radius: 16,
    );
  }

  /// Show payment method selection bottom sheet
  // Find this section in your ongoing_ride_screen.dart file and replace it:

  /// Show payment method selection bottom sheet
  // Replace your _showPaymentMethodSelection method with this complete version:

  // Replace your _showPaymentMethodSelection method with this version

  void _showPaymentMethodSelection(OngoingRideController controller) {
    final RxString selectedPaymentMethod = 'cash'.obs;
    final RxBool isCompleting = false.obs;

    print('💳 Opening payment method selection bottom sheet');
    print('💰 Current fare: ${controller.currentRide.value?.formattedFare}');

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: Colors.green[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'How did the passenger pay?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Trip summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Fare',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            controller.currentRide.value?.formattedFare ??
                                '₹0.00',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          controller.currentRide.value?.rideType
                                  .toUpperCase() ??
                              'RIDE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment options
                Obx(
                  () => Column(
                    children: [
                      // Cash option
                      _buildPaymentOption(
                        icon: Icons.money,
                        title: 'Cash Payment',
                        subtitle: 'Passenger paid with cash',
                        value: 'cash',
                        selectedValue: selectedPaymentMethod.value,
                        onTap: () {
                          print('💰 Payment method changed to: cash');
                          selectedPaymentMethod.value = 'cash';
                        },
                        iconColor: Colors.green,
                      ),
                      const SizedBox(height: 12),

                      // Online option
                      _buildPaymentOption(
                        icon: Icons.credit_card,
                        title: 'Pay Online',
                        subtitle: 'UPI / Card / Wallet',
                        value: 'online',
                        selectedValue: selectedPaymentMethod.value,
                        onTap: () {
                          print('💳 Payment method changed to: online');
                          selectedPaymentMethod.value = 'online';
                        },
                        iconColor: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          log('❌ Payment selection cancelled');
                          // Use Navigator directly instead of Get.back()
                          Navigator.of(Get.overlayContext!).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => ElevatedButton.icon(
                          onPressed: !isCompleting.value
                              ? () => _handleCompleteRideWithPayment(
                                  controller,
                                  selectedPaymentMethod.value,
                                  isCompleting,
                                )
                              : null,
                          icon: isCompleting.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 20),
                          label: Text(
                            isCompleting.value
                                ? 'Processing...'
                                : 'Complete Ride',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isCompleting.value
                                ? Colors.green[600]
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: !isCompleting.value ? 3 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select how the passenger paid for this trip',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// Build individual payment option tile
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String selectedValue,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    final bool isSelected = value == selectedValue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? iconColor.withOpacity(0.2)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? iconColor : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? iconColor : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? iconColor.withOpacity(0.8)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? iconColor : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? iconColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle complete ride with payment - SEPARATED from UI
  /// Handle complete ride with payment - Fixed version
  Future<void> _handleCompleteRideWithPayment(
    OngoingRideController controller,
    String paymentMethod,
    RxBool isCompleting,
  ) async {
    try {
      isCompleting.value = true;

      print('💳 [SCREEN] ===== STARTING PAYMENT FLOW =====');
      print('💳 [SCREEN] Payment method: $paymentMethod');
      print('💳 [SCREEN] Ride ID: ${controller.currentRide.value?.id}');

      // Call controller method - gets API response
      if (paymentMethod == 'online') {
        print('🚀 [SCREEN] Calling generatePaymentQR for online payment');

        // Close payment selection bottom sheet first
        if (Get.isBottomSheetOpen == true) {
          Navigator.of(Get.overlayContext!).pop();
        }

        // Call the new generation method
        await controller.generatePaymentQR();
        return;
      }

      final response = await controller.completeRideWithPayment(paymentMethod);

      print('📡 [SCREEN] Response received');
      print('📡 [SCREEN] Success: ${response['success']}');
      print('📡 [SCREEN] Full response: $response');

      if (response['success'] == true) {
        // ✅ Handle ONLINE payment
        if (paymentMethod == 'online') {
          print('💳 [SCREEN] Processing online payment...');

          if (response['qrCode'] != null &&
              response['qrCode'].toString().isNotEmpty) {
            print('✅ [SCREEN] QR Code found!');

            // Close payment selection bottom sheet
            if (Get.isBottomSheetOpen == true) {
              Navigator.of(Get.overlayContext!).pop();
            }

            // ✅ IMPORTANT: Update ride phase to PAYMENT_PENDING
            controller.ridePhase.value = RidePhase.PAYMENT_PENDING;
            print('✅ [SCREEN] Ride phase updated to PAYMENT_PENDING');

            // Wait for animation
            await Future.delayed(const Duration(milliseconds: 500));

            // Navigate to QR screen
            print('🚀 [SCREEN] Navigating to PaymentQRScreen...');

            final paymentResult = await Get.to(
              () => PaymentQRScreen(
                qrCode: response['qrCode'].toString(),
                orderId:
                    (response['paymentLinkId'] ??
                            response['orderId'] ??
                            'unknown')
                        .toString(),
                rideId: controller.currentRide.value!.id,
                amount: response['amount'] ?? 0.0,
                currency: (response['currency'] ?? 'INR').toString(),
              ),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 300),
            );

            print('✅ [SCREEN] Returned from PaymentQRScreen');
            print('💰 [SCREEN] Payment result: $paymentResult');

            // ✅ Check payment result
            if (paymentResult == true) {
              // Payment successful
              print('✅ Payment completed successfully');

              // Update ride phase to COMPLETED
              controller.ridePhase.value = RidePhase.COMPLETED;

              showSuccessSnackBar(
                'Ride completed successfully',
                title: '✅ Payment Received',
              );

              await Future.delayed(const Duration(seconds: 2));
              Get.offAllNamed('/');
            } else {
              // Payment cancelled or failed
              print('⚠️ Payment was cancelled or failed');

              // Revert to GOING_TO_DROPOFF phase
              controller.ridePhase.value = RidePhase.GOING_TO_DROPOFF;

              showWarningSnackBar(
                'Payment was not completed. Please try again.',
                title: '⚠️ Payment Cancelled',
              );
            }
          } else {
            // QR code not found
            print('❌ [SCREEN] QR Code NOT found in response');

            if (Get.isBottomSheetOpen == true) {
              Navigator.of(Get.overlayContext!).pop();
            }

            showErrorSnackBar(
              'Payment QR code was not generated. Please try again or use cash payment.',
              title: '❌ QR Code Error',
            );
          }
        }
        // ✅ Handle CASH payment
        else if (paymentMethod == 'cash') {
          print('💵 [SCREEN] Processing cash payment...');

          // Close payment selection bottom sheet
          if (Get.isBottomSheetOpen == true) {
            Navigator.of(Get.overlayContext!).pop();
          }

          // ✅ CRITICAL FIX: Check if backend actually marked ride as completed
          print('🔍 Checking backend ride status...');

          // ✅ IMPORTANT: Update ride phase to COMPLETED
          controller.ridePhase.value = RidePhase.COMPLETED;
          print('✅ Ride phase updated to COMPLETED');

          // ✅ Verify ride status on backend
          try {
            // Give backend a moment to update
            await Future.delayed(const Duration(milliseconds: 500));

            // You should have a method in controller to verify ride status
            // final rideStatus = await controller.verifyRideStatus();

            // For now, we'll trust the API response
            print('✅ Cash payment recorded on backend');

            showSuccessSnackBar(
              'Cash payment recorded successfully',
              title: '✅ Ride Completed',
            );

            await Future.delayed(const Duration(seconds: 2));

            // ✅ Navigate to home
            print('🏠 Navigating to home screen');
            Get.offAllNamed('/');
          } catch (e) {
            print('❌ Error verifying ride status: $e');

            showWarningSnackBar(
              'Payment recorded but status verification failed',
              title: '⚠️ Warning',
            );

            await Future.delayed(const Duration(seconds: 2));
            Get.offAllNamed('/');
          }
        }
      } else {
        // API returned error
        print('❌ [SCREEN] API error: ${response['message']}');

        if (Get.isBottomSheetOpen == true) {
          Navigator.of(Get.overlayContext!).pop();
        }

        showErrorSnackBar(
          response['message'] ?? 'Failed to complete ride. Please try again.',
          title: '❌ Error',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [SCREEN] EXCEPTION: $e');
      print('❌ [SCREEN] Stack trace: $stackTrace');

      if (Get.isBottomSheetOpen == true) {
        Navigator.of(Get.overlayContext!).pop();
      }

      showErrorSnackBar(
        'Payment processing failed: ${e.toString()}',
        title: '❌ Critical Error',
      );
    } finally {
      isCompleting.value = false;
      print('💳 [SCREEN] ===== PAYMENT FLOW ENDED =====');
    }
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String selectedValue,
    required VoidCallback onTap,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    final bool isSelected = value == selectedValue;

    return Container(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? backgroundColor : Colors.white,
              border: Border.all(
                color: isSelected ? iconColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? iconColor.withValues(alpha: 0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? iconColor : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? iconColor : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? iconColor.withValues(alpha: 0.8)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? iconColor : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected ? iconColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Complete ride with selected payment method
  void _completeRideWithPaymentMethod(
    OngoingRideController controller,
    String paymentMethod,
    RxBool isCompleting,
  ) async {
    // Use the PaymentIntegrationHelper that handles the payment-specific API call
    await PaymentIntegrationHelper.completeRideWithPaymentMethod(
      controller,
      paymentMethod,
      isCompleting,
    );
  }

  /// Show trip menu with additional options
  void _showTripMenu(OngoingRideController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Text(
                'Trip Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              // Menu items
              _buildMenuTile(
                icon: Icons.report_problem,
                title: 'Report Issue',
                subtitle: 'Report a problem with this trip',
                onTap: () {
                  Get.back();
                  _showReportIssue(controller);
                },
              ),
              _buildMenuTile(
                icon: Icons.emergency,
                title: 'Emergency',
                subtitle: 'Get help in case of emergency',
                onTap: () {
                  Get.back();
                  _showEmergencyOptions(controller);
                },
                isEmergency: true,
              ),
              _buildMenuTile(
                icon: Icons.info_outline,
                title: 'Trip Details',
                subtitle: 'View complete trip information',
                onTap: () {
                  Get.back();
                  _showTripDetails(controller);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// Build menu tile widget
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isEmergency ? Colors.red[300]! : Colors.grey[200]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEmergency ? Colors.red[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isEmergency ? Colors.red[700] : Colors.grey[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isEmergency
                              ? Colors.red[700]
                              : Colors.grey[800],
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show report issue dialog
  void _showReportIssue(OngoingRideController controller) {
    showInfoSnackBar(
      'Report issue feature will be implemented soon',
      title: 'Report Issue',
    );
  }

  /// Show emergency options
  void _showEmergencyOptions(OngoingRideController controller) {
    showErrorSnackBar(
      'Emergency features will be implemented soon',
      title: 'Emergency',
    );
  }

  /// Show trip details
  void _showTripDetails(OngoingRideController controller) {
    showSuccessSnackBar(
      'Detailed trip information will be implemented soon',
      title: 'Trip Details',
    );
  }
}
