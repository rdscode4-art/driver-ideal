import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ongoing_ride_controller.dart';

class NavigationInfoCard extends StatelessWidget {
  final OngoingRideController controller;

  const NavigationInfoCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with route status
            Row(
              children: [
                Icon(
                  controller.isLoadingNavigation.value
                      ? Icons.refresh
                      : controller.hasNavigationError.value
                      ? Icons.warning
                      : Icons.navigation,
                  color: controller.isLoadingNavigation.value
                      ? Colors.blue
                      : controller.hasNavigationError.value
                      ? Colors.orange
                      : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRouteStatusText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: controller.hasNavigationError.value
                          ? Colors.orange[700]
                          : Colors.grey[700],
                    ),
                  ),
                ),
                if (controller.isLoadingNavigation.value)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Navigation data display
            if (controller.hasNavigationData.value &&
                controller.navigationDistance.value.isNotEmpty &&
                controller.navigationDuration.value.isNotEmpty)
              _buildNavigationData()
            else if (controller.hasNavigationError.value)
              _buildErrorState()
            else if (controller.isLoadingNavigation.value)
              _buildLoadingState()
            else
              _buildDefaultState(),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoadingNavigation.value
                        ? null
                        : () => controller.navigateWithAPI(),
                    icon: Icon(
                      controller.isLoadingNavigation.value
                          ? Icons.hourglass_empty
                          : Icons.directions,
                      size: 18,
                    ),
                    label: Text(
                      controller.navigationButtonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: controller.isLoadingNavigation.value
                      ? null
                      : () => controller.refreshNavigationData(),
                  icon: Icon(
                    Icons.refresh,
                    color: controller.isLoadingNavigation.value
                        ? Colors.grey
                        : Colors.blue[600],
                  ),
                  tooltip: 'Refresh route',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRouteStatusText() {
    if (controller.isLoadingNavigation.value) {
      return 'Calculating route...';
    }

    if (controller.hasNavigationError.value) {
      return 'Route calculation failed';
    }

    if (controller.hasNavigationData.value) {
      final lastUpdate = controller.lastNavigationUpdate.value;
      final now = DateTime.now();
      final diff = now.difference(lastUpdate);

      if (diff.inMinutes < 1) {
        return 'Route updated just now';
      } else if (diff.inMinutes < 5) {
        return 'Route updated ${diff.inMinutes}m ago';
      } else {
        return 'Route needs refresh';
      }
    }

    return 'Tap to calculate route';
  }

  Widget _buildNavigationData() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          // Distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  controller.navigationDistance.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: Colors.green[200],
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  controller.navigationDuration.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Unavailable',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.navigationError.value.isNotEmpty
                      ? controller.navigationError.value
                      : 'Unable to calculate route',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Calculating best route...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap "Navigate" to get route information',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
