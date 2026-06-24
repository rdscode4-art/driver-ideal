import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/material.dart';
import '../data/models/future_ride_models.dart';
import '../services/future_ride_api_service.dart';
import '../core/utils/app_snackbar.dart';

class FutureRideController extends GetxController {
  // Loading states
  var isLoading = false.obs;
  var isLoadingRides = false.obs;

  var isLoadingRequests = false.obs;
  // Active future rides list (local storage until backend GET endpoint is available)
  var activeFutureRides = <FutureRide>[].obs;


  // Ride requests list
  var rideRequests = <FutureRideWithRequests>[].obs;
  // Error handling
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveFutureRides();
    fetchRideRequests();

    // Show info message about upcoming feature
    Future.delayed(const Duration(seconds: 1), () {
      // Get.snackbar(
      //   'Info',
      //   'Future rides list will be available once backend team adds the GET endpoint',
      //   backgroundColor: Get.theme.primaryColor.withValues(alpha: 0.1),
      //   colorText: Get.theme.primaryColor,
      //   snackPosition: SnackPosition.BOTTOM,
      //   duration: Duration(seconds: 3),
      // );
    });
  }

  /// Converts address to coordinates using geocoding
  Future<Map<String, double>> _getCoordinatesFromAddress(String address) async {
    try {
      print('🌍 Getting coordinates for address: $address');
      List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final coords = {
          'lat': locations.first.latitude,
          'lng': locations.first.longitude,
        };
        print('✅ Coordinates found: lat=${coords['lat']}, lng=${coords['lng']}');
        return coords;
      }
    } catch (e) {
      print('❌ Geocoding error for address "$address": $e');
    }

    // Return default Delhi coordinates if geocoding fails
    print('⚠️ Using default Delhi coordinates for: $address');
    return {
      'lat': 28.6139,
      'lng': 77.2090,
    };
  }

  /// Creates a new future ride offer with REAL coordinates from geocoding
  Future<bool> createFutureRide({
    required String fromAddress,
    required String toAddress,
    required DateTime selectedDate,
    required String selectedTime,
    required double pricePerSeat,
    required String vehicleName,
    required String vehicleColor,
    required String vehicleNumber,
    required String driverPhone,
    required int maxPassengers,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Show geocoding progress to user
      showInfoSnackBar(
        'Getting location coordinates from addresses...',
        title: 'Please Wait',
      );

      // Get REAL coordinates from addresses using geocoding
      final fromCoordinates = await _getCoordinatesFromAddress(fromAddress);
      final toCoordinates = await _getCoordinatesFromAddress(toAddress);

      // Format date as YYYY-MM-DD
      final formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      // Create the request object with REAL coordinates from geocoding
      final request = FutureRideRequest(
        fromLocation: Location(
          address: fromAddress,
          lat: fromCoordinates['lat']!, // Real coordinates from geocoding
          lng: fromCoordinates['lng']!, // Real coordinates from geocoding
        ),
        toLocation: Location(
          address: toAddress,
          lat: toCoordinates['lat']!, // Real coordinates from geocoding
          lng: toCoordinates['lng']!, // Real coordinates from geocoding
        ),
        date: formattedDate,
        time: selectedTime,
        pricePerPassenger: pricePerSeat,
        vehicle: Vehicle(
          name: vehicleName,
          color: vehicleColor,
          numberPlate: vehicleNumber,
        ),
        driverPhone: driverPhone,
        maxPassengers: maxPassengers,
      );

      print('🚗 Creating ride with coordinates:');
      print('   From: $fromAddress (${fromCoordinates['lat']}, ${fromCoordinates['lng']})');
      print('   To: $toAddress (${toCoordinates['lat']}, ${toCoordinates['lng']})');

      final response = await FutureRideApiService.createFutureRide(request);

      if (response['success'] == true) {
        showSuccessSnackBar(
          'Future ride created with proper location coordinates!',
          title: 'Success',
        );

        // Add to local list temporarily until GET endpoint is available
        if (response['ride'] != null) {
          final newRide = response['ride'] as FutureRide;
          activeFutureRides.insert(0, newRide); // Add to beginning of list
        }

        return true;
      } else {
        errorMessage.value = response['message'] ?? 'Failed to create future ride';
        showErrorSnackBar(
          errorMessage.value,
          title: 'Error',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error creating future ride: $e');
      errorMessage.value = 'Network error occurred. Please try again.';
      showErrorSnackBar(
        errorMessage.value,
        title: 'Error',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches all active future rides for the driver
  /// Currently commented out since GET endpoint doesn't exist yet
  Future<void> fetchActiveFutureRides() async {
    try {
      isLoadingRides.value = true;
      errorMessage.value = '';

      // Temporarily return empty list
      activeFutureRides.clear();

    } catch (e) {
      print('Error fetching active future rides: $e');
      errorMessage.value = 'Feature coming soon';
    } finally {
      isLoadingRides.value = false;
    }
  }

  /// Refreshes the active rides list
  void refreshActiveRides() {
    // Get.snackbar(
    //   'Info',
    //   'Refresh feature will be available once backend team adds the GET endpoint',
    //   backgroundColor: Get.theme.primaryColor.withValues(alpha: 0.1),
    //   colorText: Get.theme.primaryColor,
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  /// Gets count of active future rides
  int get activeRidesCount => activeFutureRides.length;

  /// Checks if there are any active rides
  bool get hasActiveRides => activeFutureRides.isNotEmpty;

  /// Gets rides for a specific date
  List<FutureRide> getRidesForDate(DateTime date) {
    return activeFutureRides.where((ride) {
      return ride.date.year == date.year &&
             ride.date.month == date.month &&
             ride.date.day == date.day;
    }).toList();
  }

  /// Gets upcoming rides (today and future)
  List<FutureRide> get upcomingRides {
    final now = DateTime.now();
    return activeFutureRides.where((ride) {
      return ride.date.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Cancel a future ride
  Future<bool> cancelFutureRide(String rideId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // TODO: Implement cancel API call when available
      // final response = await FutureRideApiService.cancelFutureRide(rideId);

      // For now, show info message
      showInfoSnackBar(
        'Cancel functionality will be available soon!',
        title: 'Info',
      );

      return false;
    } catch (e) {
      errorMessage.value = 'Failed to cancel ride: $e';
      Get.snackbar(
        'Error',
        errorMessage.value,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update a future ride
  Future<bool> updateFutureRide(String rideId, Map<String, dynamic> updates) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // TODO: Implement update API call when available
      // final response = await FutureRideApiService.updateFutureRide(rideId, updates);

      // For now, show info message
      showInfoSnackBar(
        'Edit functionality will be available soon!',
        title: 'Info',
      );

      return false;
    } catch (e) {
      errorMessage.value = 'Failed to update ride: $e';
      Get.snackbar(
        'Error',
        errorMessage.value,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Responds to a passenger booking request (accept or reject)
  Future<bool> respondToBookingRequest({
    required String rideId,
    required String bookingId,
    required String action, // "accept" or "rejected"
  }) async {
    try {
      // Don't use isLoading here as UI handles its own loading
      errorMessage.value = '';

      print('🎯 Responding to booking request: $action');

      // Add timeout to prevent hanging
      final response = await FutureRideApiService.respondToBooking(
        rideId: rideId,
        bookingId: bookingId,
        action: action,
      ).timeout(
        const Duration(seconds: 15), // 15 second timeout
        onTimeout: () => {
          'success': false,
          'message': 'Request timed out. Please try again.',
        },
      );

      if (response['success'] == true) {
        // Update the local booking status immediately
        _updateLocalBookingStatus(rideId, bookingId, action == 'accept' ? 'accepted' : 'rejected');

        // Show success message
        showSuccessSnackBar(
          response['message'] ?? 'Booking ${action}ed successfully!',
          title: 'Success',
        );

        return true;
      } else {
        errorMessage.value = response['message'] ?? 'Failed to $action booking';
        showErrorSnackBar(
          errorMessage.value,
          title: 'Error',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error responding to booking: $e');
      errorMessage.value = 'Network error occurred. Please try again.';
      showErrorSnackBar(
        'Network error occurred. Please check your connection.',
        title: 'Error',
      );
      return false;
    }
  }

  /// Accept a passenger booking request
  Future<bool> acceptBookingRequest(String rideId, String bookingId) async {
    return await respondToBookingRequest(
      rideId: rideId,
      bookingId: bookingId,
      action: 'accept',
    );
  }

  /// Reject a passenger booking request
  Future<bool> rejectBookingRequest(String rideId, String bookingId) async {
    return await respondToBookingRequest(
      rideId: rideId,
      bookingId: bookingId,
      action: 'rejected', // Changed from 'reject' to 'rejected' to match API expectation
    );
  }

  /// Update local booking status after API call
  void _updateLocalBookingStatus(String rideId, String bookingId, String newStatus) {
    try {
      print('🔄 Updating local booking status: $bookingId -> $newStatus');

      for (int i = 0; i < rideRequests.length; i++) {
        final rideWithRequests = rideRequests[i];
        if (rideWithRequests.id == rideId) { // Use .id instead of .rideId
          for (int j = 0; j < rideWithRequests.passengersBooked.length; j++) {
            final booking = rideWithRequests.passengersBooked[j];
            if (booking.bookingId == bookingId) {
              // Create updated booking with new status
              final updatedBooking = PassengerBooking(
                bookingId: booking.bookingId,
                rider: booking.rider,
                numOfSeats: booking.numOfSeats,
                status: newStatus,
              );

              // Create new passengers list with updated booking
              final updatedPassengers = List<PassengerBooking>.from(rideWithRequests.passengersBooked);
              updatedPassengers[j] = updatedBooking;

              // Create new ride with updated passengers list
              final updatedRide = FutureRideWithRequests(
                id: rideWithRequests.id,
                fromLocation: rideWithRequests.fromLocation,
                toLocation: rideWithRequests.toLocation,
                date: rideWithRequests.date,
                time: rideWithRequests.time,
                vehicle: rideWithRequests.vehicle,
                passengersBooked: updatedPassengers,
              );

              // Update the ride in the list
              rideRequests[i] = updatedRide;
              rideRequests.refresh(); // Force reactive update

              print('✅ Updated local booking status: $bookingId -> $newStatus');
              return;
            }
          }
          break;
        }
      }
      print('❌ Could not find booking $bookingId in ride $rideId');
    } catch (e) {
      print('❌ Error updating local booking status: $e');
    }
  }

  /// Fetch ride requests from API
  Future<void> fetchRideRequests() async {
    try {
      isLoadingRequests.value = true;
      errorMessage.value = '';

      print('🔄 Fetching ride requests...');

      final response = await FutureRideApiService.getDriverRideRequests();

      if (response['success'] == true) {
        final List<FutureRideWithRequests> fetchedRides = response['rides'] ?? [];
        rideRequests.value = fetchedRides;

        print('✅ Successfully loaded ${fetchedRides.length} ride requests');
      } else {
        errorMessage.value = response['message'] ?? 'Failed to fetch ride requests';
        print('❌ Failed to fetch ride requests: ${errorMessage.value}');
      }
    } catch (e) {
      print('❌ Error fetching ride requests: $e');
      errorMessage.value = 'Network error occurred while fetching ride requests';
    } finally {
      isLoadingRequests.value = false;
    }
  }

  /// Refresh ride requests
  Future<void> refreshRideRequests() async {
    await fetchRideRequests();
  }

  /// Get total pending requests count across all rides
  int get totalPendingRequests {
    int total = 0;
    for (var rideWithRequests in rideRequests) {
      total += rideWithRequests.pendingRequestsCount;
    }
    return total;
  }

  void clearError() {
    errorMessage.value = '';
  }

  /// Reset controller state
  void reset() {
    isLoading.value = false;
    isLoadingRides.value = false;
    activeFutureRides.clear();
    isLoadingRequests.value = false;
    errorMessage.value = '';
    rideRequests.clear();
  }
}
