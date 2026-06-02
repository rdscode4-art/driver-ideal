import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/earnings_model.dart';

class EarningsService {
  // API Base URL
  static const String baseUrl = 'https://backend.ridealmobility.com';
  
  // API Endpoints
  static const String earningsEndpoint = '/driver/earnings';
  static const String walletEndpoint = '/driver/wallet';
  static const String payoutEndpoint = '/driver/payout';
  static const String payoutHistoryEndpoint = '/driver/payout/history';

  /// Get authentication token from SharedPreferences
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  /// Get common headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Fetch earnings data from API
  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final headers = await _getHeaders();
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl$earningsEndpoint'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Parse earnings data from API response
          final earningsData = data['earnings'];
          
          final earnings = Earnings(
            total: (earningsData['total'] ?? 0).toDouble(),
            today: (earningsData['today'] ?? 0).toDouble(),
            week: (earningsData['week'] ?? 0).toDouble(),
            month: (earningsData['month'] ?? 0).toDouble(),
          );

          return {
            'success': true,
            'earnings': earnings,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch earnings',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          // 'success': false,
          // 'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Earnings data not found.',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode}). Please try again later.',
        };
      }
    } catch (e) {
      print('Error fetching earnings: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Fetch wallet data from API
  Future<Map<String, dynamic>> getWalletData() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl$walletEndpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data, // Return the whole data object
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Failed to fetch wallet data',
      };
    } catch (e) {
      print('Error fetching wallet data: $e');
      return {
        'success': false,
        'message': 'Network error',
      };
    }
  }

  /// Request payout
  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> payoutData) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl$payoutEndpoint'),
        headers: headers,
        body: json.encode(payoutData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Payout requested successfully',
          'data': data['data'],
        };
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid payout request',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to process payout request',
        };
      }
    } catch (e) {
      print('Error requesting payout: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  /// Get payout history
  Future<Map<String, dynamic>> getPayoutHistory() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl$payoutHistoryEndpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'] ?? [],
          };
        }
      }
      
      return {
        'success': false,
        'data': [],
      };
    } catch (e) {
      print('Error fetching payout history: $e');
      return {
        'success': false,
        'data': [],
      };
    }
  }

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Error saving auth token: $e');
    }
  }

  /// Clear authentication token
  Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      print('Error clearing auth token: $e');
    }
  }
}