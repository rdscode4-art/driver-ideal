import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rideal_driver/core/token_manager.dart';
import '../services/driver_api_service.dart';
import '../services/api_service.dart';
import '../fcm_service.dart';
import '../core/sound_manager.dart';
import '../services/rides_api_service.dart';
import '../services/verification_api_service.dart';
import '../ride.dart';
import '../data/models/driver_status.dart';
import '../data/models/driver_status_update_response.dart';
import '../data/models/verification_status.dart';
import '../core/storage_helper.dart';
import '../core/utils/app_snackbar.dart';
import '../routes/app_pages.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/widgets.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  var status = 'Offline'.obs;
  var isLoading = false.obs;
  var kycStatus = 'Pending'.obs;
  var availableRidesCount = 0.obs;
  var nearbyRides = <Ride>[].obs;
  var driverStatus = Rx<DriverStatus?>(null);
  var isStatusLoading = false.obs;
  var driverInfo = Rx<DriverInfo?>(null);
  var hasOngoingRide = false.obs;
  var ongoingRide = Rx<Ride?>(null);
  var optimisticOnline = Rx<bool?>(null); // For immediate UI feedback on toggle

  // KYC verification status
  var isKycVerified = false.obs;
  var verificationData = Rx<VerificationData?>(null);
  var kycVerificationStatus = 'Accepted'.obs;

  // Enhanced location tracking variables
  var isLocationTracking = false.obs;
  var currentRideId = Rx<String?>(null);
  var lastLocationUpdate = Rx<DateTime?>(null);
  var locationUpdateCount = 0.obs;
  var locationUpdateErrors = 0.obs;
  var currentLatitude = 0.0.obs;
  var currentLongitude = 0.0.obs;
  var locationUpdateStatus = 'Not Started'.obs;
  Timer? _locationUpdateTimer;
  static const int locationUpdateIntervalSeconds = 10;

  // Location update history for debugging
  var locationUpdateHistory = <Map<String, dynamic>>[].obs;

  // ✨ NEW: Auto-refresh timers and configuration
  Timer? _statusRefreshTimer;
  Timer? _ridesRefreshTimer;
  var isAutoRefreshEnabled = true.obs;
  var lastStatusRefresh = Rx<DateTime?>(null);
  var lastRidesRefresh = Rx<DateTime?>(null);

  // Configurable refresh intervals (in seconds)
  static const int statusRefreshInterval =
      30; // Refresh status every 30 seconds
  static const int ridesRefreshInterval =
      15; // Refresh rides every 15 seconds when online

  // 📍 NEW: General location tracking for driver
  Timer? _generalLocationTimer;
  double _lastUploadedLat = 0.0;
  double _lastUploadedLng = 0.0;
  static const int generalLocationInterval = 6; // Every 6 seconds
  static const double movementThreshold = 100.0; // 100 meters

  final RidesApiService _ridesApiService = RidesApiService();
  final VerificationApiService _verificationApiService =
      VerificationApiService();
  
  // 📻 Stream subscription for real-time notifications
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void onInit() {
    super.onInit();
    print('************************************************');
    print('🏠 HOME CONTROLLER INIT - STARTING');
    print('************************************************');
    print('📍 Route: ${Get.currentRoute}');
    print('👤 Role: ${Get.find<TokenManager>().userRole.value}');

    _loadLocalStatus(); // Load from local storage first
    loadDriverStatus();
    loadKycStatus();

    // ✨ Start auto-refresh timers
    _startAutoRefresh();
    checkAndFetchOngoingRide();
    
    // 📍 Start general location tracking (6s interval, 100m movement)
    _startGeneralLocationTracking();
    
    // 🔔 Listen for real-time ride notifications (FCM)
    _setupFcmListener();
  }

  @override
  void onReady() {
    super.onReady();
    refreshDataAfterLogin();
  }

  @override
  void onClose() {
    print('🛑 HomeController onClose: Cleaning up resources...');
    WidgetsBinding.instance.removeObserver(this);
    
    _stopLocationTracking();
    _stopAutoRefresh(); // ✨ Stop auto-refresh when controller is disposed
    _generalLocationTimer?.cancel(); // 📍 Stop general location tracking
    _fcmSubscription?.cancel(); // 📻 Cancel FCM subscription
    super.onClose();
  }

  // ✨ NEW: Start auto-refresh timers
 void _startAutoRefresh() {
  print('🔄 Starting auto-refresh timers');

  // Refresh driver status periodically
  _statusRefreshTimer = Timer.periodic(
    const Duration(seconds: statusRefreshInterval),
    (timer) async {
      if (isAutoRefreshEnabled.value) {
        print('⏰ Auto-refreshing driver status...');
        await loadDriverStatus(isSilent: true);
        await checkOngoingRide();
        lastStatusRefresh.value = DateTime.now();
      }
    },
  );

  // 🔥 IMPROVED: Refresh rides more frequently and force UI update
  _ridesRefreshTimer = Timer.periodic(
    const Duration(seconds: ridesRefreshInterval),
    (timer) async {
      if (isAutoRefreshEnabled.value && isOnline) {
        print('⏰ Auto-refreshing available rides...');
        await loadAvailableRidesCount();
        lastRidesRefresh.value = DateTime.now();
        
        // 🔥 Force UI refresh
        nearbyRides.refresh();
      } else if (!isOnline) {
        // Clear rides if driver went offline
        nearbyRides.clear();
        availableRidesCount.value = 0;
      }
    },
  );

  print('✅ Auto-refresh timers started');
  print('   📊 Status refresh: Every $statusRefreshInterval seconds');
  print('   🚗 Rides refresh: Every $ridesRefreshInterval seconds (when online)');
}

  // 🔔 NEW: Setup FCM listener for instant UI updates
  void _setupFcmListener() {
    print('🔔 Setting up FCM listener in HomeController');
    _fcmSubscription = FCMService.rideNotificationStream.stream.listen((message) {
      print('📢 HomeController received real-time notification!');
      print('   Type: ${message.data['type']}');
      
      final String type = message.data['type']?.toString().toLowerCase() ?? '';
      final String title = message.notification?.title?.toLowerCase() ?? '';
      final String body = message.notification?.body?.toLowerCase() ?? '';
      
      // If it's a cancellation, refresh immediately
      if (type.contains('cancel') || title.contains('cancelled') || body.contains('cancelled')) {
        print('🚨 Ride cancelled! Refreshing list and checking ongoing ride...');
        loadAvailableRidesCount();
        checkOngoingRide();
        
        // Close any open dialog or bottom sheet (e.g. if looking at a ride request dialog)
        if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
           Get.back();
        }
        
        // If there was an ongoing ride, we might need to go back to home
        if (hasOngoingRide.value && ongoingRide.value != null) {
          final cancelledRideId = message.data['rideId'] ?? message.data['requestId'] ?? message.data['id'] ?? message.data['_id'];
          if (cancelledRideId == null || cancelledRideId == ongoingRide.value!.id) {
             print('🛑 Active ride was cancelled by user! ID: $cancelledRideId');
             hasOngoingRide.value = false;
             ongoingRide.value = null;
             
             // Force navigation back to home screen and show error
             Get.offAllNamed(Routes.HOME);
             showErrorSnackBar('The rider has cancelled this ride.', title: 'Ride Cancelled');
          }
        }
      } 
      // If it's a new ride request, refresh immediately
      else if (type.contains('new') || title.contains('request') || title.contains('new')) {
        print('🆕 New ride request! Refreshing available rides list...');
        loadAvailableRidesCount();
      }
      // General refresh for other ride-related events
      else {
        print('🔄 Ride event received. Performing silent refresh...');
        refreshData(isSilent: true);
      }
    });
  }

  /// Check for ongoing ride at startup
  Future<void> checkAndFetchOngoingRide() async {
    print('🔍 Initializing ongoing ride check...');
    await checkOngoingRide();
  }

  /// Fetch ongoing ride from API
  Future<void> fetchOngoingRide() async {
    try {
      print('📡 [DEBUG] fetchOngoingRide called');

      final response = await _ridesApiService.getOngoingRide();
      
      print('📥 [DEBUG] fetchOngoingRide Response: ${json.encode(response)}');

      if (response['success'] == true && response['ride'] != null) {
        ongoingRide.value = response['ride'] as Ride;
        hasOngoingRide.value = true;

        print('✅ [DEBUG] Ongoing ride fetched and set: ${ongoingRide.value!.id}');
        print('   Status: ${ongoingRide.value!.status}');
      } else {
        print('ℹ️ [DEBUG] No ongoing ride found in fetch. Success: ${response['success']}, Ride null: ${response['ride'] == null}');
        hasOngoingRide.value = false;
        ongoingRide.value = null;
      }
    } catch (e, stack) {
      print('❌ [DEBUG] Error fetching ongoing ride: $e');
      print('❌ [DEBUG] Stack trace: $stack');
      hasOngoingRide.value = false;
      ongoingRide.value = null;
    }
  }

  // ✨ NEW: Stop auto-refresh timers
  void _stopAutoRefresh() {
    print('🛑 Stopping auto-refresh timers');
    _statusRefreshTimer?.cancel();
    _ridesRefreshTimer?.cancel();
    _statusRefreshTimer = null;
    _ridesRefreshTimer = null;
  }

  // ✨ NEW: Toggle auto-refresh on/off
  void toggleAutoRefresh() {
    isAutoRefreshEnabled.value = !isAutoRefreshEnabled.value;

    if (isAutoRefreshEnabled.value) {
      showSuccessSnackBar('Status and rides will update automatically', title: 'Auto-Refresh Enabled');
    } else {
      showWarningSnackBar('You can still refresh manually', title: 'Auto-Refresh Disabled');
    }
  }

  // Method to refresh data after login
  Future<void> refreshDataAfterLogin() async {
    print('🔄 Refreshing data after login...');
    await Future.delayed(const Duration(milliseconds: 500));
    await refreshData(isSilent: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isOnline) {
        print('📱 App Resumed: Force refreshing rides for vehicle driver...');
        loadAvailableRidesCount();
        checkOngoingRide();
      }
    }
  }

  // Handle manual refresh
  Future<void> refreshData({bool isSilent = false}) async {
    if (!isSilent) {
      print('🔄 Manual refresh triggered');
    }

    try {
      await Future.wait([
        loadDriverStatus(isSilent: isSilent),
        loadKycStatus(),
        loadAvailableRidesCount(),
        checkOngoingRide(),
      ]);

      if (!isSilent) {
        showSuccessSnackBar('All data updated successfully', title: 'Refreshed');
      }
    } catch (e) {
      print('❌ Error during refresh: $e');
      if (!isSilent) {
        showWarningSnackBar('Some data could not be updated', title: 'Refresh Error');
      }
    }
  }

  // Load KYC verification status
  Future<void> loadKycStatus() async {
    try {
      print('🔍 Loading KYC verification status...');

      final response = await _verificationApiService.getVerificationStatus();

      if (response['success'] == true && response['verification'] != null) {
        final verificationJson = response['verification'];
        verificationData.value = VerificationData.fromJson(verificationJson);
        kycVerificationStatus.value = response['status'] ?? 'pending';
        isKycVerified.value =
            kycVerificationStatus.value.toLowerCase() == 'accepted' ||
            kycVerificationStatus.value.toLowerCase() == 'verified';

        switch (kycVerificationStatus.value.toLowerCase()) {
          case 'pending':
            kycStatus.value = 'Under Review';
            break;
          case 'accepted':
          case 'verified':
            kycStatus.value = 'Accepted';
            break;
          case 'rejected':
          case 'failed':
            kycStatus.value = 'Rejected';
            break;
          default:
            kycStatus.value = 'Pending';
        }
        print(
          '✅ KYC Status loaded: ${kycStatus.value} (${kycVerificationStatus.value})',
        );
      } else if (response['status'] == 'not_submitted') {
        verificationData.value = null;
        kycVerificationStatus.value = 'not_submitted';
        kycStatus.value = 'Not Submitted';
        isKycVerified.value = false;
        print('⚠️ No KYC documents found - status: not_submitted');
      } else {
        verificationData.value = null;
        kycVerificationStatus.value = response['status'] ?? 'error';
        kycStatus.value = 'Error';
        isKycVerified.value = false;
        print('❌ KYC API error: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error loading KYC status: $e');
      verificationData.value = null;
      kycVerificationStatus.value = 'error';
      kycStatus.value = 'Error';
      isKycVerified.value = false;
    }
  }

  // Check if driver can go online (requires KYC approval)
  bool get canGoOnline {
    return isKycVerified.value &&
        kycVerificationStatus.value.toLowerCase() == 'accepted';
  }

  // Get KYC status display color
  Color get kycStatusColor {
    switch (kycVerificationStatus.value.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'not_submitted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Show KYC restriction dialog when trying to go online without approval
  void showKycRestrictionDialog() {
    String title = '';
    String message = '';
    String buttonText = 'Go to KYC';

    switch (kycVerificationStatus.value.toLowerCase()) {
      case 'not_submitted':
        title = 'KYC Documents Required';
        message =
            'You need to submit your KYC documents before you can start accepting rides.';
        break;
      case 'pending':
        title = 'Documents Under Review';
        message =
            'Your KYC documents are being reviewed. You can start accepting rides once they are accepted.';
        buttonText = 'Check Status';
        break;
      case 'rejected':
        title = 'Documents Rejected';
        message =
            'Your KYC documents have been rejected. Please resubmit your documents with corrections.';
        buttonText = 'Resubmit Documents';
        break;
      default:
        title = 'Verification Required';
        message =
            'Please complete your KYC verification to start accepting rides.';
    }

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            if (verificationData.value != null) ...[
              const Text(
                'Submission Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted: ${verificationData.value!.formattedSubmissionDate}',
              ),
              Text('Status: ${verificationData.value!.statusDisplayText}'),
              Text('Reference: ${verificationData.value!.id}'),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/kyc-documents');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: Text(
              buttonText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Load current driver status from the new /status API
  Future<void> loadDriverStatus({bool isSilent = false}) async {
    try {
      if (!isSilent) {
        isStatusLoading.value = true;
      }

      final response = await DriverApiService.getDriverStatus();

      if (response.isSuccess && response.data != null) {
        final Map<String, dynamic> responseData = response.data!;
        final Map<String, dynamic> statusData = responseData.containsKey('driver') 
            ? responseData['driver'] 
            : responseData;
            
        final driverStatusData = DriverStatus.fromJson(statusData);
        driverStatus.value = driverStatusData;
        status.value = driverStatusData.displayStatus;

        if (!isSilent) {
          print(
            '✅ Driver status loaded: ${driverStatusData.isAvailable ? "Available" : "Not Available"}',
          );
        }
        
        // Save to local storage for persistence on restart
        await StorageHelper.saveDriverStatus(json.encode(driverStatusData.toJson()));
      } else {
        if (!isSilent) {
          print('❌ Failed to load driver status: ${response.message}');
        }
        // Don't overwrite local status if API fails, unless we have no status at all
        if (driverStatus.value == null) {
          status.value = 'Offline';
          driverStatus.value = DriverStatus(
            isAvailable: false,
            lat: 0.0,
            lng: 0.0,
          );
        }
      }
    } catch (e) {
      if (!isSilent) {
        print('❌ Exception loading driver status: $e');
      }
      if (driverStatus.value == null) {
        status.value = 'Offline';
        driverStatus.value = DriverStatus(
          isAvailable: false,
          lat: 0.0,
          lng: 0.0,
        );
      }
    } finally {
      if (!isSilent) {
        isStatusLoading.value = false;
      }
    }
  }

  // Toggle driver availability status using the new PATCH API
  Future<void> toggleDriverAvailability() async {
    print('************************************************');
    print('🚀 TOGGLE DRIVER AVAILABILITY CALLED!');
    print('************************************************');
    
    // Store previous status outside try block so it's accessible in catch blocks
    final previousStatus = status.value;
    
    try {
      final currentlyOnline = driverStatus.value?.isAvailable ?? false;
      final wantsToGoOnline = !currentlyOnline;

      optimisticOnline.value = wantsToGoOnline; // Set optimistic value immediately
      
      // Optimistically update status for instant UI change
      status.value = wantsToGoOnline ? 'Online' : 'Offline';
      
      isLoading.value = true;

      print('🔄 Updating driver availability to: $wantsToGoOnline');

      // Get current location for the status update
      Position? currentPosition = await _getCurrentLocation();
      double lat = currentPosition?.latitude ?? driverStatus.value?.lat ?? 0.0;
      double lng = currentPosition?.longitude ?? driverStatus.value?.lng ?? 0.0;

      print('📍 Location for update: $lat, $lng');

      // Call endpoint to ensure the server state is updated correctly
      final response = await DriverApiService.updateDriverAvailability(
        isAvailable: wantsToGoOnline,
        lat: lat,
        lng: lng,
      );

      if (response.isSuccess && response.data != null) {
        final Map<String, dynamic> responseData = response.data!;
        final Map<String, dynamic> statusData = responseData.containsKey('driver') 
            ? responseData['driver'] 
            : responseData;
            
        final driverStatusData = DriverStatus.fromJson(statusData);
        driverStatus.value = driverStatusData;
        status.value = driverStatusData.displayStatus;

        print('✅ Driver availability updated successfully to: $wantsToGoOnline');
        
        // Save to local storage
        await StorageHelper.saveDriverStatus(json.encode(driverStatusData.toJson()));

        showAppSnackBar(
          'Status Updated',
          'You are now ${wantsToGoOnline ? "Online" : "Offline"}',
          backgroundColor: wantsToGoOnline ? Colors.green[600]! : Colors.grey[800]!,
          duration: const Duration(seconds: 2),
        );

        // 🚨 IMPORTANT: Jab online ho toh IMMEDIATELY rides load karo
        if (wantsToGoOnline) {
          print('🚀 Driver went online - Loading rides immediately...');
          await loadAvailableRidesCount();
          
          // Delayed refreshes
          Future.delayed(const Duration(seconds: 2), () {
            if (isOnline) loadAvailableRidesCount();
          });
          
          Future.delayed(const Duration(seconds: 5), () {
            if (isOnline) loadAvailableRidesCount();
          });
        } else {
          print('🛑 Driver went offline - Clearing rides...');
          availableRidesCount.value = 0;
          nearbyRides.clear();
          nearbyRides.refresh();
        }
      } else {
        optimisticOnline.value = null; // Revert on failure
        status.value = previousStatus; // Revert status
        print('❌ Failed to update driver availability: ${response.message}');
        showErrorSnackBar(response.message ?? 'Could not update status. Please try again.', title: 'Update Failed');
      }
    } catch (e) {
      optimisticOnline.value = null; // Revert on failure
      status.value = previousStatus; // Revert status
      print('❌ Critical error in toggle: $e');
      showErrorSnackBar('An unexpected error occurred. Please check your internet.');
    } finally {
      optimisticOnline.value = null; // Clear override, rely on actual state
      isLoading.value = false;
    }
  }

  // Load status from local storage for instant UI update
  Future<void> _loadLocalStatus() async {
    try {
      final statusJson = await StorageHelper.getDriverStatus();
      if (statusJson != null) {
        final data = json.decode(statusJson);
        final driverStatusData = DriverStatus.fromJson(data);
        driverStatus.value = driverStatusData;
        status.value = driverStatusData.displayStatus;
        print('💾 Loaded driver status from local storage: ${status.value}');
      }
    } catch (e) {
      print('⚠️ Error loading local status: $e');
    }
  }
  // Force refresh authentication token
  Future<void> _refreshAuthToken() async {
    try {
      final apiService = ApiService();
      await apiService.refreshAuthToken();
      print('🔄 Token refreshed from storage');
    } catch (e) {
      print('❌ Failed to refresh token: $e');
    }
  }

  // Handle authentication errors
  void _handleAuthenticationError() {
    showErrorSnackBar('Your session has expired. Please log in again.', title: 'Authentication Error');
  }

  // Get driver availability status with optimistic override for instant UI feedback
  bool get isOnline => optimisticOnline.value ?? (driverStatus.value?.isAvailable ?? false);

  // ✨ ENHANCED: Load ALL available rides (no limit)
 Future<void> loadAvailableRidesCount() async {
  try {
    print('🔍 Loading all available rides...');
    print('   📊 Current online status: $isOnline');
    
    // Agar offline hai toh rides clear karo
    if (!isOnline) {
      print('   ⚠️ Driver is offline, clearing rides');
      nearbyRides.clear();
      availableRidesCount.value = 0;
      return;
    }

    final response = await _ridesApiService.getAvailableRides();
    
    print('   📥 API Response: ${response['success']}');
    print('   📥 Message: ${response['message']}');

    if (response['success'] == true) {
      final rides = response['rides'] as List<Ride>?;
      
      if (rides != null && rides.isNotEmpty) {
        // 🎵 Play sound if new rides are found
        // ✅ IMPORTANT: Force update the observable list
        nearbyRides.value = List<Ride>.from(rides);
        availableRidesCount.value = rides.length;

        // ✅ Start sound loop if there are rides, stop if not
        if (rides.isNotEmpty) {
          SoundManager().startRequestSound();
        } else {
          SoundManager().stopRequestSound();
          FCMService.stopRequestSound(); // Clear notifications too
        }
        
        print('✅ Loaded ${rides.length} available rides');
      } else {
        nearbyRides.clear();
        availableRidesCount.value = 0;
        SoundManager().stopRequestSound();
        FCMService.stopRequestSound();
        print('   ℹ️ No available rides at the moment');
      }
    } else {
      nearbyRides.clear();
      availableRidesCount.value = 0;
      print('   ⚠️ API returned success: false');
      print('   ⚠️ Message: ${response['message']}');
    }
    
    // Force UI update
    nearbyRides.refresh();
    
  } catch (e, stackTrace) {
    print('❌ Error loading available rides: $e');
    print('❌ Stack trace: $stackTrace');
    nearbyRides.clear();
    availableRidesCount.value = 0;
  }
}

  // Check for ongoing ride with improved error handling
  Future<void> checkOngoingRide() async {
    try {
      print('🔍 [DEBUG] checkOngoingRide starting...');
      final response = await _ridesApiService.getOngoingRide();
      
      print('📥 [DEBUG] checkOngoingRide Response: success=${response['success']}');
      if (response['success'] == true) {
        print('📥 [DEBUG] Ride data present: ${response['ride'] != null}');
      }

      if (response['success'] == true && response['ride'] != null) {
        final ride = response['ride'] as Ride;
        ongoingRide.value = ride;
        hasOngoingRide.value = true;
        print('✅ [DEBUG] Ongoing ride found: ${ride.id} (Status: ${ride.status})');
        print('   Ride Type: ${ride.rideType}');
      } else {
        print('ℹ️ [DEBUG] No active ride found in checkOngoingRide');
        if (response['message'] != null) print('   Message: ${response['message']}');
        ongoingRide.value = null;
        hasOngoingRide.value = false;
      }
    } catch (e, stack) {
      print('❌ [DEBUG] Exception in checkOngoingRide: $e');
      print('❌ [DEBUG] Stack trace: $stack');
      ongoingRide.value = null;
      hasOngoingRide.value = false;
    }
  }

  // Quick accept ride from home screen
  Future<void> quickAcceptRide(String rideId, BuildContext context) async {
    // 🎵 Stop sounds immediately
    SoundManager().stopRequestSound();
    FCMService.stopRequestSound();
    
    try {
      print('📞 Quick accepting ride with AUTO LOCATION TRACKING: $rideId');

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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange[600]!,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accepting ride and starting location tracking...',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final response = await _ridesApiService.acceptRide(rideId);

      if (response['success'] == true) {
        print(
          '✅ Ride accepted successfully - Starting location tracking immediately',
        );

        Ride? acceptedRide = response['ride'] as Ride?;

        if (acceptedRide != null) {
          print(
            '👤 Accepted Ride - Passenger Name: ${acceptedRide.passengerName ?? "NOT AVAILABLE"}',
          );
          print(
            '📱 Accepted Ride - Passenger Phone: ${acceptedRide.passengerPhone ?? "NOT AVAILABLE"}',
          );
        }

        nearbyRides.removeWhere((ride) => ride.id == rideId);
        availableRidesCount.value = nearbyRides.length;

        if (acceptedRide != null) {
          ongoingRide.value = acceptedRide;
          hasOngoingRide.value = true;
        }

        print('🚀 Starting immediate location tracking for ride: $rideId');
        startLocationTracking(rideId);

        Get.back();

        showSuccessSnackBar('Location tracking started! Your location is being shared every few seconds', title: 'Ride Accepted');

        if (acceptedRide != null) {
          Get.toNamed(Routes.ONGOING_RIDE, arguments: acceptedRide);
        } else {
          showErrorSnackBar('Ride data not available');
        }
      } else {
        Get.back();

        print('❌ Failed to accept ride: ${response['message']}');

        showErrorSnackBar(response['message'] ?? 'Failed to accept ride');
      }
    } catch (e, stackTrace) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('❌ Error accepting ride: $e');
      print('❌ Stack trace: $stackTrace');

      showErrorSnackBar('Network error occurred. Please try again.');
    }
  }

  // [Rest of the methods remain the same - updateDriverLocationAfterAcceptance, _getCurrentLocation,
  // cancelRide, navigateToOngoingRide, refreshStatus, startLocationTracking, _performLocationUpdate,
  // stopLocationTracking, etc.]

  // Update driver location after ride acceptance
  Future<void> updateDriverLocationAfterAcceptance(String rideId) async {
    try {
      print('📍 Starting driver location update for ride: $rideId');

      final driverId = await StorageHelper.getDriverId();
      if (driverId == null) {
        print('❌ Driver ID not found in storage');
        return;
      }

      Position? currentPosition = await _getCurrentLocation();
      if (currentPosition == null) {
        print('❌ Could not get current location');
        return;
      }

      final response = await _ridesApiService.updateDriverLocation(
        rideId: rideId,
        driverId: driverId,
        lat: currentPosition.latitude,
        lng: currentPosition.longitude,
      );

      if (response.success) {
        print('✅ Driver location updated successfully');
        startLocationTracking(rideId);

        showSuccessSnackBar('Your location is now being shared with the passenger', title: 'Location Updated');
      } else {
        print('❌ Failed to update driver location: ${response.message}');
        showWarningSnackBar('Location sharing may be delayed: ${response.message}', title: 'Location Update');
      }
    } catch (e) {
      print('❌ Exception updating driver location: $e');
    }
  }

  // Get current location with error handling
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions permanently denied');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 50),
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }

  // Cancel ride
  Future<void> cancelRide(String rideId, {BuildContext? context}) async {
    FCMService.stopRequestSound();
    try {
      print('🚫 Attempting to cancel ride: $rideId');

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Cancel Ride?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to cancel this ride? This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('No, Keep Ride'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        print('ℹ️ Ride cancellation aborted by user');
        return;
      }

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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cancelling ride...',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final response = await _ridesApiService.cancelRide(rideId);

      Get.back();

      if (response['success'] == true) {
        print('✅ Ride cancelled successfully');

        if (isLocationTracking.value && currentRideId.value == rideId) {
          print('🛑 Stopping location tracking for cancelled ride');
          _stopLocationTracking();
          locationUpdateStatus.value = 'Stopped - Ride Cancelled';
        }

        if (ongoingRide.value?.id == rideId) {
          ongoingRide.value = null;
          hasOngoingRide.value = false;
        }

        nearbyRides.removeWhere((ride) => ride.id == rideId);
        availableRidesCount.value = nearbyRides.length;

        if (context != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response['message'] ?? 'Ride cancelled successfully',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[600],
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        } else {
          showSuccessSnackBar(
            response['message'] ?? 'Ride cancelled successfully',
            title: 'Ride Cancelled',
          );
        }

        await loadAvailableRidesCount();

        if (Get.currentRoute.contains('ongoing-ride')) {
          Get.back();
        }
      } else {
        print('❌ Failed to cancel ride: ${response['message']}');

        if (context != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response['message'] ?? 'Failed to cancel ride',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[600],
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        } else {
          showErrorSnackBar(
            response['message'] ?? 'Failed to cancel ride',
            title: 'Cancellation Failed',
          );
        }
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('❌ Exception cancelling ride: $e');

      if (context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Network error occurred. Please try again.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      } else {
        showErrorSnackBar(
          'Network error occurred. Please try again.',
          title: 'Error',
        );
      }
    }
  }

  // Navigate to ongoing ride screen
  Future<void> navigateToOngoingRide() async {
    try {
      if (ongoingRide.value != null) {
        Get.toNamed('/ongoing-ride', arguments: ongoingRide.value);
      } else {
        await checkOngoingRide();

        if (ongoingRide.value != null) {
          Get.toNamed('/ongoing-ride', arguments: ongoingRide.value);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showWarningSnackBar(
              'You don\'t have any active rides at the moment.',
              title: 'No Ongoing Ride',
            );
          });
        }
      }
    } catch (e) {
      print("❌ Error navigating to ongoing ride: $e");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorSnackBar(
          'Could not load ride details. Please try again.',
          title: 'Error',
        );
      });
    }
  }

  // Refresh status (consolidated method)
  Future<void> refreshStatus({bool isSilent = false}) async {
    await loadDriverStatus(isSilent: isSilent);
    await checkOngoingRide();
    if (isOnline) {
      await loadAvailableRidesCount();
    }
  }

  // Enhanced location tracking with comprehensive monitoring
  void startLocationTracking(String rideId) {
    print('🚀 Starting enhanced location tracking for ride: $rideId');

    currentRideId.value = rideId;
    isLocationTracking.value = true;
    locationUpdateStatus.value = 'Active';
    locationUpdateCount.value = 0;
    locationUpdateErrors.value = 0;
    lastLocationUpdate.value = DateTime.now();

    locationUpdateHistory.clear();

    _performLocationUpdate(rideId);

    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: locationUpdateIntervalSeconds),
      (timer) async {
        await _performLocationUpdate(rideId);
      },
    );

    print('✅ Location tracking started successfully');
  }

  // Perform individual location update with comprehensive error handling
  Future<void> _performLocationUpdate(String rideId) async {
    final updateStartTime = DateTime.now();
    Position? currentPosition;

    try {
      locationUpdateStatus.value = 'Getting Location...';

      final driverId = await StorageHelper.getDriverId();
      if (driverId == null || driverId.isEmpty) {
        throw Exception('Driver ID not found in storage');
      }

      currentPosition = await _getCurrentLocation();
      if (currentPosition == null) {
        throw Exception('Could not get current location - GPS may be disabled');
      }

      currentLatitude.value = currentPosition.latitude;
      currentLongitude.value = currentPosition.longitude;

      locationUpdateStatus.value = 'Sending to Server...';

      print('📡 Sending location update to server:');
      print('   🆔 Ride ID: $rideId');
      print('   👤 Driver ID: $driverId');
      print(
        '   📍 Coordinates: ${currentPosition.latitude}, ${currentPosition.longitude}',
      );

      final response = await _ridesApiService
          .updateDriverLocation(
            rideId: rideId,
            driverId: driverId,
            lat: currentPosition.latitude,
            lng: currentPosition.longitude,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'Location update timed out',
              const Duration(seconds: 30),
            ),
          );

      // ⭐ Also update general driver location (important for system-wide tracking)
      try {
        final genResponse = await DriverApiService.updateDriverLocation(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        if (genResponse.isSuccess) {
          print('✅ General driver location updated successfully');
        } else {
          print('⚠️ General location update failed (Server): ${genResponse.message}');
        }
      } catch (e) {
        print('⚠️ General location update failed (Exception): $e');
      }

      final updateEndTime = DateTime.now();
      final duration = updateEndTime.difference(updateStartTime);

      if (response.success) {
        locationUpdateCount.value++;
        lastLocationUpdate.value = updateEndTime;
        locationUpdateStatus.value = 'Success';

        final historyEntry = {
          'timestamp': updateEndTime.toIso8601String(),
          'status': 'success',
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
          'duration': '${duration.inMilliseconds}ms',
          'message': response.message,
          'updateCount': locationUpdateCount.value,
        };

        try {
          locationUpdateHistory.insert(0, historyEntry);

          if (locationUpdateHistory.length > 50) {
            locationUpdateHistory.removeRange(50, locationUpdateHistory.length);
          }
        } catch (historyError) {
          print('⚠️ Could not update location history: $historyError');
        }

        print('✅ Location update #${locationUpdateCount.value} successful');
        print(
          '   📍 Coordinates: ${currentPosition.latitude}, ${currentPosition.longitude}',
        );
        print('   ⏱️ Duration: ${duration.inMilliseconds}ms');
      } else {
        throw Exception('Server error: ${response.message}');
      }
    } catch (e) {
      locationUpdateErrors.value++;
      final errorMessage = e.toString();
      locationUpdateStatus.value = 'Error: $errorMessage';

      final updateEndTime = DateTime.now();
      final duration = updateEndTime.difference(updateStartTime);

      final errorHistoryEntry = {
        'timestamp': updateEndTime.toIso8601String(),
        'status': 'error',
        'latitude': currentPosition?.latitude ?? currentLatitude.value,
        'longitude': currentPosition?.longitude ?? currentLongitude.value,
        'duration': '${duration.inMilliseconds}ms',
        'message': errorMessage,
        'errorCount': locationUpdateErrors.value,
      };

      try {
        locationUpdateHistory.insert(0, errorHistoryEntry);

        if (locationUpdateHistory.length > 50) {
          locationUpdateHistory.removeRange(50, locationUpdateHistory.length);
        }
      } catch (historyError) {
        print('⚠️ Could not update error history: $historyError');
      }

      print('❌ Location update failed (Error #${locationUpdateErrors.value}):');
      print('   🔴 Error: $errorMessage');
    }
  }

  // Stop location tracking with cleanup
  void stopLocationTracking() {
    print('🛑 Stopping location tracking');

    _stopLocationTracking();
    locationUpdateStatus.value = 'Stopped';

    print('📊 Final Location Tracking Stats:');
    print('   ✅ Successful Updates: ${locationUpdateCount.value}');
    print('   ❌ Failed Updates: ${locationUpdateErrors.value}');

    showInfoSnackBar('Updates: ${locationUpdateCount.value}, Errors: ${locationUpdateErrors.value}', title: 'Location Tracking Stopped');
  }

  // Get location tracking summary for debugging
  Map<String, dynamic> getLocationTrackingSummary() {
    return {
      'isActive': isLocationTracking.value,
      'rideId': currentRideId.value,
      'updateCount': locationUpdateCount.value,
      'errorCount': locationUpdateErrors.value,
      'lastUpdate': lastLocationUpdate.value?.toIso8601String(),
      'currentStatus': locationUpdateStatus.value,
      'currentLocation': {
        'latitude': currentLatitude.value,
        'longitude': currentLongitude.value,
      },
      'updateInterval': locationUpdateIntervalSeconds,
      'historyCount': locationUpdateHistory.length,
    };
  }

  // Private method to stop location tracking (cleanup)
  void _stopLocationTracking() {
    isLocationTracking.value = false;
    currentRideId.value = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    print('🔧 Location tracking timer stopped and cleaned up');
  }

  // Start location tracking for any ongoing ride
  Future<void> startLocationTrackingForOngoingRide() async {
    try {
      if (hasOngoingRide.value && ongoingRide.value != null) {
        final rideId = ongoingRide.value!.id;
        print('🎯 Starting location tracking for ongoing ride: $rideId');

        startLocationTracking(rideId);

        showSuccessSnackBar('Your location is being shared with the passenger every $locationUpdateIntervalSeconds seconds', title: 'Location Tracking Started');
      } else {
        showWarningSnackBar('Please accept a ride first to start location tracking', title: 'No Active Ride');
      }
    } catch (e) {
      print('❌ Error starting location tracking: $e');
      showErrorSnackBar('Failed to start location tracking: $e');
    }
  }

  // Check if location tracking should be active and restart if needed
  Future<void> ensureLocationTrackingIsActive() async {
    if (hasOngoingRide.value &&
        ongoingRide.value != null &&
        !isLocationTracking.value) {
      print('🔄 Ensuring location tracking is active for ongoing ride');
      await startLocationTrackingForOngoingRide();
    }
  }

  // Enhanced method to accept ride with immediate location tracking
  Future<void> acceptRideWithImmediateTracking(String rideId) async {
    SoundManager().stopRequestSound();
    FCMService.stopRequestSound();
    try {
      print('📞 Accepting ride with immediate location tracking: $rideId');

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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange[600]!,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Accepting ride and starting location tracking...',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final response = await _ridesApiService.acceptRide(rideId);

      if (response['success'] == true) {
        print('✅ Ride accepted successfully');

        Ride? acceptedRide = nearbyRides.firstWhereOrNull(
          (ride) => ride.id == rideId,
        );
        if (response['ride'] != null) {
          acceptedRide = response['ride'] as Ride;
        }

        ongoingRide.value = acceptedRide;
        hasOngoingRide.value = true;

        nearbyRides.removeWhere((ride) => ride.id == rideId);
        availableRidesCount.value = nearbyRides.length;

        print('🚀 Starting immediate location tracking...');
        startLocationTracking(rideId);

        Get.back();

        showSuccessSnackBar('Location tracking started successfully', title: 'Ride Accepted');

        Get.toNamed(Routes.ONGOING_RIDE, arguments: acceptedRide);

        await loadAvailableRidesCount();
      } else {
        Get.back();

        print('❌ Failed to accept ride: ${response['message']}');
        showErrorSnackBar(response['message'] ?? 'Failed to accept ride');
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('❌ Exception accepting ride: $e');
      showErrorSnackBar('Failed to accept ride and start tracking. Please try again.');
    }
  }

  // 📍 NEW: General location tracking implementation
  void _startGeneralLocationTracking() {
    print('📍 Starting general location tracking (6s interval)');
    _generalLocationTimer?.cancel();
    _generalLocationTimer = Timer.periodic(
      const Duration(seconds: generalLocationInterval),
      (timer) async {
        await _checkAndUploadLocation();
      },
    );
  }

  Future<void> _checkAndUploadLocation() async {
    // 📍 Only upload if driver is Online
    if (status.value.toLowerCase() != 'online') {
      return;
    }

    try {
      // 1. Get current position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 3),
        );
      } catch (e) {
        // Fallback to last known position if current fails
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return;

      // 2. Check if moved > 100m or first time
      double distance = movementThreshold + 1; // Default to trigger first time
      if (_lastUploadedLat != 0.0 && _lastUploadedLng != 0.0) {
        distance = Geolocator.distanceBetween(
          _lastUploadedLat,
          _lastUploadedLng,
          position.latitude,
          position.longitude,
        );
      }

      if (distance >= movementThreshold) {
        print('🏃 Driver moved ${distance.toStringAsFixed(1)}m. Updating location on server...');
        
        final response = await _ridesApiService.updateDriverGeneralLocation(
          lat: position.latitude,
          lng: position.longitude,
        );

        if (response['success'] == true) {
          print('✅ General location update successful');
          _lastUploadedLat = position.latitude;
          _lastUploadedLng = position.longitude;
        } else {
          print('❌ General location update failed: ${response['message']}');
        }
      }
    } catch (e) {
      print('⚠️ Error in background location check: $e');
    }
  }
}
