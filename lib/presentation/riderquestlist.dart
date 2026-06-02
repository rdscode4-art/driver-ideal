import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../ride.dart';
import '../core/sound_manager.dart';
import '../fcm_service.dart';

class RideRequestsListWidget extends StatelessWidget {
  const RideRequestsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController? controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;

    if (controller == null) {
      return const Center(
        child: Text('Loading rides...', style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: [
        // Auto-refresh status header
        _buildAutoRefreshHeader(controller),

        const SizedBox(height: 16),

        // Ride requests list
        Expanded(
          child: Obx(() {
            if (controller.nearbyRides.isEmpty) {
              return _buildEmptyState(controller);
            }

            return RefreshIndicator(
              onRefresh: () async {
                await controller.loadAvailableRidesCount();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.nearbyRides.length,
                itemBuilder: (context, index) {
                  final ride = controller.nearbyRides[index];
                  return _buildRideRequestCard(ride, controller, context);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  // Auto-refresh status header
  Widget _buildAutoRefreshHeader(HomeController controller) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: controller.isAutoRefreshEnabled.value
              ? Colors.green[50]
              : Colors.grey[100],
          border: Border(
            bottom: BorderSide(
              color: controller.isAutoRefreshEnabled.value
                  ? Colors.green[200]!
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Auto-refresh indicator
            Icon(
              controller.isAutoRefreshEnabled.value
                  ? Icons.autorenew
                  : Icons.sync_disabled,
              color: controller.isAutoRefreshEnabled.value
                  ? Colors.green[700]
                  : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),

            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isAutoRefreshEnabled.value
                        ? 'Auto-Refresh Active'
                        : 'Auto-Refresh Paused',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: controller.isAutoRefreshEnabled.value
                          ? Colors.green[900]
                          : Colors.grey[700],
                    ),
                  ),
                  if (controller.lastRidesRefresh.value != null)
                    Text(
                      'Last updated: ${_formatTimeSince(controller.lastRidesRefresh.value!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),

            // Ride count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: controller.availableRidesCount.value > 0
                    ? Colors.orange[600]
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${controller.availableRidesCount.value} Rides',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Toggle auto-refresh button
            IconButton(
              onPressed: () => controller.toggleAutoRefresh(),
              icon: Icon(
                controller.isAutoRefreshEnabled.value
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: controller.isAutoRefreshEnabled.value
                    ? Colors.green[700]
                    : Colors.grey[600],
              ),
              tooltip: controller.isAutoRefreshEnabled.value
                  ? 'Pause auto-refresh'
                  : 'Resume auto-refresh',
            ),

            // Manual refresh button
            IconButton(
              onPressed: () => controller.loadAvailableRidesCount(),
              icon: Icon(Icons.refresh, color: Colors.blue[700]),
              tooltip: 'Refresh now',
            ),
          ],
        ),
      );
    });
  }

  // Empty state when no rides available
  Widget _buildEmptyState(HomeController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_taxi, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Ride Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.isOnline
                ? 'Waiting for new ride requests...'
                : 'Go online to see available rides',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.isAutoRefreshEnabled.value)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[600]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-checking every 15 seconds',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Individual ride request card
  Widget _buildRideRequestCard(
    Ride ride,
    HomeController controller,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with passenger name and price
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.person, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.passengerName ?? 'Passenger',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${ride.id.substring(0, 8)}...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // child: Text(
                  //   '₹${ride.fare?.toStringAsFixed(0) ?? 'N/A'}',
                  //   style: const TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pickup location
            _buildLocationRow(
              icon: Icons.radio_button_checked,
              iconColor: Colors.green[600]!,
              label: 'Pickup',
              address: ride.pickupLocation,
            ),

            const SizedBox(height: 12),

            // Dropoff location
            _buildLocationRow(
              icon: Icons.location_on,
              iconColor: Colors.red[600]!,
              label: 'Drop-off',
              address: ride.dropoffLocation,
            ),

            const SizedBox(height: 16),

            // Ride details
            const Row(
              children: [
                // _buildDetailChip(
                //   icon: Icons.route,
                //   label: '${ride.?.toStringAsFixed(1) ?? 'N/A'} km',
                //   color: Colors.blue,
                // ),
                SizedBox(width: 8),
                // _buildDetailChip(
                //   icon: Icons.access_time,
                //   label: '${ride.duration ?? 'N/A'} min',
                //   color: Colors.purple,
                // ),
                SizedBox(width: 8),
                // _buildDetailChip(
                //   icon: Icons.payment,
                //   label: ride.paymentMethod ?? 'Cash',
                //   color: Colors.orange,
                // ),
              ],
            ),

            const SizedBox(height: 16),

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 🎵 Stop sounds immediately
                  SoundManager().stopRequestSound();
                  FCMService.stopRequestSound();
                  controller.quickAcceptRide(ride.id, context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Accept Ride',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Location row widget
  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Detail chip widget
  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Format time since last refresh
  String _formatTimeSince(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
