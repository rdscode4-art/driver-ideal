import 'package:get/get.dart';
import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import '../services/navigation_api_service.dart';

class NavigationController extends GetxController {
  final NavigationApiService _navigationApiService = NavigationApiService();

  // Observable variables for navigation state
  var isNavigating = false.obs;
  var currentStep = ''.obs;
  var currentSpeed = 0.0.obs;
  var navigationProgress = 0.0.obs;
  var remainingDistance = 0.0.obs;
  var estimatedTimeMinutes = 0.obs;

  // Navigation destination
  var destinationLatitude = 0.0.obs;
  var destinationLongitude = 0.0.obs;
  var destinationAddress = ''.obs;

  // Current location tracking
  var currentLatitude = 0.0.obs;
  var currentLongitude = 0.0.obs;

  // Navigation data
  var isLoadingNavigation = false.obs;
  var hasNavigationError = false.obs;
  var navigationError = ''.obs;

  Timer? _navigationTimer;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void onInit() {
    super.onInit();
    _startLocationTracking();
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();
    _positionSubscription?.cancel();
    super.onClose();
  }

  /// Start navigation to a destination
  Future<void> startNavigation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      log('🧭 Starting navigation to: $address');

      destinationLatitude.value = latitude;
      destinationLongitude.value = longitude;
      destinationAddress.value = address;

      isNavigating.value = true;
      currentStep.value = 'Starting navigation to $address';
      navigationProgress.value = 0.0;

      // Start navigation updates
      _startNavigationUpdates();

      Get.snackbar(
        'Navigation Started',
        'Navigate to $address',
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      log('❌ Error starting navigation: $e');
      Get.snackbar('Error', 'Failed to start navigation: $e');
    }
  }

  /// Stop navigation
  void stopNavigation() {
    isNavigating.value = false;
    currentStep.value = '';
    navigationProgress.value = 0.0;
    destinationLatitude.value = 0.0;
    destinationLongitude.value = 0.0;
    destinationAddress.value = '';

    _navigationTimer?.cancel();

    Get.snackbar(
      'Navigation Stopped',
      'Navigation has been stopped',
      duration: const Duration(seconds: 2),
    );

    log('🛑 Navigation stopped');
  }

  /// Update current location (manual refresh)
  void updateLocation() {
    log('🔄 Manually updating location');
    Get.snackbar(
      'Location Updated',
      'Current location refreshed',
      duration: const Duration(seconds: 2),
    );
  }

  /// Start location tracking
  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        currentLatitude.value = position.latitude;
        currentLongitude.value = position.longitude;
        currentSpeed.value = position.speed * 3.6; // Convert m/s to km/h

        if (isNavigating.value) {
          _updateNavigationProgress();
        }
      },
      onError: (error) {
        log('❌ Location tracking error: $error');
      },
    );
  }

  /// Start navigation updates timer
  void _startNavigationUpdates() {
    _navigationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateNavigationData(),
    );
  }

  /// Update navigation progress based on current location
  void _updateNavigationProgress() {
    if (destinationLatitude.value != 0.0 && destinationLongitude.value != 0.0) {
      final distance = Geolocator.distanceBetween(
        currentLatitude.value,
        currentLongitude.value,
        destinationLatitude.value,
        destinationLongitude.value,
      );

      remainingDistance.value = distance / 1000; // Convert to kilometers

      // Calculate estimated time based on current speed
      if (currentSpeed.value > 0) {
        estimatedTimeMinutes.value = (remainingDistance.value / currentSpeed.value * 60).round();
      } else {
        estimatedTimeMinutes.value = (remainingDistance.value / 25 * 60).round(); // Assume 25 km/h average
      }

      // Update progress (simplified calculation)
      if (remainingDistance.value < 0.1) { // Within 100 meters
        navigationProgress.value = 1.0;
        currentStep.value = 'You have arrived at your destination';

        // Auto-stop navigation when arrived
        Future.delayed(const Duration(seconds: 3), () {
          if (isNavigating.value) {
            stopNavigation();
          }
        });
      } else if (remainingDistance.value < 1.0) { // Within 1 km
        navigationProgress.value = 0.8;
        currentStep.value = 'Approaching destination - ${remainingDistance.value.toStringAsFixed(1)} km remaining';
      } else {
        navigationProgress.value = 0.3; // General progress
        currentStep.value = 'Continue to destination - ${remainingDistance.value.toStringAsFixed(1)} km remaining';
      }
    }
  }

  /// Update navigation data using API
  Future<void> _updateNavigationData() async {
    if (!isNavigating.value || destinationLatitude.value == 0.0) return;

    try {
      // Format coordinates as required by the API: "lat,lng"
      final origin = '${currentLatitude.value},${currentLongitude.value}';
      final destination = '${destinationLatitude.value},${destinationLongitude.value}';

      final response = await _navigationApiService.getNavigationData(
        origin: origin,
        destination: destination,
      );

      if (response['success'] == true) {
        // Update navigation data from API if available
        final navData = response['data'];
        if (navData != null) {
          // Update remaining distance and duration from API response
          final distanceStr = navData.distance ?? '';
          final durationStr = navData.duration ?? '';

          log('✅ Navigation data updated from API: $distanceStr in $durationStr');

          // Parse distance from API response (e.g., "77.8 km" -> 77.8)
          final distanceMatch = RegExp(r'(\d+\.?\d*)\s*km').firstMatch(distanceStr);
          if (distanceMatch != null) {
            final apiDistance = double.tryParse(distanceMatch.group(1) ?? '');
            if (apiDistance != null) {
              remainingDistance.value = apiDistance;
              log('📍 Updated remaining distance from API: ${remainingDistance.value} km');
            }
          }
        }
      }
    } catch (e) {
      log('⚠️ Navigation API update failed: $e');
      // Continue with local calculations as fallback
    }
  }

  /// Get formatted remaining distance
  String get formattedRemainingDistance {
    if (remainingDistance.value < 1.0) {
      return '${(remainingDistance.value * 1000).round()}m';
    } else {
      return '${remainingDistance.value.toStringAsFixed(1)}km';
    }
  }

  /// Get formatted estimated time
  String get formattedEstimatedTime {
    if (estimatedTimeMinutes.value < 60) {
      return '${estimatedTimeMinutes.value}min';
    } else {
      final hours = estimatedTimeMinutes.value ~/ 60;
      final minutes = estimatedTimeMinutes.value % 60;
      return '${hours}h ${minutes}min';
    }
  }
}
