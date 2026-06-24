import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rideal_driver/core/app_theme.dart';
import 'package:rideal_driver/nonvehichle/nonvehichledashboard.dart';
import 'package:rideal_driver/nonvehichle/triphistorynponvehichle.dart';
import 'package:rideal_driver/nonvehichle/ridedetailsnonvehichle.dart';
import 'package:rideal_driver/nonvehichle/non_vehichle_auth_service.dart';
import 'package:rideal_driver/core/token_manager.dart';
import 'package:rideal_driver/core/sound_manager.dart';
import 'package:rideal_driver/presentation/drawar.dart';
import 'package:rideal_driver/presentation/widgets/contact_info_section.dart';
import 'package:rideal_driver/presentation/widgets/social_media_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideal_driver/fcm_service.dart';
import 'package:rideal_driver/services/location_service.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/controllers/non_vehicle_auth_controller.dart';
import 'package:rideal_driver/controllers/profile_controller.dart';
import 'package:url_launcher/url_launcher.dart';

// Home Screen
class HomeScreennonvehichle extends StatefulWidget {
  const HomeScreennonvehichle({super.key});

  @override
  State<HomeScreennonvehichle> createState() => _HomeScreennonvehichleState();
}

class _HomeScreennonvehichleState extends State<HomeScreennonvehichle> with WidgetsBindingObserver {
  String driverStatus = 'offline';
  bool isLoading = false;
  
  final TokenManager _tokenManager = TokenManager.instance;
  String? authToken;
  
  List<RideRequest> rideRequests = [];
  List<OngoingRide> ongoingRides = [];
  Set<String> rejectedRideIds = {}; // Track rejected rides to avoid sound loops
  StreamSubscription? _notificationSubscription; // Add this
  Timer? _restoreTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Initialize ProfileController for CustomDrawer
    Get.put(ProfileController());
    WidgetsBinding.instance.addObserver(this);
    
    // 📢 Listen for real-time ride notifications
    _notificationSubscription = FCMService.rideNotificationStream.stream.listen((message) {
      print('🔔 Real-time ride notification received in Home - refreshing silently...');
      if (authToken != null) {
        fetchRideRequests(isSilent: true); // Use silent mode
      }
    });

    _initializeAndFetch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel(); // Cancel subscription
    SoundManager().stopRequestSound();
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🛑 Stop background notification ringing instantly when app comes to foreground
      FCMService.stopRequestSound();
      
