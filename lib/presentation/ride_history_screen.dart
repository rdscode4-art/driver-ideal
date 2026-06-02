import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ride_history_controller.dart';
import '../data/models/ride_history_models.dart';

class RideHistoryScreen extends StatelessWidget {
  final RideHistoryController controller = Get.find<RideHistoryController>();

  RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => controller.refreshRideHistory(),
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with gradient and API-based stats
            SliverAppBar(
              expandedHeight: 280,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              automaticallyImplyLeading: true,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                Obx(
                  () => IconButton(
                    icon: controller.isLoading.value
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
                        : const Icon(Icons.refresh, color: Colors.white),
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.refreshRideHistory(),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[600]!, Colors.orange[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ride History',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Obx(
                                      () => Text(
                                        controller.hasError.value
                                            ? 'Tap refresh to reload'
                                            : '${controller.totalRides.value} total rides completed',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // API-based stats row
                          _buildApiStatsRow(controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Body content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.045),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter section
                    _buildFilterSection(controller),
                    const SizedBox(height: 20),

                    // Error state
                    Obx(
                      () => controller.hasError.value
                          ? _buildErrorState(controller)
                          : const SizedBox.shrink(),
                    ),

                    // Trip counts overview
                    Obx(
                      () => controller.rideCounts.isNotEmpty
                          ? _buildTripCountsOverview(controller)
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),

                    // Trips list
                    Obx(
                      () => controller.isLoading.value
                          ? _buildLoadingState()
                          : controller.filteredTrips.isEmpty
                          ? _buildEmptyState(controller)
                          : _buildTripsList(controller),
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

  // API-based stats row in header
  Widget _buildApiStatsRow(RideHistoryController controller) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Rides',
              controller.totalRides.value.toString(),
              Icons.local_taxi,
              Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Completed',
              controller.getRideCountByStatus('completed').toString(),
              Icons.check_circle,
              Colors.green[100]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Earnings',
              controller.formatCurrency(controller.totalEarnings.value),
              Icons.currency_rupee,
              Colors.yellow[100]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.orange[700]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.orange[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Filter section
  Widget _buildFilterSection(RideHistoryController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Trips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            children: controller.filterOptions.map((filter) {
              final isSelected = controller.selectedFilter.value == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) controller.applyFilter(filter);
                },
                selectedColor: Colors.orange[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange[800] : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Trip counts overview from API
  Widget _buildTripCountsOverview(RideHistoryController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusCount(
                  'Pending',
                  controller.getRideCountByStatus('pending'),
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCount(
                  'Accepted',
                  controller.getRideCountByStatus('accepted'),
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatusCount(
                  'completed',
                  controller.getRideCountByStatus('completed'),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCount(
                  'Cancelled',
                  controller.getRideCountByStatus('cancelled'),
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String status, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Error state
  Widget _buildErrorState(RideHistoryController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[600]),
          const SizedBox(height: 12),
          Text(
            'Failed to Load Trip History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage.value,
            style: TextStyle(color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.refreshRideHistory(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.orange[600]),
            const SizedBox(height: 16),
            Text(
              'Loading trip history...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState(RideHistoryController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.selectedFilter.value == 'All'
                  ? 'No trips found'
                  : 'No ${controller.selectedFilter.value.toLowerCase()} trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.selectedFilter.value == 'All'
                  ? 'Your completed rides will appear here'
                  : 'Try selecting a different filter',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Trips list
  Widget _buildTripsList(RideHistoryController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = controller.filteredTrips[index];
        return _buildTripCard(trip, controller);
      },
    );
  }

  // Individual trip card with API data
  Widget _buildTripCard(
    RideHistoryItem trip,
    RideHistoryController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and fare
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: controller
                        .getStatusColor(trip.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.getStatusIcon(trip.status),
                        size: 12,
                        color: controller.getStatusColor(trip.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trip.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: controller.getStatusColor(trip.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  trip.formattedFare,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: trip.status == 'completed'
                        ? Colors.green[700]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route information
            Row(
              children: [
                Icon(Icons.local_taxi, size: 20, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.radio_button_checked,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              trip.pickup.address,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              trip.drop.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trip details
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildTripDetailChip(Icons.person, trip.rider.name),
                _buildTripDetailChip(Icons.phone, trip.rider.phone),
                _buildTripDetailChip(
                  Icons.access_time,
                  '${trip.formattedDate} • ${trip.formattedTime}',
                ),
                if (trip.stops.isNotEmpty)
                  _buildTripDetailChip(
                    Icons.stop,
                    '${trip.stops.length} stops',
                  ),
                if (trip.rating != null)
                  _buildTripDetailChip(Icons.star, '${trip.rating}/5'),
              ],
            ),

            // Show payment method if available
            if (trip.paymentMethod != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 6),
                    Text(
                      trip.paymentMethod!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
