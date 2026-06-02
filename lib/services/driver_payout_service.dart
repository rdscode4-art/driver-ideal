import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';

class DriverPayoutService {
  // Base URL - using backend.ridealmobility.com (SSL works)
  static const String baseUrl =
      'https://backend.ridealmobility.com/api/driver-payouts/vehicle';

  /// Request a payout/withdrawal (Step 1 - Sends OTP)
  static Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required String payoutMethod,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
  }) async {
    try {
      print('💰 Requesting payout: Amount: $amount, Method: $payoutMethod');

      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found for payout request');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final url = Uri.parse('$baseUrl/request');
      print('📤 POST URL: $url');

      // Build request body based on payout method
      Map<String, dynamic> body;
      
      if (payoutMethod == 'UPI') {
        body = {
          'amount': amount,
          'payoutMethod': payoutMethod,
          'upiId': upiId,
        };
        print('📦 UPI Request Body: $body');
      } else {
        body = {
          'amount': amount,
          'payoutMethod': payoutMethod,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
        };
        print('📦 BANK Request Body: $body');
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📨 Payout Request Response: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          print('✅ OTP sent successfully');
          return {
            'success': true,
            'message': data['msg'] ?? data['message'] ?? 'OTP sent to your registered mobile number',
            'data': data,
          };
        } catch (e) {
          print('❌ Failed to parse success response: $e');
          return {
            'success': true,
            'message': 'OTP sent to your registered mobile number'
          };
        }
      } else if (response.statusCode == 400) {
        print('⚠️ Bad request (400)');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'message': errorBody['msg'] ?? errorBody['message'] ?? 'Invalid request data',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid request. Please check your details.',
          };
        }
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Insufficient balance or withdrawal not allowed',
        };
      } else if (response.statusCode == 503) {
        print('⚠️ Server temporarily unavailable (503)');
        return {
          'success': false,
          'message':
              'Server is temporarily unavailable. Please try again later.',
        };
      } else {
        print('❌ Payout request failed with status: ${response.statusCode}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'message': errorBody['msg'] ?? errorBody['message'] ?? 'Failed to request withdrawal',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Server error (${response.statusCode}). Please try again later.',
          };
        }
      }
    } catch (e) {
      print('💥 Payout request exception: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify OTP and complete payout (Step 2)
  static Future<Map<String, dynamic>> verifyPayoutOTP({
    required String otp,
    required double amount,
    required String payoutMethod,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
  }) async {
    try {
      print('🔐 Verifying OTP for payout...');

      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found for OTP verification');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final url = Uri.parse('https://backend.ridealmobility.com/api/driver-payouts/driver/payout-verify-otp');
      print('📤 POST URL: $url');

      // Build request body based on payout method
      Map<String, dynamic> body;
      
      if (payoutMethod == 'UPI') {
        body = {
          'otp': otp,
          'amount': amount,
          'payoutMethod': payoutMethod,
          'upiId': upiId,
        };
        print('📦 UPI Verify Body: $body');
      } else {
        body = {
          'otp': otp,
          'amount': amount,
          'payoutMethod': payoutMethod,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
        };
        print('📦 BANK Verify Body: $body');
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📨 OTP Verification Response: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          print('✅ Payout completed successfully');
          return {
            'success': true,
            'message': data['msg'] ?? data['message'] ?? 'Withdrawal request submitted successfully',
            'data': data,
          };
        } catch (e) {
          print('❌ Failed to parse success response: $e');
          return {
            'success': true,
            'message': 'Withdrawal request submitted successfully'
          };
        }
      } else if (response.statusCode == 400) {
        print('⚠️ Bad request (400) - Invalid OTP or data');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'message': errorBody['msg'] ?? errorBody['message'] ?? 'Invalid OTP or request data',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid OTP. Please try again.',
          };
        }
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Insufficient balance or withdrawal not allowed',
        };
      } else if (response.statusCode == 503) {
        print('⚠️ Server temporarily unavailable (503)');
        return {
          'success': false,
          'message':
              'Server is temporarily unavailable. Please try again later.',
        };
      } else {
        print('❌ OTP verification failed with status: ${response.statusCode}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'message': errorBody['msg'] ?? errorBody['message'] ?? 'Failed to verify OTP',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Server error (${response.statusCode}). Please try again later.',
          };
        }
      }
    } catch (e) {
      print('💥 OTP verification exception: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get all payout requests (history and status)
  static Future<Map<String, dynamic>> getMyPayouts() async {
    try {
      print('📋 Fetching payout history...');

      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final url = Uri.parse('$baseUrl/my');
      print('📤 GET URL: $url');

      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 30));

      print('📨 Payout History Response: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('✅ Payout history fetched successfully');
          return {'success': true, 'data': data};
        } catch (e) {
          print('❌ Failed to parse response: $e');
          return {'success': false, 'message': 'Failed to parse response'};
        }
      } else if (response.statusCode == 503) {
        print('⚠️ Server temporarily unavailable (503)');
        return {
          'success': false,
          'message':
              'Server is temporarily unavailable. Please try again later.',
        };
      } else {
        print('❌ Failed to fetch payouts: ${response.statusCode}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'message':
                errorBody['msg'] ?? errorBody['message'] ?? 'Failed to fetch withdrawal history',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Server error (${response.statusCode}). Please try again later.',
          };
        }
      }
    } catch (e) {
      print('💥 Fetch payouts exception: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}