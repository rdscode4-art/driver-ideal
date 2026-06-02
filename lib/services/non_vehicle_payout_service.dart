import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';

class NonVehiclePayoutService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  /// Request a payout/withdrawal (Step 1 - Sends OTP)
 /// Request a payout/withdrawal (Step 1 - Sends OTP)
static Future<Map<String, dynamic>> requestPayout({
  required double amount,
  required String payoutMethod, // ⭐ ADD THIS PARAMETER
  String? accountNumber,         // ⭐ ADD THIS
  String? ifscCode,              // ⭐ ADD THIS
  String? upiId,                 // ⭐ ADD THIS
}) async {
  try {
    print('💰 Requesting non-vehicle payout: Amount: $amount');
    print('💳 Payout Method: $payoutMethod');

    final token = await StorageHelper.getAuthToken();
    if (token == null || token.isEmpty) {
      print('❌ No auth token found for payout request');
      return {'success': false, 'message': 'Authentication token not found'};
    }

    final url = Uri.parse('$baseUrl/api/driver-payouts/nonvehicle/request');
    print('📤 POST URL: $url');

    // ⭐ BUILD REQUEST BODY WITH PAYOUT METHOD
    final body = {
      'amount': amount,
      'payoutMethod': payoutMethod, // ⭐ BANK or UPI
    };

    // ⭐ ADD BANK DETAILS IF PROVIDED
    if (payoutMethod == 'BANK') {
      if (accountNumber != null && accountNumber.isNotEmpty) {
        body['accountNumber'] = accountNumber;
      }
      if (ifscCode != null && ifscCode.isNotEmpty) {
        body['ifscCode'] = ifscCode;
      }
    }
    
    // ⭐ ADD UPI ID IF PROVIDED
    if (payoutMethod == 'UPI') {
      if (upiId != null && upiId.isNotEmpty) {
        body['upiId'] = upiId;
      }
    }

    print('📦 Request Body: $body');

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
    } else if (response.statusCode == 401) {
      print('❌ Unauthorized (401)');
      try {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'message': errorBody['msg'] ?? errorBody['message'] ?? 'Session expired',
        };
      } catch (e) {
        return {
          // 'success': false,
          // 'message': 'Session expired. Please login again.',
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
        'message': 'Server is temporarily unavailable. Please try again later.',
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
          'message': 'Server error (${response.statusCode}). Please try again later.',
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
  String? accountNumber,
  String? ifscCode,
  String? upiId,
}) async {
  try {
    print('🔐 Verifying OTP for non-vehicle payout...');

    final token = await StorageHelper.getAuthToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Authentication token not found'};
    }

    final url = Uri.parse(
      '$baseUrl/api/driver-payouts/nonvehicle-driver/payout-verify-otp',
    );

    /// 🔴 Decide payout method properly
    final bool isUpi = upiId != null && upiId.isNotEmpty;

    final Map<String, dynamic> body = {
      'otp': otp,
      'amount': amount,
      'payoutMethod': isUpi ? 'UPI' : 'BANK',
    };

    if (isUpi) {
      body['upiId'] = upiId;
    } else {
      body['accountNumber'] = accountNumber;
      body['ifscCode'] = ifscCode;
    }

    print('📦 Verify Body: $body');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    print('📨 OTP Verification Response: ${response.statusCode}');
    print('📨 Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message':
            data['msg'] ?? data['message'] ?? 'Withdrawal successful',
        'data': data,
      };
    }

    if (response.statusCode == 400) {
      final data = json.decode(response.body);
      return {
        'success': false,
        'message': data['msg'] ?? 'Invalid OTP or payout data',
      };
    }

    if (response.statusCode == 403) {
      return {
        'success': false,
        'message': 'Insufficient balance or withdrawal not allowed',
      };
    }

    return {
      'success': false,
      'message': 'Server error (${response.statusCode})',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: ${e.toString()}',
    };
  }
}

  /// Get all payout requests (history and status)
  static Future<Map<String, dynamic>> getMyPayouts() async {
    try {
      print('📋 Fetching non-vehicle payout history...');

      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final url = Uri.parse('$baseUrl/api/driver-payouts/nonvehicle/my');
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
          'message': 'Server is temporarily unavailable. Please try again later.',
        };
      } else {
        print('❌ Failed to fetch payouts: ${response.statusCode}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'message': errorBody['msg'] ?? errorBody['message'] ?? 'Failed to fetch withdrawal history',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error (${response.statusCode}). Please try again later.',
          };
        }
      }
    } catch (e) {
      print('💥 Fetch payouts exception: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}