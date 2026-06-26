import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:rideal_driver/core/storage_helper.dart';
import '../ride.dart';
import '../data/models/driver_location_response.dart';

class RidesApiService {
  // ✅ FIXED: Ensure HTTPS is used consistently
  static const String baseUrl = 'https://backend.ridealmobility.com';
  
  // ✅ Add timeout duration for all requests
  static const Duration requestTimeout = Duration(seconds: 30);

  Future<String?> _getAuthToken() async {
    try {
      final token = await StorageHelper.getAuthToken();
      return token;
    } catch (e) {
      log('Error getting auth token: $e');
      return null;
    }
  }

  /// ✅ Helper method to build safe URIs with HTTPS
  Uri _buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    // Remove leading slash if present
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    
    return Uri.https(
      'backend.ridealmobility.com',
      '/$path',
      queryParameters,
    );
  }

  /// ✅ Helper method for making GET requests with proper error handling
  Future<http.Response> _makeGetRequest(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final uri = _buildUri(path, queryParameters: queryParameters);
    print('🌐 [GET] $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(requestTimeout);

      print('📥 [STATUS] ${response.statusCode}');
      print('📥 [BODY] ${response.body}');

      return response;
    } catch (e) {
      print('❌ [GET FAILED] $e');
      rethrow;
    }
  }

  /// ✅ Helper method for making POST requests with proper error handling
  Future<http.Response> _makePostRequest(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final uri = _buildUri(path);
    print('🌐 [POST] $uri');
    print('📤 [REQUEST BODY] ${json.encode(body)}');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(requestTimeout);

      print('📥 [STATUS] ${response.statusCode}');
      print('📥 [BODY] ${response.body}');

      return response;
    } catch (e) {
      print('❌ [POST FAILED] $e');
      rethrow;
    }
  }

  /// ✅ NEW: Get ride status - properly using HTTPS
  Future<Map<String, dynamic>> getRideStatus(String rideId) async {
    try {
      final response = await _makeGetRequest('rides/status/$rideId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'message': data['message'] ?? 'Ride status retrieved successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch ride status',
        };
      }
    } catch (e) {
      log('❌ Error fetching ride status: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> getAvailableRides() async {
    try {
      final response = await _makeGetRequest('rides/rides/available');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ridesData = data['rides'] as List<dynamic>? ?? [];
        final rides = ridesData
            .map((rideJson) => Ride.fromJson(rideJson))
            .toList();

        return {'success': true, 'rides': rides, 'total': rides.length};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch available rides',
        };
      }
    } catch (e) {
      log('Error fetching available rides: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    try {
      final response = await _makePostRequest(
        'rides/rides/accept',
        {'rideId': rideId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['ride'] != null) {
          log('🔍 RAW RIDE DATA FROM API: ${json.encode(data['ride'])}');
          log('🔍 RAW RIDER DATA: ${json.encode(data['rider'])}');

          final rideData = Map<String, dynamic>.from(data['ride']);

          if (data['rider'] != null && data['rider'] is Map) {
            rideData['rider'] = data['rider'];
            log('✅ Merged rider data into ride object');
          }

          log('👤 Rider in rideData: ${rideData['rider']}');
          log('👤 Rider name: ${rideData['rider']?['name']}');
          log('📱 Rider phone: ${rideData['rider']?['phone']}');

          final ride = Ride.fromJson(rideData);

          log('✅ Parsed ride - Passenger Name: ${ride.passengerName}');
          log('✅ Parsed ride - Passenger Phone: ${ride.passengerPhone}');

          return {
            'success': true,
            'message': data['message'] ?? 'Ride accepted successfully',
            'ride': ride,
          };
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Ride accepted successfully',
          'ride': data['ride'] != null ? Ride.fromJson(data['ride']) : null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to accept ride',
        };
      }
    } catch (e) {
      log('Error accepting ride: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> cancelRide(String rideId) async {
    try {
      final response = await _makePostRequest(
        'rides/rides/reject',
        {'rideId': rideId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Ride cancelled successfully',
          'ride': data['ride'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Ride not found or already cancelled',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to cancel ride',
        };
      }
    } catch (e) {
      log('❌ Error cancelling ride: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> getRideById(String rideId) async {
    try {
      final response = await _makeGetRequest('rides/rides/$rideId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'ride': Ride.fromJson(data['ride'])};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch ride details',
        };
      }
    } catch (e) {
      log('Error fetching ride by ID: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> startRide(String rideId, String otp) async {
    try {
      final response = await _makePostRequest(
        'rides/rides/start',
        {'rideId': rideId, 'otp': otp},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Ride started successfully',
          'ride': data['ride'] != null ? Ride.fromJson(data['ride']) : null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to start ride',
        };
      }
    } catch (e) {
      log('Error starting ride: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> getOngoingRide() async {
    try {
      List<String> endpoints = [
        'driver/ongoing-ride',
      ];

      http.Response? response;
      String? workingEndpoint;

      for (String endpoint in endpoints) {
        try {
          log('🔄 Trying endpoint: $endpoint');
          response = await _makeGetRequest(endpoint);

          if (response.statusCode != 404) {
            workingEndpoint = endpoint;
            break;
          }
        } catch (e) {
          log('⚠️ Endpoint $endpoint failed: $e');
          continue;
        }
      }

      if (response == null) {
        log('❌ All endpoints failed');
        return {
          'success': false,
          'message': 'Unable to connect to ongoing ride API',
        };
      }

      log('🚗 Ongoing ride API response status: ${response.statusCode}');
      log('🚗 Ongoing ride API response body: ${response.body}');
      if (workingEndpoint != null) {
        log('✅ Working endpoint: $workingEndpoint');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Support both direct 'ride' object and 'data': {'ride': ...}
          var rideRaw = data['ride'] ?? (data['data'] != null ? data['data']['ride'] : null);
          
          if (rideRaw != null) {
            final rideData = Map<String, dynamic>.from(rideRaw);
            
            // ✨ NEW: If passenger info is in a sibling 'user' object, merge it into rideData
            if (data['user'] != null && data['user'] is Map) {
               rideData['rider'] = data['user'];
               log('👤 Merged passenger info from top-level "user" object into ride data');
            }

            log('📍 Raw ride data from API: ${json.encode(rideData)}');
            
            final pickupLat = _extractCoordinate(rideData, 'pickupLatitude');
            final pickupLng = _extractCoordinate(rideData, 'pickupLongitude');
            final dropoffLat = _extractCoordinate(rideData, 'dropoffLatitude');
            final dropoffLng = _extractCoordinate(rideData, 'dropoffLongitude');

            log('🔍 Extracted coordinates from API:');
            log('📍 Pickup: ($pickupLat, $pickupLng)');
            log('🏁 Dropoff: ($dropoffLat, $dropoffLng)');

            if (pickupLat != null) rideData['pickupLatitude'] = pickupLat;
            if (pickupLng != null) rideData['pickupLongitude'] = pickupLng;
            if (dropoffLat != null) rideData['dropoffLatitude'] = dropoffLat;
            if (dropoffLng != null) rideData['dropoffLongitude'] = dropoffLng;

            final ride = Ride.fromJson(rideData);

            log('✅ Final parsed coordinates:');
            log('📍 Pickup: (${ride.pickupLatitude}, ${ride.pickupLongitude})');
            log('🏁 Dropoff: (${ride.dropoffLatitude}, ${ride.dropoffLongitude})');
            log('👤 Parsed Passenger Name: ${ride.passengerName ?? 'NOT IN MODEL'}');

            return {
              'success': true,
              'ride': ride,
              'message': data['message'] ?? 'Ongoing ride found',
            };
          } else {
            return {
              'success': false,
              'message': data['message'] ?? 'No ongoing ride found',
              'ride': null,
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'API error',
          };
        }
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch ongoing ride',
        };
      }
    } catch (e) {
      log('❌ Error fetching ongoing ride: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  double? _extractCoordinate(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value == null) return null;

      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null && parsed != 0.0) return parsed;
      }

      if (key == 'pickupLatitude') {
        return _extractCoordinate(data, 'pickup_latitude') ??
            _extractCoordinate(data, 'pickupLat') ??
            _extractCoordinate(data, 'pickup_lat');
      }
      if (key == 'pickupLongitude') {
        return _extractCoordinate(data, 'pickup_longitude') ??
            _extractCoordinate(data, 'pickupLng') ??
            _extractCoordinate(data, 'pickup_lng');
      }
      if (key == 'dropoffLatitude') {
        return _extractCoordinate(data, 'dropoff_latitude') ??
            _extractCoordinate(data, 'dropoffLat') ??
            _extractCoordinate(data, 'dropoff_lat');
      }
      if (key == 'dropoffLongitude') {
        return _extractCoordinate(data, 'dropoff_longitude') ??
            _extractCoordinate(data, 'dropoffLng') ??
            _extractCoordinate(data, 'dropoff_lng');
      }

      return null;
    } catch (e) {
      log('❌ Error extracting coordinate $key: $e');
      return null;
    }
  }

  /// ✅ NEW: Create payment link and QR code for a ride
  Future<Map<String, dynamic>> createPaymentLink(String rideId) async {
    try {
      final token = await _getAuthToken();
      
      // LOG CURL COMMAND FOR DEBUGGING
      print('🚀 [API] REQUEST: createPaymentLink');
      print('📝 curl --location \'https://backend.ridealmobility.com/api/rides/create-payment-link\' \\');
      print('--header \'Content-Type: application/json\' \\');
      print('--header \'Authorization: Bearer $token\' \\');
      print('--data \'{"rideId":"$rideId"}\'');

      final response = await _makePostRequest(
        'api/rides/create-payment-link',
        {'rideId': rideId},
      );

      print('📥 [API] RESPONSE STATUS: ${response.statusCode}');
      print('📥 [API] RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create payment link',
        };
      }
    } catch (e) {
      log('❌ Error creating payment link: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// ✅ NEW: Verify Razorpay payment for a ride (using Get Ride Details endpoint)
  Future<Map<String, dynamic>> verifyRazorpayPayment(String rideId) async {
    try {
      final token = await _getAuthToken();

      // LOG CURL COMMAND FOR DEBUGGING
      print('🚀 [API] REQUEST: verifyRazorpayPayment (GET)');
      print('📝 curl --location \'https://backend.ridealmobility.com/rides/rides/$rideId\' \\');
      print('--header \'Authorization: Bearer $token\'');

      final response = await _makeGetRequest('rides/rides/$rideId');

      print('📥 [API] RESPONSE STATUS: ${response.statusCode}');
      print('📥 [API] RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both nested 'ride' and flat responses
        final rideData = data['ride'] ?? data;
        
        return {
          'success': true,
          'status': rideData['status'],
          'paymentStatus': rideData['paymentStatus'],
          'paymentMethod': rideData['paymentMethod'],
          'message': data['message'] ?? 'Status retrieved successfully',
          'ride': data['ride'] != null ? Ride.fromJson(data['ride']) : null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to verify payment',
        };
      }
    } catch (e) {
      log('❌ Error verifying payment: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> completeRide(String rideId) async {
    try {
      final response = await _makePostRequest(
        'rides/rides/complete',
        {'rideId': rideId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Ride completed successfully',
          'ride': data['ride'] != null ? Ride.fromJson(data['ride']) : null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to complete ride',
        };
      }
    } catch (e) {
      log('Error completing ride: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> completeRideWithPayment(
    String rideId,
    String paymentMethod,
  ) async {
    try {
      print('💳 [API SERVICE] Completing ride with payment method: $paymentMethod');
      print('💳 [API SERVICE] Ride ID: $rideId');

      final response = await _makePostRequest(
        'rides/rides/complete',
        {
          'rideId': rideId,
          'paymentMethod': paymentMethod,
        },
      );

      print('💳 [API SERVICE] Status: ${response.statusCode}');
      print('💳 [API SERVICE] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('✅ [API SERVICE] Payment method sent: $paymentMethod');
        print('✅ [API SERVICE] Backend response: ${json.encode(data)}');

        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Ride completed successfully',
          'ride': data['ride'] != null ? Ride.fromJson(data['ride']) : null,
          'requiresPayment': data['requiresPayment'] ?? false,
          'paymentMethod': paymentMethod,
          if (data['orderId'] != null) 'orderId': data['orderId'],
          if (data['paymentLinkId'] != null) 'paymentLinkId': data['paymentLinkId'],
          if (data['amount'] != null) 'amount': data['amount'],
          if (data['currency'] != null) 'currency': data['currency'],
          if (data['qrCode'] != null) 'qrCode': data['qrCode'],
          if (data['paymentLink'] != null) 'paymentLink': data['paymentLink'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to complete ride',
        };
      }
    } catch (e) {
      print('❌ [API SERVICE] Exception: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> verifyPaymentStatus(
    String rideId,
    String orderId,
  ) async {
    try {
      log('🔍 Verifying payment status for order: $orderId');

      final response = await _makePostRequest(
        'api/verifyPayment',
        {'rideId': rideId, 'orderId': orderId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Payment verified successfully',
          'paymentStatus': data['paymentStatus'],
          'ride': data['ride'] != null ? Ride.fromJson(data['ride']) : null,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Payment verification failed',
        };
      }
    } catch (e) {
      log('❌ Error verifying payment: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> rateRider({
    required String rideId,
    required int rating,
    String? comment,
  }) async {
    try {
      log('🌐 ===== API REQUEST DETAILS =====');
      log('🌐 Endpoint: POST /rides/$rideId/rate-rider');
      log('🌐 Ride ID: $rideId');
      log('🌐 Rating: $rating');
      log('🌐 Comment: $comment');

      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        log('❌ No auth token available');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      log('🔍 Checking if ride is completed...');
      final rideCheck = await getRideById(rideId);

      if (!rideCheck['success']) {
        log('❌ Could not fetch ride details');
        return {'success': false, 'message': 'Could not verify ride status'};
      }

      final ride = rideCheck['ride'] as Ride?;
      if (ride == null) {
        log('❌ Ride not found');
        return {'success': false, 'message': 'Ride not found'};
      }

      log('✅ Ride status: ${ride.status}');

      if (ride.status != 'completed') {
        log('❌ Ride is not completed yet. Current status: ${ride.status}');
        return {
          'success': false,
          'message': 'You can only rate completed rides. Current status: ${ride.status}',
        };
      }

      log('✅ Ride is completed, proceeding with rating...');

      final requestBody = {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await _makePostRequest(
        'rides/$rideId/rate-rider',
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        log('✅ Rating submitted successfully');
        log('✅ Parsed response: $data');
        return {
          'success': true,
          'message': data['message'] ?? 'Rating submitted successfully',
          'data': data,
        };
      } else {
        log('❌ Non-success status code: ${response.statusCode}');
        log('❌ Error body: ${response.body}');

        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? errorData['msg'] ?? 'Server error: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e, stackTrace) {
      log('❌ API Exception: $e');
      log('❌ Stack trace: $stackTrace');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  Future<bool> canRateRide(String rideId) async {
    try {
      final result = await getRideById(rideId);
      if (!result['success']) return false;

      final ride = result['ride'] as Ride?;
      return ride?.status == 'completed';
    } catch (e) {
      log('❌ Error checking if ride can be rated: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getTripHistory() async {
    try {
      final response = await _makeGetRequest('rides/history');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'totalRides': data['totalRides'] ?? 0,
          'rideCounts': data['rideCounts'] ?? {},
          'rides': data['rides'] ?? [],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch ride history',
        };
      }
    } catch (e) {
      log('Error fetching ride history: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> autoDetectLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _makePostRequest(
        'driver/auto-detect-location',
        {'latitude': latitude, 'longitude': longitude},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Location detected successfully',
          'rides': data['rides'] ?? [],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to auto-detect location',
        };
      }
    } catch (e) {
      log('Error auto-detecting location: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }


  /// ✅ Update driver location for a specific ride
  Future<DriverLocationResponse> updateDriverLocation({
    required String rideId,
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      final token = await _getAuthToken();
      final body = json.encode({'driverId': driverId, 'lat': lat, 'lng': lng});
      
      // Try candidate endpoints
      final endpoints = [
        'rides/$rideId/driver-location',
        'api/rides/$rideId/driver-location',
      ];

      http.Response? lastResponse;

      for (var endpoint in endpoints) {
        try {
          final uri = _buildUri(endpoint);
          log('📡 [POST] $uri');
          
          final response = await http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: body,
          ).timeout(requestTimeout);

          log('📥 Status (${endpoint}): ${response.statusCode}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            final Map<String, dynamic> data = json.decode(response.body);
            return DriverLocationResponse.fromJson(data);
          }
          
          lastResponse = response;
        } catch (e) {
          log('⚠️ Endpoint $endpoint failed: $e');
        }
      }

      if (lastResponse != null) {
        Map<String, dynamic> errorData = {};
        try {
          errorData = json.decode(lastResponse.body);
        } catch (_) {}
        
        return DriverLocationResponse(
          success: false,
          message: errorData['message'] ?? 'Server error (${lastResponse.statusCode})',
        );
      }

      return DriverLocationResponse(
        success: false,
        message: 'All location update endpoints failed',
      );
    } catch (e) {
      log('❌ Exception updating driver location: $e');
      return DriverLocationResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// ✅ NEW: Update general driver location (not ride-specific)
  Future<Map<String, dynamic>> updateDriverGeneralLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _makePostRequest(
        'driver/update-location',
        {'latitude': lat, 'longitude': lng},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Location updated successfully'};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update location',
        };
      }
    } catch (e) {
      log('❌ Error updating driver general location: $e');
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  /// ✅ Helper to provide user-friendly error messages
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please check your internet connection.';
    } else if (errorString.contains('certificate') ||
        errorString.contains('handshake')) {
      return 'Secure connection failed. Please try again.';
    } else {
      return 'Network error occurred. Please try again later.';
    }
  }

  /// ✅ NEW: Respond to a vehicle rental booking
  Future<Map<String, dynamic>> respondVehicleBooking({
    required String bookingId,
    required String action,
  }) async {
    try {
      final normalizedAction = action.toLowerCase().trim();
      if (bookingId.isEmpty ||
          (normalizedAction != 'accept' && normalizedAction != 'reject')) {
        return {'success': false, 'message': 'Invalid rental booking response action'};
      }

      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final uri = _buildUri('api/vehicle-bookings/$bookingId/respond');
      log('📡 [PATCH] $uri');

      final response = await http.patch(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"action": normalizedAction}),
      ).timeout(requestTimeout);

      log('📥 [STATUS] ${response.statusCode}');
      log('📥 [BODY] ${response.body}');

      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded is Map<String, dynamic>
            ? decoded
            : {'success': true, 'data': decoded};
      }

      final message = decoded is Map<String, dynamic> ? decoded['message']?.toString() : null;
      return {'success': false, 'message': message ?? 'Failed to respond to rental booking'};
    } catch (e) {
      log('❌ Error responding to vehicle booking: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }
}