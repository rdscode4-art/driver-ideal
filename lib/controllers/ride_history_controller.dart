import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/ride_history_models.dart';
import '../services/ride_history_service.dart';

class RideHistoryController extends GetxController {
  final RideHistoryService _rideHistoryService = RideHistoryService();
  final rides = RxList<RideHistoryItem>([]);
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final totalRides = 0.obs;
  final totalEarnings = 0.obs;
  final selectedFilter = 'All'.obs;
  final filterOptions = ['All', 'completed', 'Cancelled', 'Pending'].obs;
  final rideCounts = RxMap<String, int>();
  final filteredTrips = RxList<RideHistoryItem>([]);

  @override
  void onInit() {
    super.onInit();
    refreshRideHistory();
  }

  Future<void> refreshRideHistory() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final rideHistoryResponse = await _rideHistoryService.getRideHistory();
      rides.assignAll(rideHistoryResponse.rides);

      // Update statistics
      totalRides.value = rideHistoryResponse.totalRides;
      totalEarnings.value = rides.fold(0.0, (sum, ride) => sum + (ride.fare ?? 0.0)).toInt();

      // Update ride counts from API response
      rideCounts.assignAll(rideHistoryResponse.rideCounts);

      // Apply current filter
      _applyCurrentFilter();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void _updateRideCounts() {
    rideCounts.clear();
    for (var status in ['pending', 'completed', 'cancelled']) {
      rideCounts[status] = rides.where((r) => r.status.toLowerCase() == status).length;
    }
  }

  void applyFilter(String filter) {
    selectedFilter.value = filter;
    _applyCurrentFilter();
  }

  void _applyCurrentFilter() {
    if (selectedFilter.value == 'All') {
      filteredTrips.assignAll(rides);
    } else {
      final status = selectedFilter.value.toLowerCase();
      filteredTrips.assignAll(
        rides.where((ride) => ride.status.toLowerCase() == status)
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.directions_car;
      default:
        return Icons.help;
    }
  }

  IconData getRideTypeIcon(String rideType) {
    switch (rideType.toLowerCase()) {
      case 'bike':
        return Icons.motorcycle;
      case 'car':
        return Icons.directions_car;
      case 'suv':
        return Icons.directions_car;
      default:
        return Icons.local_taxi;
    }
  }

  String formatCurrency(int amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  int getRideCountByStatus(String status) {
    return rideCounts[status.toLowerCase()] ?? 0;
  }
}
