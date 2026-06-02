import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer';
import '../services/location_api_service.dart';
import '../data/models/location_detection_model.dart';
import '../core/utils/app_snackbar.dart';

class LocationController extends GetxController {
  // Services and controllers
  final LocationApiService _locationService = LocationApiService();

  // Observable variables for reactive UI
  var isLoading = false.obs;
  var isLocationEnabled = false.obs;
  var hasLocationPermission = false.obs;

  // Current location
  var currentLatitude = 0.0.obs;
  var currentLongitude = 0.0.obs;
  var currentAddress = ''.obs;

  // Passenger location (for auto-detection)
  var passengerLatitude = 0.0.obs;
  var passengerLongitude = 0.0.obs;
  var passengerAddress = ''.obs;
  var isDetectingPassengerLocation = false.obs;

  // Auto-detection settings
  var isAutoDetectionEnabled = true.obs;
  var autoDetectionInterval = 30.obs; // seconds
  var lastDetectionTime = DateTime.now().obs;

  // Location detection status
  var locationStatus = 'Not detected'.obs;
  var lastUpdated = ''.obs;

  // Store the detected location model
  LocationDetectionModel? _detectedLocation;

  // Timer for automatic detection
  Timer? _autoDetectionTimer;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Notification control - completely disable location notifications
  var showLocationNotifications = false.obs; // Turned OFF permanently
  var showCriticalNotificationsOnly = false.obs;
  var lastNotificationTime = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    // Start location services automatically
    initializeLocationServices();
  }

  /// Initialize location services on app start
  Future<void> initializeLocationServices() async {
    try {
      log('🚀 Initializing location services...');

      // Check and request permissions first
      await checkLocationPermissions();

      // If permissions granted, start location tracking
      if (hasLocationPermission.value) {
        await getCurrentLocation();

        // Start auto-detection if enabled
        if (isAutoDetectionEnabled.value) {
          startAutoDetection();
        }

        log('✅ Location services initialized successfully');
      } else {
        log('❌ Location permissions not granted');
      }
    } catch (e) {
      log('💥 Failed to initialize location services: $e');
      locationStatus.value = 'Failed to initialize: $e';
    }
  }

  /// Check and request location permissions - NO NOTIFICATIONS
  Future<void> checkLocationPermissions() async {
    try {
      isLoading.value = true;

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      isLocationEnabled.value = serviceEnabled;

      if (!serviceEnabled) {
        locationStatus.value = 'Location services disabled';
        // NO NOTIFICATION - work silently
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationStatus.value = 'Location permissions denied';
          hasLocationPermission.value = false;
          // NO NOTIFICATION - work silently
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationStatus.value = 'Location permissions permanently denied';
        hasLocationPermission.value = false;
        // Only show critical notification for permanent denial

        return;
      }

      hasLocationPermission.value = true;
      locationStatus.value = 'Permission granted';

      // Start automatic location tracking silently
      await startLocationTracking();
    } catch (e) {
      locationStatus.value = 'Error: $e';
      log('Location permission error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// REMOVED - No more critical notifications for location updates
  // void _showCriticalNotification() method completely removed

  /// Start continuous location tracking with automatic passenger detection
  Future<void> startLocationTracking() async {
    if (!hasLocationPermission.value) return;

    try {
      locationStatus.value = 'Starting automatic location tracking...';

      // Get initial location silently
      await getCurrentLocation();

      // Start listening to location changes
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 50 meters
        // Removed timeLimit to make location tracking infinite
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _onLocationUpdate(position);
        },
        onError: (error) {
          locationStatus.value = 'Location tracking error: $error';
          log('Location tracking error: $error');
          // NO NOTIFICATION - work silently
        },
      );

      // Start automatic passenger detection timer
      startAutoDetection();

      locationStatus.value = 'Automatic tracking active';
      log('Location tracking started successfully');
    } catch (e) {
      locationStatus.value = 'Failed to start tracking: $e';
      log('Failed to start location tracking: $e');
      // NO NOTIFICATION - work silently
    }
  }

  /// Handle location updates from the stream - work silently
  void _onLocationUpdate(Position position) {
    currentLatitude.value = position.latitude;
    currentLongitude.value = position.longitude;
    lastUpdated.value = DateTime.now().toString().split('.')[0];

    // Update address silently
    currentAddress.value = 'Driver Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    // Log for debugging but don't show notifications
    log('📍 Location updated silently: ${position.latitude}, ${position.longitude}');
  }

  /// Start automatic passenger detection with timer
  void startAutoDetection() {
    if (!isAutoDetectionEnabled.value) return;

    _autoDetectionTimer?.cancel();
    _autoDetectionTimer = Timer.periodic(
      Duration(seconds: autoDetectionInterval.value),
      (timer) async {
        if (hasCurrentLocation && isAutoDetectionEnabled.value) {
          await _performAutoDetection();
        }
      },
    );
  }

  /// Stop automatic passenger detection
  void stopAutoDetection() {
    _autoDetectionTimer?.cancel();
    isAutoDetectionEnabled.value = false;
    locationStatus.value = 'Auto-detection stopped';
  }

  /// Toggle automatic detection on/off
  void toggleAutoDetection() {
    if (isAutoDetectionEnabled.value) {
      stopAutoDetection();
    } else {
      isAutoDetectionEnabled.value = true;
      startAutoDetection();
      locationStatus.value = 'Auto-detection enabled';
    }
  }

  /// Perform automatic passenger detection - work silently
  Future<void> _performAutoDetection() async {
    if (isDetectingPassengerLocation.value) return; // Avoid overlapping requests

    try {
      isDetectingPassengerLocation.value = true;
      locationStatus.value = 'Auto-detecting...';

      // Only passenger detection now - work silently
      await _performPassengerDetection();

      locationStatus.value = 'Auto-detection completed';
    } catch (e) {
      locationStatus.value = 'Auto-detection error: $e';
      log('Auto-detection error: $e');
    } finally {
      isDetectingPassengerLocation.value = false;
    }
  }

  /// Perform passenger detection (separated from vehicle detection) - work silently
  Future<void> _performPassengerDetection() async {
    try {
      // Call the real API for auto-detection
      final response = await LocationApiService.autoDetectPassengerLocation(
        lat: currentLatitude.value,
        lng: currentLongitude.value,
      );

      if (response['success'] == true) {
        // Successfully detected location
        _detectedLocation = response['data'] as LocationDetectionModel;

        // Check if this is a new location (different from previous)
        bool isNewLocation = passengerLatitude.value != _detectedLocation!.latitude ||
                            passengerLongitude.value != _detectedLocation!.longitude;

        passengerLatitude.value = _detectedLocation!.latitude;
        passengerLongitude.value = _detectedLocation!.longitude;
        passengerAddress.value = _detectedLocation!.address;
        lastDetectionTime.value = DateTime.now();

        // Log silently - no notifications for automatic background detection
        if (isNewLocation) {
          log('📍 New passenger location detected silently: ${_detectedLocation!.address}');
        }
      }
    } catch (e) {
      log('Passenger detection error: $e');
    }
  }

  /// Get current driver location manually
  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;
      locationStatus.value = 'Getting current location...';

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 40),
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
      lastUpdated.value = DateTime.now().toString().split('.')[0];

      currentAddress.value = 'Driver Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      locationStatus.value = 'Current location detected';
      log('Current location detected: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      locationStatus.value = 'Failed to get location: $e';
      log('Failed to get current location: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Manual passenger detection (for button press) - show notifications only for manual actions
  Future<void> manualDetectPassengerLocation() async {
    if (!hasCurrentLocation) {
      showWarningSnackBar(
        'Please enable your location first',
        title: 'Location Required',
      );
      return;
    }

    if (isDetectingPassengerLocation.value) {
      showInfoSnackBar(
        'Please wait for current detection to complete',
        title: 'Detection in Progress',
      );
      return;
    }

    try {
      isDetectingPassengerLocation.value = true;
      locationStatus.value = 'Manual detection in progress...';

      // Show notification only for manual detection
      showInfoSnackBar(
        'Manually searching for passenger location...',
        title: 'Detecting Passenger',
      );

      await _performPassengerDetection();

      // Show result notification only for manual detection
      if (hasPassengerLocation) {
        showSuccessSnackBar(
          'Passenger location detected manually',
          title: 'Passenger Found',
        );
      } else {
        showWarningSnackBar(
          'No passenger detected at this location',
          title: 'No Passenger Found',
        );
      }

      locationStatus.value = 'Manual detection completed';
    } catch (e) {
      locationStatus.value = 'Manual detection failed: $e';
      showErrorSnackBar(
        'Failed to detect passenger: $e',
        title: 'Detection Error',
      );
    } finally {
      isDetectingPassengerLocation.value = false;
    }
  }

  /// Clear passenger location - show notification only when manually triggered
  void clearPassengerLocation() {
    passengerLatitude.value = 0.0;
    passengerLongitude.value = 0.0;
    passengerAddress.value = '';
    _detectedLocation = null;

    showInfoSnackBar(
      'Passenger location cleared',
      title: 'Cleared',
    );
  }

  /// Clear all detections - show notification only when manually triggered
  void clearAllDetections() {
    clearPassengerLocation();

    showInfoSnackBar(
      'All detections and locations cleared',
      title: 'All Cleared',
    );
  }

  /// Refresh all locations and detections - show notifications only for manual refresh
  Future<void> refreshLocations() async {
    try {
      isLoading.value = true;
      locationStatus.value = 'Refreshing all locations...';

      // Refresh current location first
      await getCurrentLocation();

      // Then perform passenger detection
      if (hasCurrentLocation) {
        await _performPassengerDetection();
      }

      locationStatus.value = 'All locations refreshed';

      // Show notification only for manual refresh
      showSuccessSnackBar(
        'All locations updated',
        title: 'Refreshed',
      );
    } catch (e) {
      locationStatus.value = 'Refresh failed: $e';
      showErrorSnackBar(
        'Failed to refresh locations: $e',
        title: 'Refresh Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Set auto-detection interval - show notification only when manually changed
  void setAutoDetectionInterval(int seconds) {
    autoDetectionInterval.value = seconds;

    // Restart timer with new interval if auto-detection is active
    if (isAutoDetectionEnabled.value) {
      startAutoDetection();
    }

    showInfoSnackBar(
      'Auto-detection interval set to ${seconds}s',
      title: 'Interval Updated',
    );
  }

  /// Get formatted distance between driver and passenger
  String getFormattedDistance() {
    if (!hasCurrentLocation || !hasPassengerLocation) {
      return 'Unknown';
    }

    try {
      double distanceInMeters = Geolocator.distanceBetween(
        currentLatitude.value,
        currentLongitude.value,
        passengerLatitude.value,
        passengerLongitude.value,
      );

      if (distanceInMeters < 1000) {
        return '${distanceInMeters.round()}m';
      } else {
        return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
      }
    } catch (e) {
      return 'Error';
    }
  }

  /// Get formatted last detection time
  String getLastDetectionTime() {
    final now = DateTime.now();
    final difference = now.difference(lastDetectionTime.value);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  // Getter methods for location availability checks
  bool get hasCurrentLocation => currentLatitude.value != 0.0 && currentLongitude.value != 0.0;
  bool get hasPassengerLocation => passengerLatitude.value != 0.0 && passengerLongitude.value != 0.0;
  bool get isLocationReady => hasLocationPermission.value && isLocationEnabled.value;
  bool get canPerformDetection => hasCurrentLocation && !isDetectingPassengerLocation.value;

  // Status getters
  String get currentLocationFormatted => hasCurrentLocation
    ? '${currentLatitude.value.toStringAsFixed(6)}, ${currentLongitude.value.toStringAsFixed(6)}'
    : 'Location not available';

  String get passengerLocationFormatted => hasPassengerLocation
    ? '${passengerLatitude.value.toStringAsFixed(6)}, ${passengerLongitude.value.toStringAsFixed(6)}'
    : 'No passenger detected';

  /// Get status summary for debugging
  String get debugStatus => '''
Location Controller Status:
- Has Permissions: ${hasLocationPermission.value}
- Location Enabled: ${isLocationEnabled.value}
- Has Current Location: $hasCurrentLocation
- Has Passenger Location: $hasPassengerLocation
- Auto-detection Enabled: ${isAutoDetectionEnabled.value}
- Is Detecting: ${isDetectingPassengerLocation.value}
- Current: $currentLocationFormatted
- Passenger: $passengerLocationFormatted
- Status: ${locationStatus.value}
''';

  @override
  void onClose() {
    // Clean up resources
    _autoDetectionTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.onClose();
  }
}
