import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/ride.dart';
import 'package:rideal_driver/services/rides_api_service.dart';
import 'package:rideal_driver/routes/app_pages.dart';
import 'package:rideal_driver/core/storage_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../services/verification_api_service.dart';
import '../data/models/verification_status.dart';
import '../core/utils/app_snackbar.dart';
import '../core/sound_manager.dart';
import '../fcm_service.dart';

class RidesController extends GetxController {
  final RidesApiService _ridesApiService = RidesApiService();
  final VerificationApiService _verificationApiService = VerificationApiService();

  // Observable variables
  var isLoading = false.obs;
  var rides = <Ride>[].obs;
  var errorMessage = ''.obs;
  var hasError = false.obs;

  // KYC verification status
  var isKycVerified = false.obs;
  var kycStatus = ''.obs;
  var verificationData = Rx<VerificationData?>(null);

  // Computed properties for summary statistics
  int get totalRides => rides.length;

  double get averageFare {
    if (rides.isEmpty) return 0.0;
    double total = rides.fold(0.0, (sum, ride) => sum + ride.estimatedFare);
    return total / rides.length;
  }

  @override
  void onInit() {
    super.onInit();
    checkKycVerificationStatus();
    loadAvailableRides();
  }

  // Check KYC verification status using the new API
  Future<void> checkKycVerificationStatus() async {
    try {
      log('🔍 Checking KYC verification status...');

      final response = await _verificationApiService.getVerificationStatus();

      if (response['success'] == true && response['verification'] != null) {
        // Parse the verification data from API response
        final verificationJson = response['verification'];
        verificationData.value = VerificationData.fromJson(verificationJson);
        kycStatus.value = response['status'] ?? 'pending';
        isKycVerified.value = kycStatus.value.toLowerCase() == 'approved' ||
                              kycStatus.value.toLowerCase() == 'verified';

        log('✅ KYC Status: ${kycStatus.value}, Verified: ${isKycVerified.value}');
      } else if (response['status'] == 'not_submitted') {
        // No verification data found - driver hasn't submitted documents
        isKycVerified.value = false;
        kycStatus.value = 'not_submitted';
        verificationData.value = null;

        log('❌ No KYC documents found - status: not_submitted');
      } else {
        // API returned error or unexpected response
        isKycVerified.value = false;
        kycStatus.value = response['status'] ?? 'error';
        verificationData.value = null;

        log('❌ KYC verification API error: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      log('❌ Error checking KYC status: $e');
      isKycVerified.value = false;
      kycStatus.value = 'error';
      verificationData.value = null;
    }
  }

  Future<void> loadAvailableRides() async {
    try {
      log('🏠 Starting to load available rides...');
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await _ridesApiService.getAvailableRides();

      log('🏠 Rides controller received response: isSuccess=${response['success']}');
      log('🏠 Response data: $response');

      if (response['success'] == true) {
        final ridesList = response['rides'] as List<Ride>;
        rides.value = ridesList;
        log('🏠 Processing ${ridesList.length} rides from API...');
        log('🚗 Successfully loaded ${rides.length} available rides');
      } else {
        hasError.value = true;
        errorMessage.value = response['error'] ?? 'Failed to load rides';
        log('! API returned error: ${errorMessage.value}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'An error occurred while loading rides';
      log('❌ Error in loadAvailableRides: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshRides() async {
    await loadAvailableRides();
  }

  Future<bool> acceptRide(String rideId) async {
    try {
      log('📞 Attempting to accept ride: $rideId');
      
      // 🎵 Stop sound immediately when user takes action
      SoundManager().stopRequestSound();
      FCMService.stopRequestSound();

      // Check KYC verification status first
      await checkKycVerificationStatus();

      if (!isKycVerified.value) {
        Get.dialog(
          AlertDialog(
            title: const Text('Documents Not Verified'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kycStatus.value == 'not_submitted')
                  const Text('You need to submit your KYC documents before accepting rides.')
                else if (kycStatus.value == 'pending')
                  const Text('Your documents are under review. You can accept rides once they are approved.')
                else if (kycStatus.value == 'rejected')
                  const Text('Your documents have been rejected. Please resubmit your documents.')
                else
                  const Text('Unable to verify your documents. Please check your submission status.'),
                const SizedBox(height: 16),
                const Text('Would you like to go to KYC documents section?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed('/kyc-documents');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                ),
                child: const Text(
                  'Go to KYC',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          barrierDismissible: true,
        );
        return false;
      }

      // Show loading indicator
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Get.theme.primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accepting ride...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final response = await _ridesApiService.acceptRide(rideId);

      // Close loading dialog
      Get.back();

      if (response['success'] == true) {
        log('✅ Ride accepted successfully');

        // Find the accepted ride to pass to ongoing ride screen
        Ride? acceptedRide = rides.firstWhereOrNull((ride) => ride.id == rideId);

        // If the response contains updated ride data, use that instead
        if (response['ride'] != null) {
          acceptedRide = response['ride'] as Ride;
        }

        // Remove the accepted ride from the list
        rides.removeWhere((ride) => ride.id == rideId);

        // Show success message
        showSuccessSnackBar(
          response['message'] ?? 'Ride accepted successfully',
          title: 'Success',
        );

        // Update driver location after successful ride acceptance
        await _updateDriverLocationAfterAcceptance(rideId);

        // Navigate to ongoing ride screen
        Get.toNamed(Routes.ONGOING_RIDE, arguments: acceptedRide);
      
        return true;
      } else {
        log('❌ Ride acceptance failed: ${response['message']}');
        showErrorSnackBar(
          response['message'] ?? 'Failed to accept ride',
          title: 'Failed',
        );
        return false;
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      log('❌ Exception in acceptRide: $e');
      showErrorSnackBar(
        'Network error occurred. Please try again.',
        title: 'Error',
      );
      return false;
    }
  }

  // Update driver location after ride acceptance
  Future<void> _updateDriverLocationAfterAcceptance(String rideId) async {
    try {
      log('📍 Starting driver location update for ride: $rideId');

      // Get driver ID from stored user data
      final driverId = await StorageHelper.getDriverId();
      if (driverId == null) {
        log('❌ Driver ID not found in storage');
        return;
      }

      // Get current location
      Position? currentPosition = await _getCurrentLocation();
      if (currentPosition == null) {
        log('❌ Could not get current location');
        return;
      }

      // Update driver location via API using the new response model
      final response = await _ridesApiService.updateDriverLocation(
        rideId: rideId,
        driverId: driverId,
        lat: currentPosition.latitude,
        lng: currentPosition.longitude,
      );

      if (response.success) {
        log('✅ Driver location updated successfully');

        // Show success message to driver
        showSuccessSnackBar(
          'Your location has been shared with the passenger',
          title: 'Location Updated',
        );
      } else {
        log('❌ Failed to update driver location: ${response.message}');

        // Show warning but don't block the ride
        showWarningSnackBar(
          'Location sharing may be delayed: ${response.message}',
          title: 'Location Update',
        );
      }
    } catch (e) {
      log('❌ Exception updating driver location: $e');
      // Silent fail - don't disrupt the ride acceptance flow
    }
  }

  // Get current location with error handling
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('❌ Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('❌ Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log('❌ Location permissions permanently denied');
        return null;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 40),
      );

      log('✅ Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      log('❌ Error getting current location: $e');
      return null;
    }
  }

  // Filter rides by type
  List<Ride> getRidesByType(String type) {
    return rides.where((ride) => ride.rideType == type).toList();
  }

  // Get rides by status
  List<Ride> getRidesByStatus(String status) {
    return rides.where((ride) => ride.status == status).toList();
  }

  // Get scheduled rides
  List<Ride> getScheduledRides() {
    return rides.where((ride) => ride.isScheduled).toList();
  }

  // Get immediate rides
  List<Ride> getImmediateRides() {
    return rides.where((ride) => !ride.isScheduled).toList();
  }

  // Add missing methods for RideRequestsScreen
  Future<void> fetchAvailableRides() async {
    await loadAvailableRides();
  }

  Future<void> rejectRide(String rideId) async {
    try {
      log('❌ Rejecting ride: $rideId');

      // 🎵 Stop sound immediately when user takes action
      SoundManager().stopRequestSound();
      FCMService.stopRequestSound();

      final response = await _ridesApiService.cancelRide(rideId);

      if (response['success'] == true) {
        // Remove the rejected ride from the list
        rides.removeWhere((ride) => ride.id == rideId);

        showInfoSnackBar(
          'You have declined this ride request',
          title: 'Ride Declined',
        );

        log('✅ Ride rejected successfully');
      } else {
        showErrorSnackBar(
          response['message'] ?? 'Failed to decline ride',
          title: 'Error',
        );
      }
    } catch (e) {
      log('❌ Error rejecting ride: $e');
      showErrorSnackBar(
        'Network error occurred while declining ride',
        title: 'Error',
      );
    }
  }
}