      // Silent refresh on app resume (no UI loader)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (authToken != null) {
          fetchRideRequests(isSilent: true); // Use silent mode
          if (driverStatus == 'online') {
            _startPolling();
          }
        } else {
          _initializeAndFetch(); // Still use full init if token is missing
        }
      });
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    print('🔄 Starting periodic polling timer for ride requests...');
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (authToken != null && driverStatus == 'online' && !isLoading) {
        print('⏰ Polling: Auto-refreshing non-vehicle ride requests...');
        fetchRideRequests(isSilent: true);
      }
    });
  }

  void _stopPolling() {
    print('🔇 Stopping periodic polling timer.');
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _initializeAndFetch() async {
    await _loadStatusFromStorage(); // 🆕 Load status first
    await _loadToken();
    await _loadOngoingRidesFromStorage();
    
    // Refresh profile data to ensure UI shows correct driver info
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshProfile();
    }
    
    if (authToken != null) {
      fetchRideRequests(isSilent: false); // Initial load is not silent
      if (driverStatus == 'online') {
        _startPolling();
      }
    } else {
      _showErrorSnackbar('Authentication token not found. Please login again.');
    }
  }

  // 🆕 SAVE STATUS TO STORAGE
  Future<void> _saveStatusToStorage(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('non_vehicle_driver_status', status);
      print('💾 Saved status to storage: $status');
    } catch (e) {
      print('❌ Error saving status: $e');
    }
  }

  // 🆕 LOAD STATUS FROM STORAGE
  Future<void> _loadStatusFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getString('non_vehicle_driver_status');
      if (savedStatus != null) {
        setState(() {
          driverStatus = savedStatus;
        });
        print('📂 Loaded status from storage: $savedStatus');
      }
    } catch (e) {
      print('❌ Error loading status: $e');
    }
  }

  Future<String> _resolveAddressIfNeeded(dynamic locationData) async {
    if (locationData == null) return 'Location not provided';
    
    // 📍 Handle Map coordinates {lat, lng} or GeoJSON {type: Point, coordinates: [lng, lat]}
    if (locationData is Map) {
      try {
        double? lat;
        double? lng;
        
        if (locationData['coordinates'] != null && locationData['coordinates'] is List && locationData['coordinates'].length >= 2) {
          // GeoJSON format is [longitude, latitude]
          lng = double.tryParse(locationData['coordinates'][0].toString());
          lat = double.tryParse(locationData['coordinates'][1].toString());
        } else {
          lat = locationData['lat'] != null ? double.tryParse(locationData['lat'].toString()) : null;
          lng = locationData['lng'] != null ? double.tryParse(locationData['lng'].toString()) : null;
        }
        
        if (lat != null && lng != null) {
          print('📍 Resolving coordinates: $lat, $lng');
          final address = await LocationService.getAddressFromCoordinates(lat, lng);
          return address ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
      } catch (e) {
        print('⚠️ Error resolving Map coordinates: $e');
      }
    }

    String location = locationData.toString();
    if (location.isEmpty || location == 'Pickup location will be shared' || location == 'null') {
      return location == 'null' ? 'Location not provided' : location;
    }
    
    // 📍 If pickup looks like coordinates string "lat, lng", resolve it
    if (location.contains(',') && !location.contains(RegExp(r'[a-zA-Z]'))) {
      try {
        final coords = location.split(',');
        if (coords.length >= 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());
          if (lat != null && lng != null) {
            final address = await LocationService.getAddressFromCoordinates(lat, lng);
            if (address != null) return address;
          }
        }
      } catch (e) {
        print('⚠️ Error resolving coordinate string: $e');
      }
    }
    return location;
  }

  Future<void> _saveOngoingRidesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ridesJson = ongoingRides.map((ride) => {
        'id': ride.id,
        'passengerName': ride.passengerName,
        'passengerPhone': ride.passengerPhone,
        'pickup': ride.pickup,
        'dropoff': ride.dropoff,
        'distance': ride.distance,
        'fare': ride.fare,
        'status': ride.status,
        'otp': ride.otp,
        'estimatedTime': ride.estimatedTime,
        'rating': ride.rating,
      }).toList();
      
      await prefs.setString('ongoing_rides', jsonEncode(ridesJson));
      print('✅ Saved ${ongoingRides.length} ongoing rides to storage');
    } catch (e) {
      print('❌ Error saving rides: $e');
    }
  }

  Future<void> _loadOngoingRidesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ridesString = prefs.getString('ongoing_rides');
      
      if (ridesString != null) {
        final List<dynamic> ridesJson = jsonDecode(ridesString);
        
        // Resolve addresses for all restored rides
        final processedRides = await Future.wait(ridesJson.map((rideData) async {
          // Load fare correctly
          double fare = 0.0;
          if (rideData['fare'] != null) {
            fare = (rideData['fare'] is num) ? (rideData['fare'] as num).toDouble() : (double.tryParse(rideData['fare'].toString()) ?? 0.0);
          } else if (rideData['price'] != null) {
            fare = (rideData['price'] is num) ? (rideData['price'] as num).toDouble() : (double.tryParse(rideData['price'].toString()) ?? 0.0);
          }
          
          double rating = 4.5;
          if (rideData['rating'] != null) {
            rating = (rideData['rating'] is num) ? (rideData['rating'] as num).toDouble() : (double.tryParse(rideData['rating'].toString()) ?? 4.5);
          }
          
          final resolvedPickup = await _resolveAddressIfNeeded(rideData['pickup'] ?? '');
          
          return OngoingRide(
            id: rideData['id'] ?? '',
            passengerName: rideData['passengerName'] ?? 'Unknown',
            passengerPhone: rideData['passengerPhone'] ?? 'N/A',
            pickup: resolvedPickup,
            dropoff: rideData['dropoff'] ?? '',
            distance: rideData['distance'] ?? '',
            fare: fare.round(),
            status: rideData['status'] ?? 'accepted',
            otp: rideData['otp'] ?? '',
            estimatedTime: rideData['estimatedTime'] ?? '',
            rating: rating,
          );
        }).toList());

        setState(() {
          ongoingRides = processedRides;
          if (ongoingRides.isNotEmpty) {
            driverStatus = 'busy';
          }
        });
        print('✅ Loaded ${ongoingRides.length} ongoing rides from storage');
      }
    } catch (e) {
      print('❌ Error loading rides: $e');
    }
  }

  Future<void> _clearOngoingRidesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ongoing_rides');
      print('✅ Cleared ongoing rides from storage');
    } catch (e) {
      print('❌ Error clearing rides: $e');
    }
  }

  Future<void> _loadToken() async {
    try {
      final token = await _tokenManager.getCurrentToken();
      setState(() {
        authToken = token;
      });
      
      if (token != null) {
        print('✅ Token loaded successfully for non-vehicle driver');
      } else {
        print('⚠️ No token available');
      }
    } catch (e) {
      print('❌ Error loading token: $e');
      _showErrorSnackbar('Failed to load authentication token');
    }
  }

  Future<void> fetchRideRequests({bool isSilent = false}) async {
    if (authToken == null) return;
    
    if (driverStatus == 'offline') {
      setState(() {
        rideRequests = [];
      });
      SoundManager().stopRequestSound();
      return;
    }
    
    if (!isSilent) {
      // Clear existing list to ensure no stale data from storage/previous state is shown
      setState(() {
        ongoingRides = [];
      });
      setState(() => isLoading = true);
    }
    
    try {
      final result = await NonVehicleAuthService.fetchRideRequests(authToken!);
      print('🚀 Response: $result');

      if (result['success']) {
        final data = result['data'] ?? result;
        if (data['requests'] != null && data['requests'] is List) {
          final List rawRequestsData = data['requests'];
          
          // Filter out requests that are already accepted (in ongoingRides)
          // Also filter out requests that we have locally rejected
          final List newRequestsData = rawRequestsData.where((req) {
            final reqId = (req['rideId'] ?? req['_id'] ?? req['id'] ?? '').toString();
            final isAccepted = ongoingRides.any((ongoing) => ongoing.id == reqId);
            final isRejected = rejectedRideIds.contains(reqId);
            return !isAccepted && !isRejected;
          }).toList();
          
          // 🎵 Play sound loop if valid pending requests are present, stop if not
          if (newRequestsData.isNotEmpty) {
            SoundManager().startRequestSound();
          } else {
            SoundManager().stopRequestSound();
          }

          // Resolve addresses for all requests
          final processedRequests = await Future.wait(newRequestsData.map((rideData) async {
            // Handle both flat and nested rider objects
            String riderName = 'Rider';
            if (rideData['rider'] != null && rideData['rider'] is Map) {
              riderName = rideData['rider']['name']?.toString() ?? 'Rider';
            } else if (rideData['passengerName'] != null) {
              riderName = rideData['passengerName'].toString();
            } else {
              String riderId = rideData['riderId']?.toString() ?? 'Unknown';
              riderName = riderId.length >= 8 ? 'Rider ${riderId.substring(0, 8)}' : 'Rider $riderId';
            }

            final pickup = await _resolveAddressIfNeeded(rideData['pickupLocation'] ?? rideData['pickup'] ?? 'Pickup location will be shared');

            double fare = 0.0;
            if (rideData['price'] != null) {
              if (rideData['price'] is num) {
                fare = (rideData['price'] as num).toDouble();
              } else {
                fare = double.tryParse(rideData['price'].toString()) ?? 0.0;
              }
            }

            double rating = 4.5;
            if (rideData['rating'] != null) {
              if (rideData['rating'] is num) {
                rating = (rideData['rating'] as num).toDouble();
              } else {
                rating = double.tryParse(rideData['rating'].toString()) ?? 4.5;
              }
            }

            return RideRequest(
              id: (rideData['rideId'] ?? rideData['_id'] ?? rideData['id'] ?? '').toString(),
              passengerName: riderName,
              passengerPhone: (rideData['rider'] != null && rideData['rider'] is Map) 
                  ? (rideData['rider']['phone']?.toString() ?? '') 
                  : (rideData['passengerPhone']?.toString() ?? 'Contact on acceptance'),
              pickup: pickup,
              dropoff: rideData['dropoffLocation']?.toString() ?? 'Location will be shared',
              distance: (rideData['duration'] ?? rideData['hours'] ?? '0').toString() + (rideData['duration'] != null ? '' : ' hours'),
              fare: fare.toInt(),
              estimatedTime: (rideData['duration'] ?? '${rideData['hours'] ?? 0}h').toString(),
              rating: rating,
            );
          }).toList());

          setState(() {
            rideRequests = processedRequests;
          });
          
          print('✅ Loaded ${rideRequests.length} ride requests');
        } else {
          print('⚠️ No requests array found in response');
          setState(() {
            rideRequests = [];
          });
          SoundManager().stopRequestSound();
        }
      } else {
        // 🚗 Check if there's an active ride on backend (403 response)
        if (result['hasActiveRide'] == true) {
          final activeRideId = result['activeRideId'] as String;
          print('🔄 Restoring active ride from backend: $activeRideId');
          
          // Only add if not already in ongoingRides
          if (activeRideId.isNotEmpty) {
            // Check if we need to add a placeholder
            final alreadyExists = ongoingRides.any((r) => r.id == activeRideId);
            if (!alreadyExists) {
            // First add a placeholder so driver sees the active ride immediately
            setState(() {
              ongoingRides.add(OngoingRide(
                id: activeRideId,
                passengerName: 'Active Passenger',
                passengerPhone: '',
                pickup: 'Pickup location',
                dropoff: 'Dropoff location',
                distance: '0 hours',
                fare: 0,
                status: result['status'] ?? 'accepted',
                otp: '',
                estimatedTime: '0h',
                rating: 4.5,
              ));
              driverStatus = 'busy';
            });
          }

          // ALWAYS fetch actual details and update, even if it already existed in storage
          // Fetch full details from trip history instead of just status
          // This is more robust as we know history has the correct mapping
          final historyResult = await NonVehicleAuthService.getTripHistory(authToken!);
          print('📦 Restoration history result: ${historyResult['success']}');
            
            if (historyResult['success'] == true) {
              List<dynamic> tripsJson = [];
              final data = historyResult['data'];
              if (data is List) tripsJson = data;
              else if (data is Map) tripsJson = data['rides'] ?? data['trips'] ?? data['history'] ?? data['data'] ?? [];
              
              // Find the active ride in history
              final activeRideJson = tripsJson.firstWhere(
                (json) => (json['rideId']?.toString() ?? json['id']?.toString() ?? json['_id']?.toString()) == activeRideId,
                orElse: () => null,
              );

              if (activeRideJson != null) {
                print('✅ Found active ride in history: $activeRideJson');
                
                // Use the robust parsing logic
                int parsedHours = 0;
                if (activeRideJson['hours'] != null) {
                  parsedHours = (activeRideJson['hours'] is int) ? activeRideJson['hours'] : (double.tryParse(activeRideJson['hours'].toString())?.round() ?? 0);
                } else if (activeRideJson['duration'] != null) {
                  String durationStr = activeRideJson['duration'].toString().toLowerCase();
                  RegExp regExp = RegExp(r'(\d+\.?\d*)');
                  Match? match = regExp.firstMatch(durationStr);
                  if (match != null) parsedHours = double.parse(match.group(1)!).round();
                }

                double parsedFare = 0.0;
                if (activeRideJson['price'] != null) {
                  parsedFare = (activeRideJson['price'] is num) ? (activeRideJson['price'] as num).toDouble() : (double.tryParse(activeRideJson['price'].toString()) ?? 0.0);
                } else if (activeRideJson['fare'] != null) {
                  parsedFare = (activeRideJson['fare'] is num) ? (activeRideJson['fare'] as num).toDouble() : (double.tryParse(activeRideJson['fare'].toString()) ?? 0.0);
                }

                String passengerName = activeRideJson['rider']?['name']?.toString() ?? 
                                    activeRideJson['passengerName']?.toString() ?? 
                                    'Active Passenger';
                
                dynamic locationObj = activeRideJson['pickupLocation'] ?? activeRideJson['pickup'];
                String pickup = await _resolveAddressIfNeeded(locationObj);
                
                String dropoff = activeRideJson['dropoffLocation']?.toString() ?? 
                                 activeRideJson['dropoff']?.toString() ?? 
                                 (parsedHours > 0 ? '$parsedHours hour${parsedHours > 1 ? "s" : ""} booking' : 'Driver Service');

                setState(() {
                  final idx = ongoingRides.indexWhere((r) => r.id == activeRideId);
                  final restoredRide = OngoingRide(
                    id: activeRideId,
                    passengerName: passengerName,
                    passengerPhone: activeRideJson['rider']?['phone']?.toString() ?? activeRideJson['passengerPhone']?.toString() ?? '',
                    pickup: pickup,
                    dropoff: dropoff,
                    distance: parsedHours > 0 ? '${parsedHours}h' : 'N/A',
                    fare: parsedFare.round(),
                    status: activeRideJson['status'] ?? 'accepted',
                    otp: activeRideJson['otp']?.toString() ?? '',
                    estimatedTime: parsedHours > 0 ? '${parsedHours}h' : '...',
                    rating: 4.5,
                  );

                  if (idx != -1) {
                    ongoingRides[idx] = restoredRide;
                  } else {
                    ongoingRides.add(restoredRide);
                  }
                });
                print('✅ Active ride details restored from history!');
              } else {
                print('⚠️ Active ride not found in history, falling back to status API');
                // Fallback to getRideStatus if not in history yet
                final statusResult = await NonVehicleAuthService.getRideStatus(authToken!, activeRideId);
                if (statusResult['success'] == true) {
                  final rawData = statusResult['data'];
                  final rideData = rawData['ride'] ?? rawData['data']?['ride'] ?? rawData['data'] ?? rawData;
                  
                  // (Using the existing fallback parsing logic here...)
                  setState(() {
                    final idx = ongoingRides.indexWhere((r) => r.id == activeRideId);
                    // ... (simplified for this chunk)
                    if (idx == -1) {
                      ongoingRides.add(OngoingRide(
                        id: activeRideId,
                        passengerName: 'Active Ride',
                        passengerPhone: '',
                        pickup: 'Service ongoing',
                        dropoff: 'Location pending',
                        distance: '...',
                        fare: 0,
                        status: 'accepted',
                        otp: '',
                        estimatedTime: '...',
                        rating: 0,
                      ));
                    }
                  });
                }
              }
            }

            await _saveOngoingRidesToStorage();
            print('✅ Active ride restoration process completed!');
          }
          setState(() => rideRequests = []);
          SoundManager().stopRequestSound();
        } else {
          final errorMessage = result['message'] ?? 'Failed to fetch rides';
          print('⚠️ API Info: $errorMessage');
          // Only show error for non-empty/non-404 failures
          if (!errorMessage.contains('404') && !errorMessage.contains('No ride requests')) {
            _showErrorSnackbar(errorMessage);
          }
          setState(() {
            rideRequests = [];
          });
          SoundManager().stopRequestSound();
        }
      }
    } catch (e) {
      print('🔥 Exception: $e');
      _showErrorSnackbar('Something went wrong fetching rides');
      setState(() {
        rideRequests = [];
      });
      SoundManager().stopRequestSound();
    } finally {
      if (!isSilent) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> acceptRide(String requestId) async {
    FCMService.stopRequestSound();
    if (ongoingRides.isNotEmpty) {
      _showErrorSnackbar('⚠️ You already have an ongoing ride. Complete it first.');
      return;
    }

    if (authToken == null) {
      await _loadToken();
      if (authToken == null) {
        _showErrorSnackbar('Please login to continue');
        return;
      }
    }

    setState(() => isLoading = true);
    
    // 🎵 Stop the request sound immediately when accepting
    FCMService.stopRequestSound();

    final result = await NonVehicleAuthService.acceptRide(authToken!, requestId);

    if (result['success']) {
      final rideData = result['data']['ride'];

      if (rideData != null) {
        String riderId = rideData['riderId']?.toString() ?? 'Unknown';
        String riderDisplayName = riderId.length >= 8 
            ? 'Rider ${riderId.substring(0, 8)}' 
            : 'Rider $riderId';

        _showSuccessSnackbar('Ride accepted successfully! ');

        // Logic mirrored from TripHistoryItem.fromJson
        int parsedHours = 0;
        if (rideData['hours'] != null) {
          parsedHours = (rideData['hours'] is int) ? rideData['hours'] : (double.tryParse(rideData['hours'].toString())?.round() ?? 0);
        } else if (rideData['duration'] != null) {
          String durationStr = rideData['duration'].toString().toLowerCase();
          RegExp regExp = RegExp(r'(\d+\.?\d*)');
          Match? match = regExp.firstMatch(durationStr);
          if (match != null) parsedHours = double.parse(match.group(1)!).round();
        }

        double parsedFare = 0.0;
        if (rideData['price'] != null) {
          parsedFare = (rideData['price'] is num) ? (rideData['price'] as num).toDouble() : (double.tryParse(rideData['price'].toString()) ?? 0.0);
        } else if (rideData['fare'] != null) {
          parsedFare = (rideData['fare'] is num) ? (rideData['fare'] as num).toDouble() : (double.tryParse(rideData['fare'].toString()) ?? 0.0);
        }

        String passengerName = rideData['rider']?['name']?.toString() ?? 
                            rideData['passengerName']?.toString() ?? 
                            riderDisplayName;
        
        String pickup = await _resolveAddressIfNeeded(rideData['pickupLocation'] ?? rideData['pickup'] ?? 'Service Location');
        String dropoff = rideData['dropoffLocation']?.toString() ?? (parsedHours > 0 ? '$parsedHours hour${parsedHours > 1 ? 's' : ''} booking' : 'Driver Service');

        final newOngoingRide = OngoingRide(
          id: rideData['_id'] ?? rideData['id'] ?? rideData['rideId'] ?? requestId,
          passengerName: passengerName,
          passengerPhone: rideData['rider']?['phone']?.toString() ?? rideData['passengerPhone']?.toString() ?? 'Contact shared after start',
          pickup: pickup,
          dropoff: dropoff,
          distance: parsedHours > 0 ? '${parsedHours}h' : 'N/A',
          fare: parsedFare.round(),
          status: rideData['status'] ?? 'accepted',
          otp: rideData['otp'] ?? '',
          estimatedTime: parsedHours > 0 ? '${parsedHours}h' : '...',
          rating: 4.5,
        );

        setState(() {
          rideRequests.removeWhere((r) => r.id == requestId);
          ongoingRides.add(newOngoingRide);
          driverStatus = 'busy';
        });
        
        await _saveOngoingRidesToStorage();
      }
    } else {
      if (result['message']?.toLowerCase().contains('token') ?? false) {
        await _tokenManager.handleInvalidToken();
      } else {
        _showErrorSnackbar(result['message'] ?? 'Failed to accept ride');
      }
    }

    setState(() => isLoading = false);
  }

  Widget _buildRideRequestCard(RideRequest ride) {
    final hasOngoingRide = ongoingRides.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: hasOngoingRide ? Colors.grey[50] : Colors.white,
        border: Border.all(
          color: hasOngoingRide ? Colors.grey[300]! : AppTheme.primary.withOpacity(0.3),
          width: hasOngoingRide ? 1 : 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hasOngoingRide 
                ? Colors.transparent 
                : AppTheme.primary.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          if (hasOngoingRide)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasOngoingRide ? Colors.grey[200] : AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: hasOngoingRide ? Colors.grey[600] : AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.passengerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: hasOngoingRide ? Colors.grey[600] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_filled, 
                                    size: 12, 
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ride.distance,
                                    style: TextStyle(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${ride.fare.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: hasOngoingRide ? Colors.grey : AppTheme.primary,
                        ),
                      ),
                      Text(
                        'Est. Earning',
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.w600,
                          color: hasOngoingRide ? Colors.grey : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (hasOngoingRide) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange[800]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You must complete your current ride before accepting a new one.',
                          style: TextStyle(
                            fontSize: 13, 
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location details will be shared once you accept the request.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (isLoading || hasOngoingRide) 
                          ? null 
                          : () => rejectRide(ride.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasOngoingRide ? Colors.grey : Colors.red[600],
                        side: BorderSide(
                          color: hasOngoingRide ? Colors.grey[300]! : Colors.red[400]!,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Decline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (isLoading || hasOngoingRide) 
                          ? null 
                          : () => acceptRide(ride.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasOngoingRide ? Colors.grey[300] : AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: hasOngoingRide ? 0 : 4,
                        shadowColor: AppTheme.primary.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasOngoingRide ? Icons.lock : Icons.check_circle_outline, 
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasOngoingRide ? 'Busy' : 'Accept Ride', 
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> rejectRide(String requestId) async {
    FCMService.stopRequestSound();
    if (authToken == null) {
      await _loadToken();
      if (authToken == null) {
        _showErrorSnackbar('Please login to continue');
        return;
      }
    }

    setState(() => isLoading = true);
    
    // 🎵 Stop the request sound immediately when rejecting
    FCMService.stopRequestSound();

    final result = await NonVehicleAuthService.rejectRide(authToken!, requestId);

    if (result['success']) {
      _showSuccessSnackbar(result['message']);
      setState(() {
        rideRequests.removeWhere((r) => r.id == requestId);
        rejectedRideIds.add(requestId); // 🆕 Track so it doesn't ring again
      });
    } else {
      if (result['message']?.toLowerCase().contains('token') ?? false) {
        await _tokenManager.handleInvalidToken();
      } else {
        _showErrorSnackbar(result['message']);
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> completeRide(OngoingRide ride) async {
    print('🔵 completeRide() called for ride: ${ride.id}');
    
    if (authToken == null) {
      await _loadToken();
      if (authToken == null) {
        _showErrorSnackbar('Please login to continue');
        return;
      }
    }

    final TextEditingController otpController = TextEditingController();

    final enteredOtp = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[700], size: 28),
                  const SizedBox(width: 12),
                  const Text('Complete Ride?'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm that the ride is complete. Payment will be processed from passenger wallet.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[50]!, Colors.green[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.person, size: 20, color: Colors.green[700]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride.passengerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Passenger',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.green[300]),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.green[700]),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Duration',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ride.distance,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.currency_rupee, size: 18, color: Colors.green[700]),
                                    Text(
                                      ride.fare.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Payment will be deducted from passenger\'s wallet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // OTP Text Field for Completion
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.green[700],
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter 6-digit OTP to Complete',
                        hintText: '------',
                        hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 8),
                        counterText: '',
                        prefixIcon: const Icon(Icons.security, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    print('❌ User cancelled complete ride');
                    Navigator.of(context).pop(null);
                  },
                  child: Text(
                    'Not Yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: otpController.text.length == 6
                      ? () {
                          print('✅ User confirmed complete ride with OTP');
                          Navigator.of(context).pop(otpController.text);
                        }
                      : null,
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text(
                    'Complete Ride',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );

    print('🔍 Dialog result: $enteredOtp');

    if (enteredOtp != null && enteredOtp.length == 6) {
      setState(() => isLoading = true);
      print('🚀 Calling API to complete ride with wallet payment...');

      final result = await NonVehicleAuthService.completeRide(
        authToken!, 
        ride.id,
        'wallet',
        enteredOtp,
      );

      print('📦 API Response: $result');

      if (result['success']) {
        final responseData = result['data'];
        final message = responseData['message'] ?? 'Ride completed and payment successful';
        
        _showSuccessSnackbar('🎉 $message');
        print('✅ $message');
        
        setState(() {
          ongoingRides.removeWhere((r) => r.id == ride.id);
          if (ongoingRides.isEmpty) {
            driverStatus = 'online';
          }
          print('✅ Ongoing rides count: ${ongoingRides.length}');
        });
        
        await _saveOngoingRidesToStorage();
        _showEarningsSummary(ride);
        fetchRideRequests();
      } else {
        print('❌ Failed to complete ride: ${result['message']}');
        if (result['message']?.toLowerCase().contains('token') ?? false) {
          await _tokenManager.handleInvalidToken();
        } else {
          _showErrorSnackbar(result['message'] ?? 'Failed to complete ride');
        }
      }

      setState(() => isLoading = false);
    } else {
      print('⚠️ User did not confirm or cancelled');
    }
  }

  void _showEarningsSummary(OngoingRide ride) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ride Completed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment processed successfully',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'You Earned',
                      style: TextStyle(
                        color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.currency_rupee,
                        color: Colors.white,
                        size: 32,
                      ),
                      Text(
                        ride.fare.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    Icons.access_time,
                    'Duration',
                    ride.distance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    Icons.account_balance_wallet,
                    'Payment',
                    'Wallet',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Great!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildSummaryItem(IconData icon, String label, String value) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
  // 🆕 START RIDE FUNCTION
  Future<void> startRide(OngoingRide ride) async {
  if (authToken == null) {
    await _loadToken();
    if (authToken == null) {
      _showErrorSnackbar('Please login to continue');
      return;
    }
  }

  final TextEditingController otpController = TextEditingController();
  
  final otpResult = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.play_circle_outline, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('Start Ride?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please enter the 6-digit OTP from the passenger to start this ride.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter 6-digit OTP',
                    prefixIcon: const Icon(Icons.security),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton.icon(
                onPressed: otpController.text.length == 6
                    ? () => Navigator.of(context).pop(otpController.text)
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        }
      );
    },
  );

  if (otpResult != null && otpResult.length == 6) {
    setState(() => isLoading = true);

    final result = await NonVehicleAuthService.startRide(
      authToken!,
      ride.id,
      otpResult, // Use the typed OTP, not ride.otp
    );

    if (result['success']) {
      _showSuccessSnackbar('🎉 Ride started successfully!');
      
      final rideData = result['data']['ride'];
      
      setState(() {
        final index = ongoingRides.indexWhere((r) => r.id == ride.id);
        if (index != -1) {
          ongoingRides[index] = OngoingRide(
            id: rideData['_id'],
            passengerName: ride.passengerName,
            passengerPhone: ride.passengerPhone,
            pickup: ride.pickup,
            dropoff: ride.dropoff,
            distance: ride.distance,
            fare: ride.fare,
            status: rideData['status'],
            otp: rideData['otp'],
            estimatedTime: ride.estimatedTime,
            rating: ride.rating,
          );
        }
      });
      
      // 🆕 UPDATE STORAGE WITH NEW STATUS
      await _saveOngoingRidesToStorage();
    } else {
      if (result['message']?.toLowerCase().contains('token') ?? false) {
        await _tokenManager.handleInvalidToken();
      } else {
        _showErrorSnackbar(result['message'] ?? 'Failed to start ride');
      }
    }

    setState(() => isLoading = false);
  }
}

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
      title: const Text(''),
      backgroundColor: AppTheme.primary,
      elevation: 0,
      // Hamburger icon automatically show hoga
    ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: fetchRideRequests,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Header with Floating Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary, width: 2),
                              ),
                              child: const CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                backgroundImage: AssetImage("assets/images/logo.png"), // Can replace with profile pic
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Text(
                                  'Driver Partner',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Floating Status Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                                spreadRadius: -4,
                              ),
                            ],
                            border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 1),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: driverStatus == 'online'
                                              ? AppTheme.primary
                                              : (driverStatus == 'offline' ? Colors.red : Colors.orange),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (driverStatus == 'online'
                                                      ? AppTheme.primary
                                                      : (driverStatus == 'offline' ? Colors.red : Colors.orange))
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Current Status',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: driverStatus == 'online'
                                          ? AppTheme.primary.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      driverStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: driverStatus == 'online' ? AppTheme.primary : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (driverStatus == 'online') return;
                                        setState(() {
                                          driverStatus = 'online';
                                          isLoading = true;
                                        });

                                        try {
                                          final position = await LocationService.getCurrentLocation();
                                          await NonVehicleAuthService.updateDriverAvailability(
                                            authToken!,
                                            true,
                                            lat: position?.latitude,
                                            lng: position?.longitude,
                                          );
                                        } catch (e) {
                                          print('Server update failed: $e');
                                        }

                                        await _saveStatusToStorage('online');
                                        fetchRideRequests();
                                        _startPolling();
                                        setState(() => isLoading = false);

                                        try {
                                          Get.find<NonVehicleAuthController>().setOnlineStatus(true);
                                        } catch (e) {}
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: driverStatus == 'online'
                                            ? AppTheme.primary
                                            : Colors.grey[100],
                                        foregroundColor: driverStatus == 'online'
                                            ? Colors.white
                                            : Colors.grey[600],
                                        elevation: driverStatus == 'online' ? 4 : 0,
                                        shadowColor: AppTheme.primary.withOpacity(0.4),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text('Go Online', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (driverStatus == 'offline') return;
                                        setState(() {
                                          driverStatus = 'offline';
                                          isLoading = true;
                                          rideRequests = [];
                                        });
                                        SoundManager().stopRequestSound();
                                        _stopPolling();

                                        try {
                                          await NonVehicleAuthService.updateDriverAvailability(
                                            authToken!,
                                            false,
                                          );
                                        } catch (e) {
                                          print('Server update failed: $e');
                                        }

                                        await _saveStatusToStorage('offline');
                                        setState(() => isLoading = false);

                                        try {
                                          Get.find<NonVehicleAuthController>().setOnlineStatus(false);
                                        } catch (e) {}
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: driverStatus == 'offline'
                                            ? Colors.red[600]
                                            : Colors.grey[100],
                                        foregroundColor: driverStatus == 'offline'
                                            ? Colors.white
                                            : Colors.grey[600],
                                        elevation: driverStatus == 'offline' ? 4 : 0,
                                        shadowColor: Colors.red.withOpacity(0.4),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text('Go Offline', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      
                  // Quick Stats
                  // Padding(
                  //   padding: const EdgeInsets.all(16),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: _buildStatCard(
                  //           '₹1,250',
                  //           "Today's Earnings",
                  //           Colors.green[600]!,
                  //         ),
                  //       ),
                  //       const SizedBox(width: 12),
                  //       Expanded(
                  //         child: _buildStatCard(
                  //           '8',
                  //           "Today's Trips",
                  //           AppTheme.primary,
                  //         ),
                  //       ),
                  //       const SizedBox(width: 12),
                  //       Expanded(
                  //         child: _buildStatCard(
                  //           '4.7⭐',
                  //           'Your Rating',
                  //           Colors.amber[700]!,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
      
                  // Ongoing Rides
                  if (ongoingRides.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.navigation, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Ongoing Rides',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...ongoingRides.map((ride) => _buildOngoingRideCard(ride)),
                        ],
                      ),
                    ),
      
                  // Ride Requests
                  if (rideRequests.isNotEmpty && driverStatus == 'online')
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'New Ride Requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, color: AppTheme.primary),
                                onPressed: fetchRideRequests,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...rideRequests.map((ride) => _buildRideRequestCard(ride)),
                        ],
                      ),
                    ),
      
                  // No requests message
                  if (rideRequests.isEmpty && driverStatus == 'online' && !isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No ride requests available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
      
                  // Trip History Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TripHistoryScreennonvehichle(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Trip History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SocialMediaLinksEnhanced(),

                      const ContactInfoSection(),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
            
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🆕 PREMIUM ONGOING RIDE CARD
  Widget _buildOngoingRideCard(OngoingRide ride) {
    final isStarted = ride.status == 'started';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isStarted ? Colors.blue[400]! : AppTheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isStarted ? Colors.blue : AppTheme.primary).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isStarted ? Colors.blue : AppTheme.primary).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: isStarted ? Colors.blue[700] : AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.passengerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            ride.passengerPhone,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isStarted 
                        ? [Colors.blue[400]!, Colors.blue[700]!]
                        : [AppTheme.primary.withOpacity(0.8), AppTheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isStarted ? Colors.blue : AppTheme.primary).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isStarted ? Icons.navigation_rounded : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isStarted ? 'IN PROGRESS' : 'ACCEPTED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildLocationRow(
              Icons.location_on_rounded, 
              'Pickup Location', 
              ride.pickup, 
              isStarted ? Colors.blue[600]! : AppTheme.primary
            ),
          ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final destination = Uri.encodeComponent(ride.pickup);
                    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving');
                    if (await canLaunchUrl(googleMapsUrl)) {
                      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open Maps')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Navigate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (isStarted) {
                            completeRide(ride);
                          } else {
                            startRide(ride);
                          }
                        },
                  icon: Icon(
                    isStarted ? Icons.flag_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isStarted ? 'Complete' : 'Start Ride', 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStarted ? AppTheme.primary : Colors.blue[600],
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: (isStarted ? AppTheme.primary : Colors.blue).withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  
  
  Widget _buildLocationRow(IconData icon, String label, String location, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                location,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}