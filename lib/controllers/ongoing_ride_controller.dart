import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/navigation_response.dart';
import '../ride.dart';
import '../services/rides_api_service.dart';
import '../services/rides_api_service.dart' as services;
import '../services/navigation_api_service.dart';
import '../services/geocoding_service.dart';
import '../services/enhanced_geocoding_service.dart';
import 'location_controller.dart';
import 'paymentscreen.dart';
import '../core/utils/app_snackbar.dart';

enum RidePhase {
  GOING_TO_PICKUP,
  WAITING_FOR_PASSENGER,
  PAYMENT_PENDING,  // ✅ New phase
  GOING_TO_DROPOFF,
  COMPLETED,
}

class OngoingRideController extends GetxController {
  final RidesApiService _ridesApiService = RidesApiService();
  final NavigationApiService _navigationApiService = NavigationApiService();
  final services.RidesApiService _locationApiService =
      services.RidesApiService();

  // Cached Icons
  final BitmapDescriptor _pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  final BitmapDescriptor _dropoffIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  final BitmapDescriptor _driverDefaultIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

  // Add location controller integration
  late LocationController _locationController;
var passengerPhoneNumber = ''.obs;
var currentLocationAddress = 'Getting location...'.obs;
  // Observable variables
  var isLoading = false.obs;
  var currentRide = Rxn<Ride>();
  var errorMessage = ''.obs;
  var hasError = false.obs;

  // Auto-detection location variables
  var isAutoDetecting = false.obs;
  var autoDetectedAddress = ''.obs;
  var hasAutoDetectedLocation = false.obs;
  var autoDetectionError = ''.obs;
  var lastAutoDetectionUpdate = DateTime.now().obs;

  // Google Maps controller and markers
  GoogleMapController? _mapController;
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var circles = <Circle>{}.obs; // Add circles for driver location
  var isMapReady = false.obs;

  // Navigation API integration
  var isLoadingNavigation = false.obs;
  var hasNavigationData = false.obs;
  var navigationDistance = ''.obs;
  var navigationDuration = ''.obs;
  var navigationError = ''.obs;
  var hasNavigationError = false.obs;
  var lastNavigationUpdate = DateTime.now().obs;
  var currentNavigationData = Rxn<NavigationResponse>();

  // Location tracking
  var driverLatitude = 0.0.obs;
  var driverLongitude = 0.0.obs;
  var pickupLatitude = 0.0.obs;
  var pickupLongitude = 0.0.obs;
  var dropoffLatitude = 0.0.obs;
  var dropoffLongitude = 0.0.obs;

  // Navigation and distance tracking
  var distanceToPickup = 0.0.obs;
  var distanceToDropoff = 0.0.obs;
  var estimatedDuration = 0.obs; // in minutes
  var isNavigating = false.obs;
  var hasReachedPickup = false.obs;
  var hasReachedDropoff = false.obs;
  var canCompleteRide = false.obs;

  // Timer for real-time updates
  Timer? _locationUpdateTimer;
  Timer? _navigationUpdateTimer;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Ride status tracking
  var ridePhase = RidePhase.GOING_TO_PICKUP.obs;
  var elapsedTime = 0.obs;
  Timer? _rideTimer;

  // 💳 Payment variables
  var qrCodeBase64 = ''.obs;
  var paymentLink = ''.obs;
  var isGeneratingQR = false.obs;
  var paymentAmount = 0.obs;
  var paymentCurrency = 'INR'.obs;

  // Passenger details (using default values since not in Ride model)
  var passengerName = 'Passenger'.obs;
  var passengerPhone = ''.obs;

  // Enhanced driver location tracking
  var isTrackingDriverLocation = false.obs;
  var driverLocationAccuracy = 0.0.obs;
  var lastLocationUpdate = DateTime.now().obs;
  var driverHeading = 0.0.obs; // Direction driver is facing
  // Multi-stop functionality
  // var multiStopData = Rxn<MultiStopResponse>();
  // var multiStopLocations = <MultiStopLocation>[].obs;
  // var isLoadingMultiStop = false.obs;
  // var hasMultiStopData = false.obs;
  // var multiStopError = ''.obs;
  final GeocodingService _geocodingService = GeocodingService();

  var driverSpeed = 0.0.obs; // Current speed in km/h

  @override
  void onInit() {
    super.onInit();
    log('🚀 OngoingRideController onInit starting...');
    
    // Defer initialization to avoid "setState during build" issues
    Future.microtask(() async {
      try {
        // Initialize LocationController - safely find if already exists
        if (!Get.isRegistered<LocationController>()) {
          _locationController = Get.put(LocationController());
        } else {
          _locationController = Get.find<LocationController>();
        }
        
        await _initializeRide();
        
        // Start auto location detection
        _startDriverLocationAutoDetection();
        
        log('✅ OngoingRideController deferred initialization complete');
      } catch (e, stack) {
        log('❌ Error during deferred initialization: $e');
        log('Stack trace: $stack');
        hasError.value = true;
        errorMessage.value = 'Initialization error: $e';
      }
    });
  }

  @override
  void onClose() {
    _stopLocationTracking();
    _stopNavigationUpdates();
    _rideTimer?.cancel();
    _mapController?.dispose();
    super.onClose();
  }

  // Set the Google Maps controller - called from the UI when map is ready
  void setMapController(GoogleMapController controller) {
    if (_mapController != null) {
      log('🗺️ Disposing old map controller');
      _mapController?.dispose();
    }
    
    _mapController = controller;
    isMapReady.value = true;
    log('🗺️ Google Maps controller set successfully');

    // Initialize map markers and camera position
    // Use Future.microtask to avoid triggering rebuild in same frame
    Future.microtask(() => _setupMapMarkersAndCamera());
  }

