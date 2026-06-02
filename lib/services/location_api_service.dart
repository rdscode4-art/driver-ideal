import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';
import '../data/models/location_detection_model.dart';

class LocationApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  /// Auto-detect location based on coordinates
  static Future<Map<String, dynamic>> autoDetectLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      // Get the auth token
      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Construct the API URL with query parameters
      final url = Uri.parse('$baseUrl/location/auto-detect?lat=$lat&lng=$lng');

      // Make the API call
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Handle the response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Create location model from response
        final locationModel = LocationDetectionModel.fromJson(responseData);

        return {
          'success': true,
          'data': locationModel,
          'message': 'Location detected successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to detect location. Status: ${response
              .statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Auto-detect location for passenger (wrapper method for clarity)
  static Future<Map<String, dynamic>> autoDetectPassengerLocation({
    required double lat,
    required double lng,
  }) async {
    return await autoDetectLocation(lat: lat, lng: lng);
  }

/// Get nearest vehicles based on coordinates
//   static Future<Map<String, dynamic>> getNearestVehicles({
//     required double lat,
//     required double lng,
//   }) async {
//     try {
//       // Get the auth token
//       final token = await StorageHelper.getAuthToken();
//       if (token == null || token.isEmpty) {
//         return {
//           'success': false,
//           'message': 'Authentication token not found',
//         };
//       }
//
//       // Construct the API URL with query parameters
//       final url = Uri.parse('$baseUrl/rides/nearest-vehicles?lat=$lat&lng=$lng');
//
//       // Make the API call
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       // Handle the response
// //       if (response.statusCode == 200) {
// //         final Map<String, dynamic> responseData = json.decode(response.body);
// //
// //         // Create nearest vehicles response model
// //         final vehiclesResponse = NearestVehiclesResponse.fromJson(responseData);
// //
// //         return {
// //           'success': true,
// //           'data': vehiclesResponse,
// //           'message': 'Nearest vehicles fetched successfully',
// //         };
// //       } else if (response.statusCode == 401) {
// //         return {
// //           'success': false,
// //           'message': 'Authentication failed. Please login again.',
// //         };
// //       } else {
// //         return {
// //           'success': false,
// //           'message': 'Failed to fetch nearest vehicles. Status: ${response.statusCode}',
// //         };
// //       }
// //     } catch (e) {
// //       return {
// //         'success': false,
// //         'message': 'Network error: $e',
// //       };
// //     }
// //   }
// // }
}