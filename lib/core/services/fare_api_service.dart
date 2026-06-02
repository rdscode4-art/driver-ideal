// lib/services/fare_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FareApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com/api';

  /// Fetch fare rates and vehicle types from API
  static Future<Map<String, dynamic>> getFareRates() async {
    try {
      print('🚗 Fetching fare rates from API...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/fare'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Fare API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ Fare rates fetched successfully');
          return {
            'success': true,
            'fareRates': data['fareRates'] ?? {},
            'vehicleImages': data['vehicleImages'] ?? {},
          };
        } else {
          print('❌ Fare API returned success: false');
          return {
            'success': false,
            'message': 'Failed to fetch fare rates',
          };
        }
      } else {
        print('❌ Fare API error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 Exception in getFareRates: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get list of available vehicle types
  static Future<List<String>> getVehicleTypes() async {
    try {
      final response = await getFareRates();
      
      if (response['success'] == true) {
        final fareRates = response['fareRates'] as Map<String, dynamic>;
        final vehicleTypes = fareRates.keys.toList();
        
        print('🚙 Available vehicle types: $vehicleTypes');
        return vehicleTypes;
      }
      
      // Return default types if API fails
      print('⚠️ Using default vehicle types');
      return ['sedan', 'suv', 'auto', 'bike', 'ev'];
    } catch (e) {
      print('❌ Error getting vehicle types: $e');
      return ['sedan', 'suv', 'auto', 'bike', 'ev'];
    }
  }

  /// Get formatted vehicle type name for display
  static String getVehicleTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'sedan':
        return 'Sedan';
      case 'sedan_ac':
        return 'Sedan AC';
      case 'suv':
        return 'SUV';
      case 'suv_ac':
        return 'SUV AC';
      case 'auto':
        return 'Auto';
      case 'bike':
        return 'Bike';
      case 'ev':
        return 'EV';
      case 'hatchback':
        return 'Hatchback';
      default:
        return type.toUpperCase();
    }
  }

  /// Get fare rate for specific vehicle type
  static Future<Map<String, dynamic>?> getFareRateForType(String vehicleType) async {
    try {
      final response = await getFareRates();
      
      if (response['success'] == true) {
        final fareRates = response['fareRates'] as Map<String, dynamic>;
        return fareRates[vehicleType.toLowerCase()] as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting fare rate for $vehicleType: $e');
      return null;
    }
  }
}