  void _setupMapMarkersAndCamera() {
    if (_mapController == null) return;

    log('🗺️ Setting up map markers and camera...');
    _updateMapMarkers();
    
    // Auto-fit markers with a slight delay to ensure map is fully rendered
    Future.delayed(const Duration(milliseconds: 500), () {
      autoFitMarkersOnMap();
    });
  }

  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};

    log('🔍 Updating map markers with current coordinates:');
    log('🚗 Driver: (${driverLatitude.value}, ${driverLongitude.value})');
    // log('📍 Pickup: (${pickupLatitude.value}, ${pickupLongitude.value})');
    // log('🏁 Dropoff: (${dropoffLatitude.value}, ${dropoffLongitude.value})');

    // Driver location circle (small circle mark)
    if (_isValidCoordinate(driverLatitude.value, driverLongitude.value)) {
      // Add driver circle marker
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(driverLatitude.value, driverLongitude.value),
          icon: _driverDefaultIcon,
          infoWindow: const InfoWindow(
            title: '🚗 Your Location',
            snippet: 'Driver current position',
          ),
          rotation: 0.0,
        ),
      );
      log(
        '✅ Added driver marker at (${driverLatitude.value}, ${driverLongitude.value})',
      );
    } else {
      log('⚠️ Skipping driver marker - invalid coordinates');
    }

    // Pickup marker
    if (_isValidCoordinate(pickupLatitude.value, pickupLongitude.value)) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLatitude.value, pickupLongitude.value),
          icon: _pickupIcon,
          infoWindow: InfoWindow(
            title: '📍 Pickup Location',
            snippet: currentRide.value?.pickupLocation ?? 'Pickup point',
          ),
        ),
      );
      }

    // Dropoff marker
    if (_isValidCoordinate(dropoffLatitude.value, dropoffLongitude.value)) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(dropoffLatitude.value, dropoffLongitude.value),
          icon: _dropoffIcon,
          infoWindow: InfoWindow(
            title: '🏁 Dropoff Location',
            snippet: currentRide.value?.dropoffLocation ?? 'Destination',
          ),
        ),
      );
      }

    // Update the markers on the map
    markers.assignAll(newMarkers);
    log('🗺️ Map updated with ${newMarkers.length} markers');

    // Update polylines whenever markers are updated
    _updatePolylines();
    
    // Manually refresh the map view in the UI
    update(['map_view']);

    // Show success notification if we have all markers
    if (newMarkers.length >= 2) {
      // At least pickup and dropoff
      // Get.snackbar(
      //   'Map Updated',
      //   'Pickup and dropoff locations now visible on map',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green[600],
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 2),
      //   icon: const Icon(Icons.map, color: Colors.white),
      //   margin: const EdgeInsets.all(8),
      // );
    }
  }

  /// Force refresh map markers and camera position
  void refreshMapDisplay() {
    if (_mapController != null && isMapReady.value) {
      log('🔄 Force refreshing map display...');
      _updateMapMarkers();
      _updatePolylines(); // Ensure polylines are also refreshed
      autoFitMarkersOnMap();
    }
  }

  /// Update polylines on the map based on current ride phase
  void _updatePolylines() {
    List<LatLng> points = [];

    // 1. Always start from driver's current location
    if (_isValidCoordinate(driverLatitude.value, driverLongitude.value)) {
      points.add(LatLng(driverLatitude.value, driverLongitude.value));
    }

    // 2. Use high-resolution route points from navigation data if available
    final navData = currentNavigationData.value;
    if (navData != null && navData.points != null && navData.points!.isNotEmpty) {
      points.addAll(navData.points!);
      print('✅ Map: Using ${navData.points!.length} high-res route points');
    } else {
      // Fallback to straight line if no high-res points available
      if (ridePhase.value == RidePhase.GOING_TO_PICKUP) {
        if (_isValidCoordinate(pickupLatitude.value, pickupLongitude.value)) {
          points.add(LatLng(pickupLatitude.value, pickupLongitude.value));
          }
      } else if (ridePhase.value == RidePhase.GOING_TO_DROPOFF ||
          ridePhase.value == RidePhase.WAITING_FOR_PASSENGER) {
        if (_isValidCoordinate(dropoffLatitude.value, dropoffLongitude.value)) {
          points.add(LatLng(dropoffLatitude.value, dropoffLongitude.value));
          }
      }
    }

    if (points.length >= 2) {
      polylines.assignAll({
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue[600]!,
          width: 8,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      });
      } else {
      polylines.clear();
      }
  }

  /// Automatically fit map to show all relevant markers (pickup, dropoff, driver)
  void autoFitMarkersOnMap() {
    if (_mapController == null || !isMapReady.value) {
      log('⚠️ Map controller not ready for auto-fit');
      return;
    }

    List<LatLng> allMarkerPositions = [];

    // Use navigation API coordinates if available, otherwise fall back to ride coordinates
    final navData = currentNavigationData.value;

    double? pickupLat, pickupLng, dropoffLat, dropoffLng;

    if (navData != null) {
      // Use coordinates from navigation API (most accurate)
      pickupLat = navData.originLatitude;
      pickupLng = navData.originLongitude;
      dropoffLat = navData.destinationLatitude;
      dropoffLng = navData.destinationLongitude;
      log('📍 Using navigation API coordinates for auto-fit');
    } else {
      // Fallback to ride coordinates if navigation data not available
      pickupLat = pickupLatitude.value != 0 ? pickupLatitude.value : null;
      pickupLng = pickupLongitude.value != 0 ? pickupLongitude.value : null;
      dropoffLat = dropoffLatitude.value != 0 ? dropoffLatitude.value : null;
      dropoffLng = dropoffLongitude.value != 0 ? dropoffLongitude.value : null;
      log('📍 Using fallback ride coordinates for auto-fit');
    }

    // Add pickup location if available
    if (pickupLat != null && pickupLng != null) {
      allMarkerPositions.add(LatLng(pickupLat, pickupLng));
      log('📍 Added pickup location to auto-fit: ($pickupLat, $pickupLng)');
    }

    // Add dropoff location if available
    if (dropoffLat != null && dropoffLng != null) {
      allMarkerPositions.add(LatLng(dropoffLat, dropoffLng));
      log('📍 Added dropoff location to auto-fit: ($dropoffLat, $dropoffLng)');
    }

    // Add driver location if available
    if (_isValidCoordinate(driverLatitude.value, driverLongitude.value)) {
      allMarkerPositions.add(
        LatLng(driverLatitude.value, driverLongitude.value),
      );
      log(
        '📍 Added driver location to auto-fit: (${driverLatitude.value}, ${driverLongitude.value})',
      );
    }

    if (allMarkerPositions.isEmpty) {
      log('⚠️ No valid marker positions for auto-fit');
      return;
    }

    if (allMarkerPositions.length == 1) {
      // Single marker - center on it with appropriate zoom
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(allMarkerPositions.first, 16.0),
      );
      log('📍 Centered map on single marker at ${allMarkerPositions.first}');
    } else {
      // Multiple markers - fit bounds to show all
      _fitMapToBounds(allMarkerPositions);
    }
  }

  /// Fit map camera to show all provided points with appropriate padding
  void _fitMapToBounds(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;

    try {
      // Calculate bounds
      double minLat = points
          .map((p) => p.latitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLat = points
          .map((p) => p.latitude)
          .reduce((a, b) => a > b ? a : b);
      double minLng = points
          .map((p) => p.longitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLng = points
          .map((p) => p.longitude)
          .reduce((a, b) => a > b ? a : b);

      // Add padding to ensure markers aren't at the edge
      double latPadding = (maxLat - minLat) * 0.2; // 20% padding
      double lngPadding = (maxLng - minLng) * 0.2; // 20% padding

      // Ensure minimum padding for very close markers
      latPadding = latPadding < 0.005 ? 0.005 : latPadding; // ~500m minimum
      lngPadding = lngPadding < 0.005 ? 0.005 : lngPadding; // ~500m minimum

      final bounds = LatLngBounds(
        southwest: LatLng(minLat - latPadding, minLng - lngPadding),
        northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      );

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80.0), // 80px screen padding
      );

      log(
        '📍 Map fitted to bounds: SW(${bounds.southwest}), NE(${bounds.northeast})',
      );

      // Show success feedback to user
      // Get.snackbar(
      //   'Map Updated',
      //   'Showing ${points.length} locations on map',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green[600],
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 2),
      //   icon: const Icon(Icons.map, color: Colors.white),
      //   margin: const EdgeInsets.all(8),
      // );
    } catch (e) {
      log('❌ Error fitting map to bounds: $e');
      // Fallback to center on first point
      if (points.isNotEmpty) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15.0),
        );
      }
    }
  }

  // Center map on current target (pickup or dropoff based on ride phase)
  void centerMapOnTarget() {
    if (_mapController == null) return;

    LatLng? target;

    if (ridePhase.value == RidePhase.GOING_TO_PICKUP) {
      if (pickupLatitude.value != 0 && pickupLongitude.value != 0) {
        target = LatLng(pickupLatitude.value, pickupLongitude.value);
      }
    } else if (ridePhase.value == RidePhase.GOING_TO_DROPOFF ||
        ridePhase.value == RidePhase.WAITING_FOR_PASSENGER) {
      if (dropoffLatitude.value != 0 && dropoffLongitude.value != 0) {
        target = LatLng(dropoffLatitude.value, dropoffLongitude.value);
      }
    }

    if (target != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 16.0));
    }
  }

  // Center map on driver's current location
  void centerMapOnDriver() {
    if (_mapController == null) return;

    if (driverLatitude.value != 0 && driverLongitude.value != 0) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(driverLatitude.value, driverLongitude.value),
          16.0,
        ),
      );
    }
  }

  Future<void> _initializeRide() async {
    try {
      log('🚀 Initializing ride data...');
      // Get ride data from arguments passed during navigation
      final rideData = Get.arguments;
      if (rideData != null && rideData is Ride) {
        currentRide.value = rideData;
        _syncPhaseWithStatus(); // Sync phase with ride status
        _extractPassengerInfo();
        await _parseLocationCoordinates();
        _startLocationTracking();
        _startRideTimer();
        // Start navigation updates automatically
        _startNavigationUpdates();
        log('🚗 Ongoing ride initialized for ride: ${currentRide.value!.id}');
      } else {
        // If no ride data passed, try to fetch from API
        log('ℹ️ No ride data in arguments, fetching from API...');
        await _fetchOngoingRideFromAPI();
      }
    } catch (e, stack) {
      log('❌ Exception in _initializeRide: $e');
      log('Stack trace: $stack');
      hasError.value = true;
      errorMessage.value = 'Failed to initialize ride: $e';
    }
  }

  void _syncPhaseWithStatus() {
    if (currentRide.value == null) return;
    
    final status = currentRide.value!.status.toLowerCase();
    log('🔄 Syncing phase with status: $status');
    
    if (status == 'ongoing' || status == 'started') {
      ridePhase.value = RidePhase.GOING_TO_DROPOFF;
    } else if (status == 'arrived') {
      ridePhase.value = RidePhase.WAITING_FOR_PASSENGER;
    } else if (status == 'payment_pending') {
      ridePhase.value = RidePhase.PAYMENT_PENDING;
    } else if (status == 'completed' || status == 'finished') {
      ridePhase.value = RidePhase.COMPLETED;
    } else {
      ridePhase.value = RidePhase.GOING_TO_PICKUP;
    }
    
    log('✅ Set initial phase to: ${ridePhase.value}');
  }

  void _extractPassengerInfo() {
  if (currentRide.value != null) {
    final ride = currentRide.value!;
    
    // Use passenger data from the parsed Ride object
    if (ride.passengerName != null && ride.passengerName!.isNotEmpty) {
      passengerName.value = ride.passengerName!;
      log('✅ Passenger name found: ${passengerName.value}');
    } else {
      // Fallback to generated name
      final riderId = ride.riderId;
      final riderIdSuffix = riderId.length >= 6
          ? riderId.substring(0, 6)
          : riderId;
      passengerName.value = 'Passenger $riderIdSuffix';
      log('⚠️ No passenger name, using fallback: ${passengerName.value}');
    }
    
    if (ride.passengerPhone != null && ride.passengerPhone!.isNotEmpty) {
      passengerPhone.value = ride.passengerPhone!;
      log('✅ Passenger phone found: ${passengerPhone.value}');
    } else {
      passengerPhone.value = '';
      log('⚠️ No passenger phone number available');
    }
    
    log('👤 Final Passenger Info:');
    log('   Name: ${passengerName.value}');
    log('   Phone: ${passengerPhone.value.isEmpty ? "Not available" : passengerPhone.value}');
  }
}

  // Fetch ongoing ride from API
  Future<void> _fetchOngoingRideFromAPI() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await _ridesApiService.getOngoingRide();
      print('📡 Raw API Response: ${jsonEncode(response)}');
      if (response['success'] == true && response['ride'] != null) {
         log('🚗 Ride data: ${json.encode(response['ride'])}');
        currentRide.value = response['ride'] as Ride;
        _syncPhaseWithStatus(); // Sync phase after fetching from API
        _extractPassengerInfo();
        await _parseLocationCoordinates();
        _startLocationTracking();
        _startRideTimer();
        log('🚗 Ongoing ride fetched from API: ${currentRide.value!.id}');
      } else {
        hasError.value = true;
        errorMessage.value = response['message'] ?? 'No ongoing ride found';
        log('⚠️ No ongoing ride found via API: ${response['message']}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to fetch ongoing ride: $e';
      log('❌ Error fetching ongoing ride: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _parseLocationCoordinates() async {
    if (currentRide.value != null) {
      log('🔍 Parsing location coordinates from ride data...');
      log('📍 Pickup: ${currentRide.value!.pickupLocation}');
      log('��� Dropoff: ${currentRide.value!.dropoffLocation}');

      // Log initial coordinate values from ride data
      print(
        '🔍 Initial pickup coordinates from ride: (${currentRide.value!.pickupLatitude}, ${currentRide.value!.pickupLongitude})',
      );
      print(
        '🔍 Initial dropoff coordinates from ride: (${currentRide.value!.dropoffLatitude}, ${currentRide.value!.dropoffLongitude})',
      );

      // Enhanced coordinate parsing with better validation and fallbacks
      bool pickupCoordinatesSet = false;
      bool dropoffCoordinatesSet = false;

      // Show loading notification for geocoding process
      // Get.snackbar(
      //   'Location Processing',
      //   'Converting passenger addresses to map coordinates...',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.blue[600],
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 3),
      //   icon: const Icon(Icons.location_searching, color: Colors.white),
      //   margin: const EdgeInsets.all(8),
      // );

      // First priority: Use coordinates directly from the ride data if available and valid
      if (currentRide.value!.pickupLatitude != null &&
          currentRide.value!.pickupLongitude != null &&
          _isValidCoordinate(
            currentRide.value!.pickupLatitude!,
            currentRide.value!.pickupLongitude!,
          )) {
        pickupLatitude.value = currentRide.value!.pickupLatitude!;
        pickupLongitude.value = currentRide.value!.pickupLongitude!;
        pickupCoordinatesSet = true;
        log(
          '✅ Using valid ride data pickup coordinates: (${pickupLatitude.value}, ${pickupLongitude.value})',
        );
      }

      if (currentRide.value!.dropoffLatitude != null &&
          currentRide.value!.dropoffLongitude != null &&
          _isValidCoordinate(
            currentRide.value!.dropoffLatitude!,
            currentRide.value!.dropoffLongitude!,
          )) {
        dropoffLatitude.value = currentRide.value!.dropoffLatitude!;
        dropoffLongitude.value = currentRide.value!.dropoffLongitude!;
        dropoffCoordinatesSet = true;
        log(
          '✅ Using valid ride data dropoff coordinates: (${dropoffLatitude.value}, ${dropoffLongitude.value})',
        );
      }

      // Second priority: Extract coordinates from location strings if API coordinates are missing
      if (!pickupCoordinatesSet) {
        log(
          '⚠️ Pickup coordinates missing or invalid, attempting extraction from string...',
        );
        log(
          '🔍 Extracting from pickup location string: "${currentRide.value!.pickupLocation}"',
        );
        final pickupResult = GeocodingService.extractCoordinatesFromString(
          currentRide.value!.pickupLocation,
        );
        if (pickupResult['lat'] != null && pickupResult['lng'] != null) {
          pickupLatitude.value = pickupResult['lat']!;
          pickupLongitude.value = pickupResult['lng']!;
          pickupCoordinatesSet = true;
          log(
            '✅ Extracted pickup coordinates from string: (${pickupLatitude.value}, ${pickupLongitude.value})',
          );
        } else {
          log(
            '❌ No coordinates found in pickup string: "${currentRide.value!.pickupLocation}"',
          );
        }
      }

      if (!dropoffCoordinatesSet) {
        log(
          '⚠️ Dropoff coordinates missing or invalid, attempting extraction from string...',
        );
        log(
          '🔍 Extracting from dropoff location string: "${currentRide.value!.dropoffLocation}"',
        );
        final dropoffResult = GeocodingService.extractCoordinatesFromString(
          currentRide.value!.dropoffLocation,
        );
        if (dropoffResult['lat'] != null && dropoffResult['lng'] != null) {
          dropoffLatitude.value = dropoffResult['lat']!;
          dropoffLongitude.value = dropoffResult['lng']!;
          dropoffCoordinatesSet = true;
          log(
            '✅ Extracted dropoff coordinates from string: (${dropoffLatitude.value}, ${dropoffLongitude.value})',
          );
        } else {
          log(
            '❌ No coordinates found in dropoff string: "${currentRide.value!.dropoffLocation}"',
          );
        }
      }

      // Third priority: Use enhanced geocoding service API to convert addresses to coordinates
      if (!pickupCoordinatesSet) {
        log(
          '🌐 No coordinates found in pickup string, using enhanced geocoding API...',
        );
        log(
          '🔍 Geocoding pickup address: "${currentRide.value!.pickupLocation}"',
        );
        await _geocodePickupLocation();
        pickupCoordinatesSet = _isValidCoordinate(
          pickupLatitude.value,
          pickupLongitude.value,
        );

        if (pickupCoordinatesSet) {
          log(
            '✅ Successfully geocoded pickup location: (${pickupLatitude.value}, ${pickupLongitude.value})',
          );
          showSuccessSnackBar(
            'Successfully found coordinates for: ${currentRide.value!.pickupLocation}',
            title: 'Pickup Location Found',
          );
        } else {
          log(
            '❌ Failed to geocode pickup location: "${currentRide.value!.pickupLocation}"',
          );
        }
      }

      if (!dropoffCoordinatesSet) {
        log(
          '🌐 No coordinates found in dropoff string, using enhanced geocoding API...',
        );
        log(
          '🔍 Geocoding dropoff address: "${currentRide.value!.dropoffLocation}"',
        );
        await _geocodeDropoffLocation();
        dropoffCoordinatesSet = _isValidCoordinate(
          dropoffLatitude.value,
          dropoffLongitude.value,
        );

        if (dropoffCoordinatesSet) {
          log(
            '✅ Successfully geocoded dropoff location: (${dropoffLatitude.value}, ${dropoffLongitude.value})',
          );
          showSuccessSnackBar(
            'Successfully found coordinates for: ${currentRide.value!.dropoffLocation}',
            title: 'Dropoff Location Found',
          );
        } else {
          log(
            '❌ Failed to geocode dropoff location: "${currentRide.value!.dropoffLocation}"',
          );
        }
      }

      // Final fallback: Use realistic Delhi coordinates based on address content
      if (!pickupCoordinatesSet) {
        log(
          '❌ All pickup geocoding methods failed, generating realistic coordinates...',
        );
        _setDefaultPickupCoordinates();
        pickupCoordinatesSet = true;
      }

      if (!dropoffCoordinatesSet) {
        log(
          '❌ All dropoff geocoding methods failed, generating realistic coordinates...',
        );
        _setDefaultDropoffCoordinates();
        dropoffCoordinatesSet = true;
      }

      // Log final coordinates and validation
      log(
        '📍 Final Pickup coordinates: (${pickupLatitude.value}, ${pickupLongitude.value}) - Valid: ${_isValidCoordinate(pickupLatitude.value, pickupLongitude.value)}',
      );
      log(
        '📍 Final Dropoff coordinates: (${dropoffLatitude.value}, ${dropoffLongitude.value}) - Valid: ${_isValidCoordinate(dropoffLatitude.value, dropoffLongitude.value)}',
      );

      // Show appropriate success/warning notification
      if (pickupCoordinatesSet && dropoffCoordinatesSet) {
        showSuccessSnackBar(
          'Pickup and dropoff locations successfully loaded on map',
          title: 'Locations Ready',
        );
      } else {
        showWarningSnackBar(
          'Some coordinates were estimated. Please verify locations on the map.',
          title: 'Location Warning',
        );
      }

      // Force update map markers and camera after coordinates are set
      await Future.delayed(const Duration(milliseconds: 500));
      if (isMapReady.value) {
        log('🗺️ Updating map with geocoded coordinates...');
        _updateMapMarkers();
        autoFitMarkersOnMap();
      } else {
        log('⚠️ Map not ready yet, will update when ready');
      }
    }
  }

  /// Validate if coordinates are within realistic bounds
  bool _isValidCoordinate(double lat, double lng) {
    return lat != 0.0 &&
        lng != 0.0 &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  Future<void> _geocodePickupLocation() async {
    if (currentRide.value?.pickupLocation == null ||
        currentRide.value!.pickupLocation.isEmpty) {
      return;
    }

    try {
      log(
        '🔍 Enhanced geocoding for pickup location: ${currentRide.value!.pickupLocation}',
      );

      // Use enhanced geocoding service for better accuracy
      final coords = await EnhancedGeocodingService.getCoordinatesFromAddress(
        currentRide.value!.pickupLocation,
      );

      if (coords['lat'] != null && coords['lng'] != null) {
        pickupLatitude.value = coords['lat']!;
        pickupLongitude.value = coords['lng']!;
        log(
          '✅ Enhanced geocoding successful for pickup: (${pickupLatitude.value}, ${pickupLongitude.value})',
        );
      } else {
        // Fallback to original geocoding service
        log('⚠️ Enhanced geocoding failed, trying original service...');
        final fallbackCoords = await GeocodingService.getCoordinatesFromAddress(
          currentRide.value!.pickupLocation,
        );

        if (fallbackCoords['lat'] != null && fallbackCoords['lng'] != null) {
          pickupLatitude.value = fallbackCoords['lat']!;
          pickupLongitude.value = fallbackCoords['lng']!;
          log(
            '✅ Fallback geocoding successful for pickup: (${pickupLatitude.value}, ${pickupLongitude.value})',
          );
        } else {
          // Final fallback to realistic coordinates based on address content
          log(
            '⚠️ All geocoding failed, using realistic coordinates based on address',
          );
          final realisticCoords =
              GeocodingService.generateRealisticDelhiCoordinates(
                currentRide.value!.pickupLocation,
                currentRide.value!.id,
              );
          pickupLatitude.value = realisticCoords['lat']!;
          pickupLongitude.value = realisticCoords['lng']!;
          log(
            '📍 Generated realistic pickup coordinates: (${pickupLatitude.value}, ${pickupLongitude.value})',
          );
        }
      }
    } catch (e) {
      log('❌ Error in enhanced geocoding for pickup location: $e');
      _setDefaultPickupCoordinates();
    }
  }

  Future<void> _geocodeDropoffLocation() async {
    if (currentRide.value?.dropoffLocation == null ||
        currentRide.value!.dropoffLocation.isEmpty) {
      return;
    }

    try {
      log(
        '🔍 Enhanced geocoding for dropoff location: ${currentRide.value!.dropoffLocation}',
      );

      // Use enhanced geocoding service for better accuracy
      final coords = await EnhancedGeocodingService.getCoordinatesFromAddress(
        currentRide.value!.dropoffLocation,
      );

      if (coords['lat'] != null && coords['lng'] != null) {
        dropoffLatitude.value = coords['lat']!;
        dropoffLongitude.value = coords['lng']!;
        log(
          '✅ Enhanced geocoding successful for dropoff: (${dropoffLatitude.value}, ${dropoffLongitude.value})',
        );
      } else {
        // Fallback to original geocoding service
        log('⚠️ Enhanced geocoding failed, trying original service...');
        final fallbackCoords = await GeocodingService.getCoordinatesFromAddress(
          currentRide.value!.dropoffLocation,
        );

        if (fallbackCoords['lat'] != null && fallbackCoords['lng'] != null) {
          dropoffLatitude.value = fallbackCoords['lat']!;
          dropoffLongitude.value = fallbackCoords['lng']!;
          log(
            '✅ Fallback geocoding successful for dropoff: (${dropoffLatitude.value}, ${dropoffLongitude.value})',
          );
        } else {
          // Final fallback to realistic coordinates based on address content
          log(
            '⚠️ All geocoding failed, using realistic coordinates based on address',
          );
          final realisticCoords =
              GeocodingService.generateRealisticDelhiCoordinates(
                currentRide.value!.dropoffLocation,
                currentRide.value!.riderId,
              );
          dropoffLatitude.value = realisticCoords['lat']!;
          dropoffLongitude.value = realisticCoords['lng']!;
          log(
            '📍 Generated realistic dropoff coordinates: (${dropoffLatitude.value}, ${dropoffLongitude.value})',
          );
        }
      }
    } catch (e) {
      log('❌ Error in enhanced geocoding for dropoff location: $e');
      _setDefaultDropoffCoordinates();
    }
  }

  void _setDefaultPickupCoordinates() {
    // Default to Delhi area with slight variation based on ride ID
    final hash = currentRide.value?.id.hashCode ?? 0;
    pickupLatitude.value = 28.6139 + (0.003 * ((hash % 100 - 50) / 100));
    pickupLongitude.value = 77.2090 + (0.003 * ((hash % 100 - 50) / 100));
    log(
      '📍 Using default pickup coordinates: (${pickupLatitude.value}, ${pickupLongitude.value})',
    );
  }

  void _setDefaultDropoffCoordinates() {
    // Default to Delhi area with slight variation based on rider ID
    final hash = currentRide.value?.riderId.hashCode ?? 0;
    dropoffLatitude.value = 28.6448 + (0.003 * ((hash % 100 - 50) / 100));
    dropoffLongitude.value = 77.2167 + (0.003 * ((hash % 100 - 50) / 100));
    log(
      '📍 Using default dropoff coordinates: (${dropoffLatitude.value}, ${dropoffLongitude.value})',
    );
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateDriverLocation(position);
          },
          onError: (error) {
            log('❌ Location tracking error: $error');
          },
        );

    // Also start a timer for periodic updates
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateDistancesAndStatus(),
    );
  }

  void _updateDriverLocation(Position position) {
    driverLatitude.value = position.latitude;
    driverLongitude.value = position.longitude;
    _updateDistancesAndStatus();

    // Update map markers when location changes
    if (isMapReady.value) {
      _updateMapMarkers();
      update(['map_view']); // Ensure map updates
    }

    // Auto-detect location every 2 minutes when driver moves
    if (!isAutoDetecting.value && !isAutoDetectionDataFresh) {
      autoDetectCurrentLocation();
    }
  }

  void _updateDistancesAndStatus() {
    if (driverLatitude.value != 0 && driverLongitude.value != 0) {
      // Calculate distances
      if (ridePhase.value == RidePhase.GOING_TO_PICKUP) {
        distanceToPickup.value =
            Geolocator.distanceBetween(
              driverLatitude.value,
              driverLongitude.value,
              pickupLatitude.value,
              pickupLongitude.value,
            ) /
            1000; // Convert to kilometers

        // Check if reached pickup (within 0 meters);
        if (distanceToPickup.value <= 0.00) {
          _reachedPickup();
        }
      } else if (ridePhase.value == RidePhase.GOING_TO_DROPOFF) {
        distanceToDropoff.value =
            Geolocator.distanceBetween(
              driverLatitude.value,
              driverLongitude.value,
              dropoffLatitude.value,
              dropoffLongitude.value,
            ) /
            1000; // Convert to kilometers

        // Check if reached dropoff (within 0 meters)
        if (distanceToDropoff.value <= 0.00) {
          _reachedDropoff();
        }
      }

      // Estimate duration (assuming average speed of 25 km/h in city)
      double distance = ridePhase.value == RidePhase.GOING_TO_PICKUP
          ? distanceToPickup.value
          : distanceToDropoff.value;
      estimatedDuration.value = (distance / 25 * 60).round(); // in minutes

      // Ensure minimum 1 minute
      if (estimatedDuration.value < 1) estimatedDuration.value = 1;
    }
  }

  void _reachedPickup() {
    if (!hasReachedPickup.value) {
      hasReachedPickup.value = true;
      ridePhase.value = RidePhase.WAITING_FOR_PASSENGER;
      showSuccessSnackBar(
        'You have arrived at the pickup location. Please wait for the passenger.',
        title: 'Pickup Location Reached',
      );
    }
  }

  void _reachedDropoff() {
    if (!hasReachedDropoff.value) {
      hasReachedDropoff.value = true;
      canCompleteRide.value = true;
      showSuccessSnackBar(
        'You have arrived at the destination. Tap "Complete Ride" to finish.',
        title: 'Destination Reached',
      );
    }
  }

  /// Start ride with OTP verification using the API
  Future<bool> startRideWithOtp(String otp) async {
    try {
      // If no current ride, try to fetch from API first
      if (currentRide.value == null || currentRide.value!.id.isEmpty) {
        log('⚠️ No current ride found, attempting to fetch from API...');
        await _fetchOngoingRideFromAPI();

        // Check again after API fetch
        if (currentRide.value == null || currentRide.value!.id.isEmpty) {
          log('❌ Still no current ride available after API fetch');
          showErrorSnackBar(
            'No ongoing ride found. Please check your ride status.',
            title: 'Error',
          );
          return false;
        }
      }

      log('🚀 Starting ride with OTP verification...');
      log('🔢 Ride ID: ${currentRide.value!.id}');
      log('🔢 OTP: $otp');

      // Call the start ride API with OTP
      final response = await _ridesApiService.startRide(
        currentRide.value!.id,
        otp,
      );

      if (response['success'] == true) {
        log('✅ Ride started successfully via API');

        // Update the local ride state
        ridePhase.value = RidePhase.GOING_TO_DROPOFF;

        // Update the ride object if returned from API
        if (response['ride'] != null) {
          currentRide.value = response['ride'];
          log('📝 Updated ride object from API response');
        }

        // Re-parse location coordinates after ride update (CRITICAL: await this)
        await _parseLocationCoordinates();
        
        // Clear old navigation data immediately so user doesn't see "old" distance
        hasNavigationData.value = false;
        navigationDistance.value = '';
        navigationDuration.value = '';

        // Update map to show route to dropoff
        if (isMapReady.value) {
          refreshMapDisplay(); // Force a full map refresh
        }

        // Fetch fresh navigation data for dropoff route (Await this too)
        await fetchNavigationData();

        log('🎉 Ride transition to GOING_TO_DROPOFF completed');
        return true;
      } else {
        log('❌ API returned error: ${response['message']}');
        showErrorSnackBar(
          response['message'] ?? 'Unable to start ride. Please try again.',
          title: 'Verification Failed',
        );
        return false;
      }
    } catch (e) {
      log('❌ Exception during start ride: $e');
      showErrorSnackBar(
        'Failed to start ride. Please try again.',
        title: 'Error',
      );
      return false;
    }
  }

  void startRideToDropoff() {
    if (ridePhase.value == RidePhase.WAITING_FOR_PASSENGER && currentRide.value != null) {
      log('🚀 Starting ride to dropoff via API...');
      startRideWithOtp(currentRide.value!.otp);
    } else {
      log('⚠️ Cannot start ride: phase is ${ridePhase.value} and ride is ${currentRide.value == null ? "null" : "not null"}');
    }
  }

  void _startRideTimer() {
    _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime.value++;
    });
  }

  /// Stop the ride timer
  void stopRideTimer() {
    _rideTimer?.cancel();
    _rideTimer = null;
    log('⏹️ Ride timer stopped');
  }

  String get formattedElapsedTime {
    int hours = elapsedTime.value ~/ 3600;
    int minutes = (elapsedTime.value % 3600) ~/ 60;
    int seconds = elapsedTime.value % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> completeRide() async {
    try {
      isLoading.value = true;

      // Make API call to complete the ride
      final response = await _ridesApiService.completeRide(
        currentRide.value!.id,
      );

      if (response['success'] == true) {
        ridePhase.value = RidePhase.COMPLETED;

        showSuccessSnackBar(
          'Ride has been completed successfully!',
          title: 'Ride Completed',
        );
        // Show rider rating bottom sheet immediately after successful completion
        await Future.delayed(const Duration(seconds: 1));
        // _showRiderRatingBottomSheet();
        Get.offAllNamed('/');
      } else {
        showErrorSnackBar(
          response['message'] ?? 'Failed to complete ride',
          title: 'Error',
        );
      }
    } catch (e) {
      log('❌ Error completing ride: $e');
      showErrorSnackBar(
        'Network error occurred. Please try again.',
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete ride with payment method - calls API with payment information
  /// Complete ride with payment method - calls API with payment information
// In ongoing_ride_controller.dart

/// Complete ride with payment method - calls API with payment information
/// Complete ride with payment method - calls API with payment information
Future<Map<String, dynamic>> completeRideWithPayment(
  String paymentMethod,
) async {
  try {
    if (currentRide.value == null) {
      return {'success': false, 'message': 'No active ride found'};
    }

    print('💳 [CONTROLLER] Starting payment flow: $paymentMethod');
    print('💳 [CONTROLLER] Ride ID: ${currentRide.value!.id}');
    
    // ✅ Call API and get COMPLETE response - DON'T MODIFY IT
    final response = await _ridesApiService.completeRideWithPayment(
      currentRide.value!.id,
      paymentMethod,
    );

    print('📡 [CONTROLLER] API returned success: ${response['success']}');
    print('📡 [CONTROLLER] Response keys: ${response.keys.toList()}');
    print('📡 [CONTROLLER] Has qrCode: ${response.containsKey('qrCode')}');
    print('📡 [CONTROLLER] Has paymentLinkId: ${response.containsKey('paymentLinkId')}');
    
    if (response['success'] == true) {
      if (paymentMethod == 'cash') {
        // Only update state for cash payment
        ridePhase.value = RidePhase.COMPLETED;
        _stopLocationTracking();
        _stopNavigationUpdates();
        _rideTimer?.cancel();
        print('✅ [CONTROLLER] Cash payment - ride completed');
      } else {
        print('💳 [CONTROLLER] Online payment - preserving all data');
      }
    }
    
    // ✅ CRITICAL: Return the EXACT response from API without modification
    print('📤 [CONTROLLER] Returning response with ${response.keys.length} keys');
    return response;

  } catch (e) {
    print('❌ [CONTROLLER] Error: $e');
    return {
      'success': false,
      'message': 'Network error occurred: $e'
    };
  }
}
  /// Verify payment status for online payments
  Future<Map<String, dynamic>> verifyPaymentStatus(String orderId) async {
    try {
      log('🔍 Verifying payment status for order: $orderId');

      // Call the API to verify payment
      final response = await _ridesApiService.verifyPaymentStatus(
        currentRide.value!.id,
        orderId,
      );

      return response;
    } catch (e) {
      log('❌ Error verifying payment status: $e');
      return {
        'success': false,
        'message': 'Network error occurred while verifying payment',
      };
    }
  }

  /// Force complete ride - statically complete the ride regardless of API response
  Future<void> cancelOngoingRide(String reason) async {
    try {
      final rideId = currentRide.value?.id;
      if (rideId == null) {
        showErrorSnackBar('No active ride to cancel');
        return;
      }

      isLoading.value = true;
      log('🚫 Cancelling ride: $rideId for reason: $reason');

      final result = await RidesApiService().cancelRide(rideId, reason: reason);

      if (result['success']) {
        showSuccessSnackBar('Ride has been cancelled successfully');
        
        // Stop all tracking and timers
        _stopLocationTracking();
        _stopNavigationUpdates();
        _rideTimer?.cancel();
        
        // Return to home screen
        Get.offAllNamed('/home');
      } else {
        showErrorSnackBar(result['message'] ?? 'Failed to cancel ride');
      }
    } catch (e) {
      log('❌ Error cancelling ongoing ride: $e');
      showErrorSnackBar('An error occurred while cancelling the ride');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forceCompleteRide() async {
    try {
      isLoading.value = true;

      log('🏁 Force completing ride: ${currentRide.value?.id}');

      // Show immediate success feedback
      showSuccessSnackBar(
        'Ride has been forcefully completed successfully!',
        title: 'Ride Completed',
      );

      // Force update ride state to completed
      ridePhase.value = RidePhase.COMPLETED;
      canCompleteRide.value = false;
      hasReachedDropoff.value = true;

      // Stop all location tracking and timers
      _stopLocationTracking();
      _stopNavigationUpdates();
      _rideTimer?.cancel();

      // Try to call API in background but don't wait for response
      _attemptApiCompleteRide();

      // Force navigate back to home after a short delay
      await Future.delayed(const Duration(seconds: 2));

      log('🏁 Ride forcefully completed, navigating to home');
      Get.offAllNamed('/');
    } catch (e) {
      log('❌ Error in force complete ride: $e');

      // Even if there's an error, still complete the ride locally
      ridePhase.value = RidePhase.COMPLETED;

      showWarningSnackBar(
        'Ride completed locally. Network sync will happen in background.',
        title: 'Ride Completed',
      );

      // Still navigate to home
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed('/');
    } finally {
      isLoading.value = false;
    }
  }

  /// Attempt to complete ride via API in background (non-blocking)
  void _attemptApiCompleteRide() async {
    try {
      if (currentRide.value?.id != null) {
        log(
          '🔄 Attempting background API call to complete ride: ${currentRide.value!.id}',
        );

        final response = await _ridesApiService.completeRide(
          currentRide.value!.id,
        );

        if (response['success'] == true) {
          log('✅ Background API call successful - ride completed on server');
        } else {
          log('⚠️ Background API call failed: ${response['message']}');
        }
      }
    } catch (e) {
      log('❌ Background API call error: $e');
      // Don't show error to user since ride is already completed locally
    }
  }

  Future<void> generatePaymentQR() async {
    if (currentRide.value == null) return;
    
    try {
      isLoading.value = true;
      isGeneratingQR.value = true;
      
      log('💳 Requesting payment link for ride: ${currentRide.value!.id}');
      
      final response = await _ridesApiService.createPaymentLink(currentRide.value!.id);
      
      log('📡 API Response: $response');
      
      if (response['success'] == true) {
        qrCodeBase64.value = response['qrCode'] ?? '';
        paymentLink.value = response['paymentLink'] ?? '';
        paymentAmount.value = response['amount'] ?? 0;
        paymentCurrency.value = response['currency'] ?? 'INR';
        
        // Change phase to payment pending to show QR UI context
        ridePhase.value = RidePhase.PAYMENT_PENDING;
        
        log('✅ Payment QR generated successfully');
        
        // Show the Payment QR Screen
        if (qrCodeBase64.value.isNotEmpty) {
           Get.to(
            () => PaymentQRScreen(
              qrCode: qrCodeBase64.value,
              orderId: (response['paymentLinkId'] ?? response['orderId'] ?? 'unknown').toString(),
              rideId: currentRide.value!.id,
              amount: paymentAmount.value,
              currency: paymentCurrency.value,
            ),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        } else {
           showErrorSnackBar(
             'QR code data is empty',
             title: 'Payment Error',
           );
        }
      } else {
        showErrorSnackBar(
          response['message'] ?? 'Failed to generate payment QR',
          title: 'Payment Error',
        );
      }
    } catch (e) {
      log('❌ Exception generating payment QR: $e');
      showErrorSnackBar(
        'Network error while generating payment QR',
        title: 'Error',
      );
    } finally {
      isGeneratingQR.value = false;
      isLoading.value = false;
    }
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    isTrackingDriverLocation.value = false;
    log('🛑 Location tracking stopped');
  }

  /// Fetch navigation data based on current ride phase
  Future<void> fetchNavigationData() async {
    print('🗺️ fetchNavigationData() started for phase: ${ridePhase.value}');
    
    // Clear any previous errors or stale data states
    isLoadingNavigation.value = true;
    hasNavigationError.value = false;
    // 1. Determine origin (prefer driver's current location)
    String originLocation;
    if (driverLatitude.value != 0 && driverLongitude.value != 0) {
      originLocation = '${driverLatitude.value},${driverLongitude.value}';
      print('🗺️ Origin location set from driver position: $originLocation');
    } else {
      // Fallback: If driver location not yet available, we can't do live navigation
      print('⚠️ Cannot fetch live navigation - driver location not available (lat=${driverLatitude.value}, lng=${driverLongitude.value})');
      return;
    }

    // 2. Determine destination based on ride phase
    String destinationLocation;
    String destinationType;

    if (ridePhase.value == RidePhase.GOING_TO_PICKUP) {
      print('🗺️ Phase: GOING_TO_PICKUP. Pickup coords: ${pickupLatitude.value}, ${pickupLongitude.value}');
      if (pickupLatitude.value == 0 || pickupLongitude.value == 0) {
        print('⚠️ Cannot fetch navigation - pickup coordinates not available');
        return;
      }
      destinationLocation = '${pickupLatitude.value},${pickupLongitude.value}';
      destinationType = 'Pickup';
    } else if (ridePhase.value == RidePhase.GOING_TO_DROPOFF || 
               ridePhase.value == RidePhase.WAITING_FOR_PASSENGER) {
      print('🗺️ Phase: ${ridePhase.value}. Dropoff coords: ${dropoffLatitude.value}, ${dropoffLongitude.value}');
      if (dropoffLatitude.value == 0 || dropoffLongitude.value == 0) {
        print('⚠️ Cannot fetch navigation - dropoff coordinates not available');
        return;
      }
      destinationLocation = '${dropoffLatitude.value},${dropoffLongitude.value}';
      destinationType = 'Dropoff';
    } else {
      log('ℹ️ Navigation not needed for current phase: ${ridePhase.value}');
      return;
    }

    try {
      isLoadingNavigation.value = true;
      hasNavigationError.value = false;
      navigationError.value = '';

      final String? id = currentRide.value?.id;
      if (id == null) {
        print('⚠️ Cannot fetch navigation - ride ID is null');
        return;
      }

      print('🗺️ ===== NAVIGATION API REQUEST (LIVE) =====');
      print('🗺️ Ride ID: $id');
      print('🗺️ Target: $destinationType');
      
      // Determine if we should prioritize dropoff navigation
      final bool isToDropoff = ridePhase.value == RidePhase.GOING_TO_DROPOFF || 
                               ridePhase.value == RidePhase.WAITING_FOR_PASSENGER;

      // Use the ride-specific navigation API with phase awareness
      final response = await _navigationApiService.getRideNavigationData(
        id, 
        isToDropoff: isToDropoff,
      );

      print('🗺️ ===== NAVIGATION API RESPONSE =====');
      print('🗺️ API Response: $response');

      if (response['success'] == true) {
        final NavigationResponse navData = response['data'];
        currentNavigationData.value = navData;
        navigationDistance.value = navData.formattedDistance;
        navigationDuration.value = navData.formattedDuration;
        hasNavigationData.value = true;
        lastNavigationUpdate.value = DateTime.now();

        print('✅ Navigation data updated ($destinationType):');
        print('   Distance: ${navData.formattedDistance}');
        print('   Duration: ${navData.formattedDuration}');
        print('   Origin: ${navData.origin}');
        print('   Destination: ${navData.destination}');

        // Immediately update polylines with new high-res points
        _updatePolylines();
        update(['map_view']); // Refresh UI

        /* 
        showSuccessSnackBar(
          'To $destinationType: ${navData.formattedDistance} in ${navData.formattedDuration}',
          title: 'Route Updated',
        );
        */
      } else {
        hasNavigationError.value = true;
        navigationError.value =
            response['message'] ?? 'Failed to fetch navigation data';
        log('❌ Navigation API error: ${navigationError.value}');

        // Show error feedback
        showErrorSnackBar(
          navigationError.value,
          title: 'Navigation Error',
        );
      }
    } catch (e) {
      hasNavigationError.value = true;
      navigationError.value = 'Network error occurred';
      log('❌ Exception fetching navigation data: $e');

      // Show network error feedback
      showErrorSnackBar(
        'Could not connect to navigation service. Please check your internet connection.',
        title: 'Connection Error',
      );
    } finally {
      isLoadingNavigation.value = false;
    }
  }

  /// Start periodic navigation updates
  void _startNavigationUpdates() {
    _stopNavigationUpdates(); // Stop any existing timer

    // Fetch initial navigation data after coordinates are available
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (pickupLatitude.value != 0 && dropoffLatitude.value != 0) {
        fetchNavigationData();
      }
    });

    // Set up periodic updates every 60 seconds (less frequent to avoid rate limiting)
    _navigationUpdateTimer = Timer.periodic(const Duration(seconds: 60), (
      timer,
    ) {
      if (ridePhase.value == RidePhase.GOING_TO_PICKUP ||
          ridePhase.value == RidePhase.GOING_TO_DROPOFF ||
          ridePhase.value == RidePhase.WAITING_FOR_PASSENGER) {
        if (pickupLatitude.value != 0 || dropoffLatitude.value != 0) {
          fetchNavigationData();
        }
      }
    });

    print('🔄 Started navigation updates every 60 seconds');
    
    // Call immediately for the first time
    if (pickupLatitude.value != 0 || dropoffLatitude.value != 0) {
      fetchNavigationData();
    }
  }

  /// Stop navigation updates
  void _stopNavigationUpdates() {
    _navigationUpdateTimer?.cancel();
    _navigationUpdateTimer = null;
    print('⏹️ Stopped navigation updates');
  }

  /// Enhanced Navigate button functionality with API integration
  Future<void> navigateWithAPI() async {
    try {
      print(
        '🗺️ Navigate button pressed - fetching route data and opening navigation',
      );

      // First, fetch fresh navigation data from API to get distance and duration
      await fetchNavigationData();

      // Show the navigation data to user if available
      if (hasNavigationData.value &&
          navigationDistance.value.isNotEmpty &&
          navigationDuration.value.isNotEmpty) {
        // Show route info before opening external navigation
        showSuccessSnackBar(
          'Distance: ${navigationDistance.value}\nEstimated Time: ${navigationDuration.value}',
          title: 'Trip Route Information',
        );

        // Wait a moment for user to see the route info
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      // Then open external navigation (Google Maps) to dropoff location
      await openGoogleMapsNavigation();
    } catch (e) {
      print('❌ Error in navigateWithAPI: $e');
      // Show error but still try to open basic navigation
      showWarningSnackBar(
        'Could not fetch route data, opening basic navigation',
        title: 'Navigation Error',
      );

      // Fallback to basic navigation if API fails
      await openGoogleMapsNavigation();
    }
  }

  /// Open Google Maps for navigation to dropoff location (always)
  Future<void> openGoogleMapsNavigation() async {
    try {
      // Always navigate to dropoff location as requested
      double targetLat = dropoffLatitude.value;
      double targetLng = dropoffLongitude.value;

      // Validate dropoff coordinates are available
      if (targetLat == 0.0 || targetLng == 0.0) {
        print('❌ Dropoff coordinates not available: $targetLat, $targetLng');
        showErrorSnackBar(
          'Dropoff location coordinates not available from backend',
          title: 'Navigation Error',
        );
        return;
      }

      print('🗺️ Opening navigation to dropoff: $targetLat, $targetLng');

      // Create Google Maps navigation URL with dropoff coordinates
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng&travelmode=driving',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        isNavigating.value = true;

        // Show confirmation that navigation opened
        showSuccessSnackBar(
          'Opening navigation to dropoff location',
          title: 'Navigation Started',
        );
      } else {
        // Fallback to web maps if Google Maps app not available
        final webMapsUrl = Uri.parse(
          'https://maps.google.com/?q=$targetLat,$targetLng',
        );
        await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
        isNavigating.value = true;
      }
    } catch (e) {
      print('❌ Error opening Google Maps navigation: $e');
      showErrorSnackBar(
        'Could not open navigation. Please check if Google Maps is installed.',
        title: 'Navigation Error',
      );
    }
  }

  /// Call passenger
  // Make sure this package is in your pubspec.yaml

  // NOTE: This function assumes 'passengerPhone' is an RxString property
  // within the GetX controller where this method resides.

  Future<void> callPassenger() async {
    try {
      // 1. Validation Check: If number is empty or contains the privacy placeholder
      if (passengerPhone.value.isEmpty ||
          passengerPhone.value.contains('XXXXX')) {
        showWarningSnackBar(
          'Passenger phone number is hidden for privacy. Cannot call.',
          title: 'Phone Not Available',
        );
        return;
      }

      // 2. Clean and Format Phone Number
      String phone = passengerPhone.value.trim();

      // Regex: Keep only digits and the leading '+' symbol.
      // This removes spaces, hyphens, and any other special characters.
      phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      // 3. Create tel URI
      final Uri telUri = Uri(scheme: 'tel', path: phone);

      print('📞 Attempting to launch: ${telUri.toString()}');

      // 4. Launch URL
      // We directly call launchUrl. If the device cannot handle the 'tel:' URI,
      // launchUrl returns false, and we handle that failure here.
      final bool launched = await launchUrl(
        telUri,
        // Using externalApplication mode is recommended for opening native apps like the dialer
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        log('✅ Phone dialer opened successfully for: $phone');
      } else {
        // Handle failure if launchUrl returns false
        log('❌ launchUrl returned false for: ${telUri.toString()}');
        showErrorSnackBar(
          'Cannot open the phone dialer. The phone app may not be available on this device.',
          title: 'Launch Failed',
        );
      }
    } catch (e, stackTrace) {
      // Catching any unexpected errors (e.g., system crash, permissions issue)
      print('❌ Critical Error during phone call attempt: $e');
      print('Stack trace: $stackTrace');

      showErrorSnackBar(
        'An unexpected error occurred. Please check app permissions.',
        title: 'Call Failed',
      );
    }
  }

  // /// Send message to passenger
  // Future<void> sendMessage() async {
  //   try {
  //     if (passengerPhone.value.isNotEmpty &&
  //         passengerPhone.value != '+91 XXXXX XXXXX') {
  //       final uri = Uri.parse('sms:${passengerPhone.value}');
  //       if (await canLaunchUrl(uri)) {
  //         await launchUrl(uri);
  //       } else {
  //         Get.snackbar(
  //           'Error',
  //           'Could not open messaging app',
  //           snackPosition: SnackPosition.BOTTOM,
  //           backgroundColor: Colors.red,
  //           colorText: Colors.white,
  //         );
  //       }
  //     } else {
  //       Get.snackbar(
  //         'Info',
  //         'Passenger phone number not available for privacy protection',
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.orange,
  //         colorText: Colors.white,
  //       );
  //     }
  //   } catch (e) {
  //     log('❌ Error opening messaging app: $e');
  //   }
  // }

  /// Get current distance text (using API data if available, fallback to calculated)
  String get currentDistanceText {
    // Prefer API navigation data if available and fresh
    if (hasNavigationData.value &&
        navigationDistance.value.isNotEmpty &&
        isNavigationDataFresh) {
      return navigationDistance.value;
    }

    // Fallback to calculated distance
    double distance = ridePhase.value == RidePhase.GOING_TO_PICKUP
        ? distanceToPickup.value
        : distanceToDropoff.value;

    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  /// Get current ETA text (using API data if available, fallback to calculated)
  String get currentETAText {
    // Prefer API navigation data if available and fresh
    if (hasNavigationData.value &&
        navigationDuration.value.isNotEmpty &&
        isNavigationDataFresh) {
      return navigationDuration.value;
    }

    // Fallback to calculated ETA
    return '${estimatedDuration.value} min';
  }

  /// Get navigation button state and text
  String get navigationButtonText {
    if (isLoadingNavigation.value) {
      return 'Getting Route...';
    }

    if (hasNavigationData.value && isNavigationDataFresh) {
      return 'Navigate (${navigationDistance.value})';
    }

    return 'Navigate';
  }

  /// Check if navigation button should show loading state
  bool get isNavigationButtonLoading {
    return isLoadingNavigation.value;
  }

  /// Get formatted navigation info for display
  String get navigationDisplayText {
    if (isLoadingNavigation.value) {
      return 'Calculating route...';
    }

    if (hasNavigationError.value) {
      return 'Navigation unavailable';
    }

    if (hasNavigationData.value &&
        navigationDistance.value.isNotEmpty &&
        navigationDuration.value.isNotEmpty) {
      return '${navigationDistance.value} • ${navigationDuration.value}';
    }

    return 'Tap to get directions';
  }

  /// Check if navigation data is fresh (updated within last 2 minutes)
  bool get isNavigationDataFresh {
    if (!hasNavigationData.value) return false;

    final timeDiff = DateTime.now().difference(lastNavigationUpdate.value);
    return timeDiff.inMinutes < 2;
  }

  /// Force refresh navigation data
  Future<void> refreshNavigationData() async {
    print('🔄 Force refreshing navigation data');
    await fetchNavigationData();
  }

  // Auto-Detection Location API Methods
  /// Auto-detect location based on current driver coordinates
  Future<void> autoDetectCurrentLocation() async {
    // First check if we have location controller integration
    try {
      _locationController = Get.find<LocationController>();
    } catch (e) {
      print('��️ LocationController not found, creating new instance');
      _locationController = Get.put(LocationController());
    }

    // Check if driver location is available
    if (driverLatitude.value == 0 || driverLongitude.value == 0) {
      print(
        '⚠️ Driver location not available for auto-detection, attempting to get current location',
      );

      // Try to get current location first
      bool locationObtained = await _getCurrentLocationForAutoDetection();

      if (!locationObtained) {
        showWarningSnackBar(
          'Please enable location services and grant permissions to auto-detect your address.',
          title: 'Location Unavailable',
        );
        return;
      }
    }

    try {
      isAutoDetecting.value = true;
      autoDetectionError.value = '';

      print(
        '📍 Auto-detecting location for coordinates: (${driverLatitude.value}, ${driverLongitude.value})',
      );

      final response = await _locationApiService.autoDetectLocation(
        driverLatitude.value,
        driverLongitude.value,
      );

      if (response['success'] == true) {
        autoDetectedAddress.value = response['address'] ?? 'Unknown location';
        hasAutoDetectedLocation.value = true;
        lastAutoDetectionUpdate.value = DateTime.now();

        print('✅ Auto-detection successful: ${autoDetectedAddress.value}');

        showSuccessSnackBar(
          autoDetectedAddress.value,
          title: 'Location Detected',
        );
      } else {
        autoDetectionError.value =
            response['message'] ?? 'Failed to auto-detect location';
        hasAutoDetectedLocation.value = false;

        print('❌ Auto-detection failed: ${autoDetectionError.value}');

        showErrorSnackBar(
          autoDetectionError.value,
          title: 'Auto-Detection Failed',
        );
      }
    } catch (e) {
      autoDetectionError.value = 'Network error: $e';
      hasAutoDetectedLocation.value = false;

      print('💥 Auto-detection exception: $e');

      showErrorSnackBar(
        'Could not connect to location service',
        title: 'Auto-Detection Error',
      );
    } finally {
      isAutoDetecting.value = false;
    }
  }

  /// Helper method to get current location when not available
  Future<bool> _getCurrentLocationForAutoDetection() async {
    try {
      print('🔍 Attempting to get current location for auto-detection');

      // Check location permissions first
      if (!_locationController.hasLocationPermission.value) {
        print('⚠️ Location permissions not granted, checking permissions');
        await _locationController.checkLocationPermissions();

        if (!_locationController.hasLocationPermission.value) {
          print('❌ Location permissions denied');
          return false;
        }
      }

      // Check if location services are enabled
      if (!_locationController.isLocationEnabled.value) {
        print('⚠️ Location services disabled');
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('❌ Location services are disabled on device');
          return false;
        }
        _locationController.isLocationEnabled.value = true;
      }

      // Try to get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        // Removed timeLimit to make location detection limitless - no timeout
      );

      // Update driver location
      driverLatitude.value = position.latitude;
      driverLongitude.value = position.longitude;

      print(
        '✅ Successfully obtained current location: (${driverLatitude.value}, ${driverLongitude.value})',
      );

      // Start location tracking if not already started
      if (_positionStreamSubscription == null) {
        print('🔄 Starting location tracking');
        _startLocationTracking();
      }

      return true;
    } catch (e) {
      print('❌ Error getting current location: $e');

      // Show specific error messages based on the error type
      if (e.toString().contains('Permission')) {
        showWarningSnackBar(
          'Location permission is required for auto-detection',
          title: 'Permission Required',
        );
      } else if (e.toString().contains('disabled')) {
        showWarningSnackBar(
          'Please enable location services in your device settings',
          title: 'Location Services Disabled',
        );
      } else {
        showErrorSnackBar(
          'Could not get current location. Please try again.',
          title: 'Location Error',
        );
      }

      return false;
    }
  }

  /// Get formatted auto-detected address for display
  String get autoDetectedLocationText {
    if (isAutoDetecting.value) {
      return 'Detecting location...';
    }

    if (autoDetectionError.value.isNotEmpty) {
      return 'Location detection failed';
    }

    if (hasAutoDetectedLocation.value && autoDetectedAddress.value.isNotEmpty) {
      return autoDetectedAddress.value;
    }

    return 'Tap to detect current location';
  }

  /// Check if auto-detection data is fresh (updated within last 5 minutes)
  bool get isAutoDetectionDataFresh {
    if (!hasAutoDetectedLocation.value) return false;

    final timeDiff = DateTime.now().difference(lastAutoDetectionUpdate.value);
    return timeDiff.inMinutes < 5;
  }

  /// Get auto-detection button state
  String get autoDetectionButtonText {
    if (isAutoDetecting.value) {
      return 'Detecting...';
    }

    if (hasAutoDetectedLocation.value && isAutoDetectionDataFresh) {
      return 'Update Location';
    }

    return 'Detect Location';
  }

  /// Check if auto-detection button should show loading state
  bool get isAutoDetectionButtonLoading {
    return isAutoDetecting.value;
  }

  /// Manual trigger for auto-detection (for UI button)
  Future<void> manualAutoDetectLocation() async {
    print('🔄 Manual auto-detection triggered');
    await _getCurrentDriverLocation();
  }

  /// Start enhanced driver location auto-detection
  void _startDriverLocationAutoDetection() async {
    if (isTrackingDriverLocation.value) return;

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        showWarningSnackBar(
          'Please enable location access to track your position on the map',
          title: 'Location Permission Required',
        );
        return;
      }

      isTrackingDriverLocation.value = true;
      log('🎯 Starting enhanced driver location auto-detection');

      // Get initial position immediately
      await _getCurrentDriverLocation();

      // Start continuous location tracking
      _startContinuousLocationTracking();
    } catch (e) {
      log('❌ Error starting driver location auto-detection: $e');
      isTrackingDriverLocation.value = false;
    }
  }

  /// Get current driver location with high accuracy
  Future<void> _getCurrentDriverLocation() async {
    try {
      isAutoDetecting.value = true;
      autoDetectionError.value = '';

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        // Removed timeLimit to make location detection limitless - no timeout
      );

      _updateDriverLocationWithPosition(position);

      // Reverse geocode to get address
      await _reverseGeocodeDriverLocation(position);

      lastAutoDetectionUpdate.value = DateTime.now();
      hasAutoDetectedLocation.value = true;

      log(
        '🎯 Driver location auto-detected: (${position.latitude}, ${position.longitude})',
      );

      // Get.snackbar(
      //   'Location Detected',
      //   'Your current location has been detected and marked on the map',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.blue[600],
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 3),
      //   icon: const Icon(Icons.my_location, color: Colors.white),
      // );
    } catch (e) {
      autoDetectionError.value = 'Failed to detect location: $e';
      log('❌ Error getting current driver location: $e');

      showErrorSnackBar(
        'Unable to detect your current location. Please check GPS settings.',
        title: 'Location Error',
      );
    } finally {
      isAutoDetecting.value = false;
    }
  }

  /// Update driver location with enhanced position data
  void _updateDriverLocationWithPosition(Position position) {
    driverLatitude.value = position.latitude;
    driverLongitude.value = position.longitude;
    driverLocationAccuracy.value = position.accuracy;
    driverHeading.value = position.heading;
    driverSpeed.value = position.speed * 3.6; // Convert m/s to km/h
    lastLocationUpdate.value = DateTime.now();

    // Update map display
    if (isMapReady.value) {
      _updateMapMarkersAndCircles();
    }

    // Update distances and navigation
    _updateDistancesAndStatus();
  }

  /// Start continuous location tracking with improved settings
  void _startContinuousLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // Update every 3 meters for smoother tracking
      // Removed timeLimit to make it truly continuous and limitless
    );

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateDriverLocationWithPosition(position);

            // Auto-reverse geocode every 30 seconds if moving
            if (position.speed > 0.5 && // Moving faster than 0.5 m/s
                DateTime.now()
                        .difference(lastAutoDetectionUpdate.value)
                        .inSeconds >
                    30) {
              _reverseGeocodeDriverLocation(position);
            }
          },
          onError: (error) {
            log('❌ Continuous location tracking error: $error');
            isTrackingDriverLocation.value = false;
          },
        );

    log('🎯 Continuous location tracking started');
  }

  /// Reverse geocode driver's current location
  Future<void> _reverseGeocodeDriverLocation(Position position) async {
    try {
      // This would typically call a geocoding service to get the address
      // For now, we'll set a placeholder that indicates we have the coordinates
      autoDetectedAddress.value =
          'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';

      lastAutoDetectionUpdate.value = DateTime.now();
      hasAutoDetectedLocation.value = true;

      log('📍 Driver location address updated: ${autoDetectedAddress.value}');
    } catch (e) {
      log('❌ Error reverse geocoding driver location: $e');
      autoDetectedAddress.value = 'Location detected (coordinates only)';
    }
  }

  /// Enhanced map markers and circles update
  void _updateMapMarkersAndCircles() {
    Set<Marker> newMarkers = {};
    Set<Circle> newCircles = {};

    

    // Driver location circle (small circle mark)
    if (_isValidCoordinate(driverLatitude.value, driverLongitude.value)) {
      // Add driver circle marker
      newCircles.add(
        Circle(
          circleId: const CircleId('driver_location'),
          center: LatLng(driverLatitude.value, driverLongitude.value),
          radius: 15, // 15 meter radius circle
          fillColor: Colors.blue.withValues(alpha: 0.3),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );

      // Add accuracy circle if location accuracy is available
      if (driverLocationAccuracy.value > 0) {
        newCircles.add(
          Circle(
            circleId: const CircleId('driver_accuracy'),
            center: LatLng(driverLatitude.value, driverLongitude.value),
            radius: driverLocationAccuracy.value,
            fillColor: Colors.blue.withValues(alpha: 0.1),
            strokeColor: Colors.blue.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        );
      }

      // Add driver marker with rotation based on heading
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _animatedPosition ?? LatLng(driverLatitude.value, driverLongitude.value),
          icon: _driverDefaultIcon,
          rotation: _animatedRotation,
            title: '🚗 Your Location',
            snippet:
                'Speed: ${driverSpeed.value.toStringAsFixed(1)} km/h\nAccuracy: ${driverLocationAccuracy.value.toStringAsFixed(1)}m',
          ),
          rotation: driverHeading.value,
        ),
      );
      }

    // Pickup marker
    if (_isValidCoordinate(pickupLatitude.value, pickupLongitude.value)) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLatitude.value, pickupLongitude.value),
          icon: _pickupIcon,
          infoWindow: InfoWindow(
            title: '📍 Pickup Location',
            snippet: currentRide.value?.pickupLocation ?? 'Pickup point',
          ),
        ),
      );
      }

    // Dropoff marker
    if (_isValidCoordinate(dropoffLatitude.value, dropoffLongitude.value)) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(dropoffLatitude.value, dropoffLongitude.value),
          icon: _dropoffIcon,
          infoWindow: InfoWindow(
            title: '🏁 Dropoff Location',
            snippet: currentRide.value?.dropoffLocation ?? 'Destination',
          ),
        ),
      );
      }

    // Update the markers and circles on the map
    markers.assignAll(newMarkers);
    circles.assignAll(newCircles);
    
  }
}
