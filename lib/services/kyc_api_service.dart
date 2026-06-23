import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../data/models/kyc_verification_model.dart';
import '../core/storage_helper.dart';

class KycApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  static Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      print(
        '🔍 Fetching KYC verification status from: $baseUrl/driver/kyc/status',
      );

      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found for KYC status check');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      print('🔑 Using auth token: ${token.substring(0, 10)}...');

      final response = await http
          .get(
            Uri.parse('$baseUrl/driver/kyc/status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📨 KYC Status API Response: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('✅ KYC status fetched successfully');
          return {
            'success': true,
            'data': KycVerificationStatusResponse.fromJson(data),
          };
        } catch (e) {
          print('❌ Failed to parse KYC response: $e');
          return {
            'success': false,
            'message': 'Failed to parse server response',
          };
        }
      } else if (response.statusCode == 404) {
        print('📋 No KYC documents found (404)');
        return {
          'success': true,
          'data': null,
          'message': 'No KYC documents found',
        };
      } else if (response.statusCode == 503) {
        print('⚠️ Server temporarily unavailable (503)');
        return {
          'success': false,
          'message':
              'Server is temporarily unavailable. Please try again later.',
        };
      } else {
        print('❌ KYC status API failed with status: ${response.statusCode}');

        if (response.body.trim().startsWith('<') ||
            response.body.trim().startsWith('<!DOCTYPE')) {
          return {
            'success': false,
            'message':
                'Server error (${response.statusCode}). Please try again later.',
          };
        }

        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'message':
                errorBody['message'] ?? 'Failed to fetch verification status',
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
      print('💥 KYC status API exception: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Submit KYC documents - UPDATED TO MATCH BACKEND EXACTLY
  /// Backend expects: aadhaarNumber, licenseNumber, vehicleNumber, vehicleType, vehicleName
  /// Files: aadhaarImage (multiple), licenseImage, vehicleImage, rcImage, insuranceImage
  static Future<Map<String, dynamic>> submitKycDocuments({
    required String aadhaarNumber,
    required String drivingLicenseNumber,
    required String vehicleNumber,
    required String vehicleType,
    required String vehicleName,
    required File aadhaarFrontImage,
    required File aadhaarBackImage,
    required File drivingLicenseImage,
    required File drivingLicenseBackPic,
    required File vehicleImage,
    required File vehicleRCImage,
    required File vehicleInsuranceImage,
  }) async {
    try {
      print('📤 Starting KYC document submission to: $baseUrl/driver/kyc/upload');
      print('📋 Submission details:');
      print('  - Aadhaar: $aadhaarNumber');
      print('  - License: $drivingLicenseNumber');
      print('  - Vehicle: $vehicleNumber');
      print('  - Vehicle Type: $vehicleType');
      print('  - Vehicle Name: $vehicleName');
      print('📋 Files being uploaded:');
      print(
        '  - Aadhaar Front: ${aadhaarFrontImage.path} (${await aadhaarFrontImage.length()} bytes)',
      );
      print(
        '  - Aadhaar Back: ${aadhaarBackImage.path} (${await aadhaarBackImage.length()} bytes)',
      );
      print(
        '  - License: ${drivingLicenseImage.path} (${await drivingLicenseImage.length()} bytes)',
      );
      print(
        '  - License Back: ${drivingLicenseBackPic.path} (${await drivingLicenseBackPic.length()} bytes)',
      );
      print(
        '  - Vehicle: ${vehicleImage.path} (${await vehicleImage.length()} bytes)',
      );
      print(
        '  - RC: ${vehicleRCImage.path} (${await vehicleRCImage.length()} bytes)',
      );
      print(
        '  - Insurance: ${vehicleInsuranceImage.path} (${await vehicleInsuranceImage.length()} bytes)',
      );

      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found for KYC submission');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      print('🔑 Using auth token: ${token.substring(0, 10)}...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/driver/kyc/upload'),
      );

      // Add authorization header
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // ✅ Add ALL text fields as per backend requirements
      request.fields.addAll({
        'aadhaarNumber': aadhaarNumber.trim(),
        'licenseNumber': drivingLicenseNumber.trim(),
        'vehicleNumber': vehicleNumber.trim(),
        'vehicleType': vehicleType.trim(),
        'vehicleName': vehicleName.trim(),
      });

      print('📄 Form fields: ${request.fields}');

      // ✅ Add Aadhaar images - both use same field name 'aadhaarImage'
      // Backend: { name: "aadhaarImage", maxCount: 5 }
      request.files.add(
        await http.MultipartFile.fromPath(
          'aadhaarImage',
          aadhaarFrontImage.path,
          filename: 'aadhaar_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'aadhaarImage',
          aadhaarBackImage.path,
          filename: 'aadhaar_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // ✅ Add license image
      // Backend: { name: "licenseImage", maxCount: 1 }
      request.files.add(
        await http.MultipartFile.fromPath(
          'licenseImage',
          drivingLicenseImage.path,
          filename: 'driving_license_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // ✅ Add license back image
      request.files.add(
        await http.MultipartFile.fromPath(
          'drivingLicenseBackPic',
          drivingLicenseBackPic.path,
          filename: 'driving_license_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // ✅ Add vehicle image
      // Backend: { name: "vehicleImage", maxCount: 1 }
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicleImage',
          vehicleImage.path,
          filename: 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // ✅ Add RC image
      // Backend: { name: "rcImage", maxCount: 1 }
      request.files.add(
        await http.MultipartFile.fromPath(
          'rcImage',
          vehicleRCImage.path,
          filename: 'vehicle_rc_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // ✅ Add insurance image
      // Backend: { name: "insuranceImage", maxCount: 1 }
      request.files.add(
        await http.MultipartFile.fromPath(
          'insuranceImage',
          vehicleInsuranceImage.path,
          filename: 'vehicle_insurance_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print('📤 Sending multipart request with ${request.files.length} files');
      print('🗂️ Files to upload:');
      for (var file in request.files) {
        print('   - ${file.field}: ${file.filename} (${file.length} bytes)');
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 KYC Submit API Response: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          print('✅ KYC documents submitted successfully');
          print('📋 Response data: $data');
          return {
            'success': true,
            'message': data['message'] ?? 'KYC documents submitted successfully',
            'data': data['data'],
          };
        } catch (e) {
          print('⚠️ Failed to parse success response: $e');
          // Still return success since status code indicates success
          return {
            'success': true,
            'message': 'KYC documents submitted successfully',
          };
        }
      } else if (response.statusCode == 503) {
        print('⚠️ Server temporarily unavailable (503)');
        return {
          'success': false,
          'message':
              'Server is temporarily unavailable. Please try again later.',
        };
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized (401) - Token might be expired');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        print('❌ KYC submit API failed with status: ${response.statusCode}');
        
        // Try to parse error message from response
        try {
          final errorBody = json.decode(response.body);
          final errorMessage = errorBody['message'] ?? 'Failed to submit KYC documents';
          print('❌ Error message: $errorMessage');
          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (e) {
          // If response is not JSON (like HTML error pages)
          print('❌ Could not parse error response: $e');
          return {
            'success': false,
            'message':
                'Server error (${response.statusCode}). Please try again later.',
          };
        }
      }
    } catch (e) {
      print('💥 KYC submit API exception: $e');
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Request timeout. Please check your internet connection and try again.',
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}