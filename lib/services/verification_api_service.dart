import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/storage_helper.dart';

class VerificationApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  /// Get verification status from API
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      print('🔍 Fetching verification status from API...');

      final response = await http.get(
        Uri.parse('$baseUrl/verification/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📱 Verification status API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Verification status fetched successfully: ${data['status']}');
        return data;
      } else if (response.statusCode == 404) {
        // No verification data found - new user
        print('⚠️ No verification data found (404) - new user');
        return {
          'success': false,
          'message': 'No verification data found',
          'status': 'not_submitted',
        };
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message':
              'Failed to fetch verification status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Network error fetching verification status: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Submit verification documents to the API
  Future<Map<String, dynamic>> submitVerification({
    required String aadhaarNumber,
    required String aadhaarImagePath,
    required String drivingLicenseNumber,
    required String drivingLicenseImagePath,
    required String vehicleNumber,
    required String vehicleType,
    required String vehicleName,
    required String vehicleImagePath,
    required String vehicleRCPath,
    required String vehicleInsurancePath,
  }) async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/verification'),
      );

      // Add headers
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Add form fields
      request.fields['aadhaarNumber'] = aadhaarNumber;
      request.fields['drivingLicenseNumber'] = drivingLicenseNumber;
      request.fields['vehicleNumber'] = vehicleNumber;
      request.fields['vehicleType'] = vehicleType;
      request.fields['vehicleName'] = vehicleName;

      // Add image files
      request.files.add(
        await http.MultipartFile.fromPath('aadhaarPic', aadhaarImagePath),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'drivingLicensePic',
          drivingLicenseImagePath,
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath('vehicleImage', vehicleImagePath),
      );
      request.files.add(
        await http.MultipartFile.fromPath('vehicleRC', vehicleRCPath),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicleInsurance',
          vehicleInsurancePath,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorData['message'] ?? 'Failed to submit verification documents',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
