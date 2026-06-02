import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/storage_helper.dart';
import '../services/geocoding_service.dart';
import '../data/models/navigation_response.dart';

class GoogleRouteData {
  final List<LatLng> points;
  final String distance;
  final String duration;

  GoogleRouteData({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

class NavigationApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com';
  static const String googleApiKey = 'AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI';
  
  /// Get navigation data between two points
  Future<Map<String, dynamic>> getNavigationData({
    required String origin,
    required String destination,
  }) async {
    try {
      log('🗺️ Fetching navigation data from $origin to $destination');
      
      final token = await StorageHelper.getAuthToken();
      
      final originCoords = await _parseLocationToCoordinates(origin);
      final destinationCoords = await _parseLocationToCoordinates(destination);

      if (originCoords == null || destinationCoords == null) {
        return {'success': false, 'message': 'Could not resolve coordinates'};
      }

      // 1. Fetch from Google First (More reliable for routing)
      final googleData = await _fetchGoogleRouteData(originCoords, destinationCoords);

      // 2. Fetch from Backend (For any specific business logic if needed)
      final url = Uri.https(
        'backend.ridealmobility.com',
        '/location/navigation',
        {'from': originCoords, 'to': destinationCoords},
      );

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      NavigationResponse? backendNav;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        backendNav = NavigationResponse.fromJson(data);
      }

      // 3. Combine Data: Prioritize Google for points/dist/dur if backend is weak
      final finalNav = NavigationResponse(
        origin: backendNav?.origin ?? originCoords,
        destination: backendNav?.destination ?? destinationCoords,
        distance: (backendNav?.distance != null && backendNav!.distance.isNotEmpty) 
            ? backendNav.distance 
            : (googleData?.distance ?? ''),
        duration: (backendNav?.duration != null && backendNav!.duration.isNotEmpty) 
            ? backendNav.duration 
            : (googleData?.duration ?? ''),
        points: googleData?.points,
      );

      return {'success': true, 'data': finalNav};
    } catch (e) {
      log('❌ Navigation API error: $e');
      return {'success': false, 'message': 'Navigation service unavailable'};
    }
  }

  /// Get navigation data for a specific ride
  Future<Map<String, dynamic>> getRideNavigationData(String rideId, {bool isToDropoff = false}) async {
    try {
      final token = await StorageHelper.getAuthToken();
      final url = Uri.https('backend.ridealmobility.com', '/location/ride-navigation/$rideId');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        String? dist, dur, origin, dest;
        
        if (isToDropoff) {
          final dropoffData = data['navigationToDropoff'] ?? data['dropoff'];
          dist = dropoffData?['distance']?.toString();
          dur = dropoffData?['duration']?.toString();
          origin = data['driverLocation'] != null ? "${data['driverLocation']['lat']},${data['driverLocation']['lng']}" : "";
          dest = data['dropoff'] != null ? data['dropoff']['coordString']?.toString() : "";
        } else {
          final pickupData = data['navigationToPickup'] ?? data['pickup'];
          dist = pickupData?['distance']?.toString();
          dur = pickupData?['duration']?.toString();
          origin = data['driverLocation'] != null ? "${data['driverLocation']['lat']},${data['driverLocation']['lng']}" : "";
          dest = data['pickup'] != null ? data['pickup']['coordString']?.toString() : "";
        }

        // Fetch from Google for high-res route and reliable dist/dur
        GoogleRouteData? googleData;
        if (origin != null && dest != null && origin.isNotEmpty && dest.isNotEmpty) {
          googleData = await _fetchGoogleRouteData(origin, dest);
        }

        final navResponse = NavigationResponse(
          origin: origin ?? "",
          destination: dest ?? "",
          distance: (dist != null && dist.isNotEmpty && dist != "Unknown distance") ? dist : (googleData?.distance ?? ""),
          duration: (dur != null && dur.isNotEmpty && dur != "Unknown duration") ? dur : (googleData?.duration ?? ""),
          points: googleData?.points,
        );

        return {'success': true, 'data': navResponse};
      }
      return {'success': false, 'message': 'Backend error'};
    } catch (e) {
      log('❌ Ride Navigation API error: $e');
      return {'success': false, 'message': 'Service unavailable'};
    }
  }

  /// Fetch route data from Google Directions API
  Future<GoogleRouteData?> _fetchGoogleRouteData(String origin, String destination) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$googleApiKey'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'];
          final leg = route['legs'][0];
          
          final points = _decodePolyline(polyline);
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];
          
          print('✅ Google Directions: Success ($distance, $duration, ${points.length} points)');
          return GoogleRouteData(points: points, distance: distance, duration: duration);
        } else {
          print('⚠️ Google Directions: ${data['status']}');
        }
      }
    } catch (e) {
      log('⚠️ Google Directions API error: $e');
    }
    return null;
  }

  /// Decode Google encoded polyline string
  List<LatLng> _decodePolyline(String poly) {
    var list = poly.codeUnits;
    var lList = <double>[];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift);
        index++;
        shift += 5;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) {
      lList[i] += lList[i - 2];
    }

    var res = <LatLng>[];
    for (var i = 0; i < lList.length; i += 2) {
      res.add(LatLng(lList[i], lList[i + 1]));
    }
    return res;
  }

  Future<String?> _parseLocationToCoordinates(String location) async {
    if (RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(location)) return location;
    final coords = await GeocodingService.getCoordinatesFromAddress(location);
    if (coords['lat'] != null && coords['lng'] != null) return '${coords['lat']},${coords['lng']}';
    return null;
  }
}
