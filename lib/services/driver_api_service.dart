import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../core/storage_helper.dart';

class DriverApiService {
  static final ApiService _apiService = ApiService();

  // Get driver profile from the correct endpoint
  static Future<ApiResponse> getDriverProfile() async {
    try {
      return await _apiService.get('/auth/driver-profile');
    } catch (e) {
      return ApiResponse.error('Failed to get driver profile: ${e.toString()}');
    }
  }

  // Update driver profile using the correct endpoint
  static Future<ApiResponse> updateDriverProfile(Map<String, dynamic> profileData) async {
    try {
      return await _apiService.put('/auth/driver-profile', body: profileData);
    } catch (e) {
      return ApiResponse.error('Failed to update driver profile: ${e.toString()}');
    }
  }

  // Update driver status (online/offline)
  static Future<ApiResponse> updateDriverStatus(String status) async {
    try {
      return await _apiService.patch('/driver/status', body: {
        'status': status,
      });
    } catch (e) {
      return ApiResponse.error('Failed to update driver status: ${e.toString()}');
    }
  }

  // Get driver availability status
  static Future<ApiResponse> getDriverStatus() async {
    try {
      return await _apiService.get('/status');
    } catch (e) {
      return ApiResponse.error('Failed to get driver status: ${e.toString()}');
    }
  }

  // Update driver availability status (new PATCH API)
  static Future<ApiResponse> updateDriverAvailability({
  required bool isAvailable,
  required double lat,
  required double lng,
}) async {
  try {
    return await _apiService.patch(
      '/driver-status',
      body: {
        "isAvailable": isAvailable,
        "lat": lat,
        "lng": lng,
      },
    );
  } catch (e) {
    return ApiResponse.error(
      'Failed to update driver availability: ${e.toString()}',
    );
  }
}

  static Future<ApiResponse> loadKycStatus() async {
    try {
      return await _apiService.get('/driver/kyc/status');
    } catch (e) {
      return ApiResponse.error('Failed to load KYC status: ${e.toString()}');
    }
  }
  
  // Update driver location with resilience and fallbacks
  static Future<ApiResponse> updateDriverLocation(
    double latitude,
    double longitude,
  ) async {
    final body = {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Candidates: [Path, Method]
    final candidates = [
      ['/driver/location', 'PATCH'],
      ['/api/driver/location', 'PATCH'],
      ['/driver/location', 'POST'],
      ['/api/driver/location', 'POST'],
    ];

    ApiResponse? lastError;

    for (var candidate in candidates) {
      final path = candidate[0];
      final method = candidate[1];
      
      try {
        ApiResponse response;
        if (method == 'PATCH') {
          response = await _apiService.patch(path, body: body);
        } else {
          response = await _apiService.post(path, body: body);
        }

        if (response.isSuccess) {
          print('✅ Location update successful via $method $path');
          return response;
        }
        
        lastError = response;
        print('⚠️ Location update failed via $method $path: ${response.message}');
      } catch (e) {
        print('❌ Error updating location via $method $path: $e');
      }
    }

    return lastError ?? ApiResponse.error('All location update candidates failed');
  }

  // Get driver statistics
  static Future<ApiResponse> getDriverStatistics({
    String? period,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (period != null) queryParams['period'] = period;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      return await _apiService.get('/driver/statistics', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get driver statistics: ${e.toString()}');
    }
  }

  // Upload driver documents
  static Future<ApiResponse> uploadDocument(
    String documentType,
    File documentFile,
  ) async {
    try {
      return await _apiService.uploadFile(
        '/driver/documents/upload',
        documentFile,
        'document',
        additionalFields: {
          'document_type': documentType,
        },
      );
    } catch (e) {
      return ApiResponse.error('Failed to upload document: ${e.toString()}');
    }
  }

  // Get document verification status
  static Future<ApiResponse> getDocumentStatus() async {
    try {
      return await _apiService.get('/driver/documents/status');
    } catch (e) {
      return ApiResponse.error('Failed to get document status: ${e.toString()}');
    }
  }

  // Submit feedback
  static Future<ApiResponse> submitFeedback(Map<String, dynamic> feedbackData) async {
    try {
      return await _apiService.post('/feedback/submit', body: feedbackData);
    } catch (e) {
      return ApiResponse.error('Failed to submit feedback: ${e.toString()}');
    }
  }

  // Get feedback history
  static Future<ApiResponse> getFeedbackHistory() async {
    try {
      return await _apiService.get('/feedback/history');
    } catch (e) {
      return ApiResponse.error('Failed to get feedback history: ${e.toString()}');
    }
  }

  // Update vehicle information
  static Future<ApiResponse> updateVehicleInfo(Map<String, dynamic> vehicleData) async {
    try {
      return await _apiService.put('/driver/vehicle', body: vehicleData);
    } catch (e) {
      return ApiResponse.error('Failed to update vehicle info: ${e.toString()}');
    }
  }

  // Get driver ratings and reviews
  static Future<ApiResponse> getDriverRatings({
    int? page,
    int? limit,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      return await _apiService.get('/driver/ratings', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get driver ratings: ${e.toString()}');
    }
  }

  // Get driver notifications
  static Future<ApiResponse> getNotifications({
    bool? unreadOnly,
    int? page,
    int? limit,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly.toString();
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      return await _apiService.get('/driver/notifications', queryParams: queryParams);
    } catch (e) {
      return ApiResponse.error('Failed to get notifications: ${e.toString()}');
    }
  }

  // Mark notification as read
  static Future<ApiResponse> markNotificationAsRead(String notificationId) async {
    try {
      return await _apiService.patch('/driver/notifications/$notificationId/read');
    } catch (e) {
      return ApiResponse.error('Failed to mark notification as read: ${e.toString()}');
    }
  }

  // KYC Verification Methods

  // Get KYC verification status
  static Future<ApiResponse> getKycVerificationStatus() async {
    try {
      return await _apiService.get('/api/driver/kyc/status');
    } catch (e) {
      return ApiResponse.error('Failed to get KYC verification status: ${e.toString()}');
    }
  }

  // Upload KYC document
  static Future<ApiResponse> uploadKycDocument(String documentType, String filePath) async {
    try {
      final file = File(filePath);
      return await _apiService.uploadFile(
        '/api/driver/kyc/upload-document',
        file,
        'document',
        additionalFields: {
          'document_type': documentType,
        },
      );
    } catch (e) {
      return ApiResponse.error('Failed to upload KYC document: ${e.toString()}');
    }
  }

  // Submit KYC verification for review
  static Future<ApiResponse> submitKycVerification() async {
    try {
      return await _apiService.post('/api/driver/kyc/submit', body: {
        'submitted_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ApiResponse.error('Failed to submit KYC verification: ${e.toString()}');
    }
  }

  // Submit all KYC documents in one request using existing endpoint
  static Future<ApiResponse> submitAllKycDocuments({
    required String aadhaarNumber,
    required String drivingLicenseNumber,
    required String vehicleNumber,
    required String vehicleType,
    required String vehicleName,
    required File aadhaarImage,
    required File drivingLicenseImage,
    required File vehicleImage,
    required File vehicleRCImage,
    required File vehicleInsuranceImage,
  }) async {
    try {
      // Get auth token
      final token = await StorageHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Authentication token not found');
      }

      print('📤 Starting KYC document submission (all in one) to: https://ride.bhoomi.cloud/verification/submit');
      print('🔑 Using auth token: ${token.substring(0, 10)}...');
      print('📋 Form data - Aadhaar: $aadhaarNumber, License: $drivingLicenseNumber, Vehicle: $vehicleNumber');

      var request = http.MultipartRequest('POST', Uri.parse('https://ride.bhoomi.cloud/verification/submit'));

      // Add auth headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['aadhaarNumber'] = aadhaarNumber;
      request.fields['drivingLicenseNumber'] = drivingLicenseNumber;
      request.fields['vehicleNumber'] = vehicleNumber;
      request.fields['vehicleType'] = vehicleType;
      request.fields['vehicleName'] = vehicleName;

      print('📎 Adding file attachments...');

      // Add file fields with validation
      if (await aadhaarImage.exists()) {
        request.files.add(await http.MultipartFile.fromPath('aadhaarPic', aadhaarImage.path));
        print('📄 Aadhaar image added: ${aadhaarImage.path}');
      } else {
        return ApiResponse.error('Aadhaar image file not found');
      }

      if (await drivingLicenseImage.exists()) {
        request.files.add(await http.MultipartFile.fromPath('drivingLicensePic', drivingLicenseImage.path));
        print('📄 Driving license image added: ${drivingLicenseImage.path}');
      } else {
        return ApiResponse.error('Driving license image file not found');
      }

      if (await vehicleImage.exists()) {
        request.files.add(await http.MultipartFile.fromPath('vehicleImage', vehicleImage.path));
        print('📄 Vehicle image added: ${vehicleImage.path}');
      } else {
        return ApiResponse.error('Vehicle image file not found');
      }

      if (await vehicleRCImage.exists()) {
        request.files.add(await http.MultipartFile.fromPath('vehicleRC', vehicleRCImage.path));
        print('📄 Vehicle RC image added: ${vehicleRCImage.path}');
      } else {
        return ApiResponse.error('Vehicle RC image file not found');
      }

      if (await vehicleInsuranceImage.exists()) {
        request.files.add(await http.MultipartFile.fromPath('vehicleInsurance', vehicleInsuranceImage.path));
        print('📄 Vehicle insurance image added: ${vehicleInsuranceImage.path}');
      } else {
        return ApiResponse.error('Vehicle insurance image file not found');
      }

      print('🚀 Sending KYC submission request...');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 KYC Submission API Response: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          print('✅ KYC documents submitted successfully');
          return ApiResponse.success(data);
        } catch (jsonError) {
          print('⚠️ JSON parsing error for success response: $jsonError');
          return ApiResponse.success({'response': response.body});
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          print('❌ KYC submission failed: ${errorData['message']}');
          return ApiResponse.error(errorData['message'] ?? 'Server error occurred', response.statusCode);
        } catch (jsonError) {
          print('❌ Non-JSON error response: ${response.body}');
          return ApiResponse.error('Server error (${response.statusCode}). Please try again.', response.statusCode);
        }
      }
    } catch (e) {
      print('💥 KYC submission exception: $e');
      return ApiResponse.error('Failed to submit all KYC documents: ${e.toString()}');
    }
  }

  // Get driver wallet information
  static Future<ApiResponse> getDriverWallet() async {
    try {
      return await _apiService.get('/driver/wallet');
    } catch (e) {
      return ApiResponse.error('Failed to get driver wallet: ${e.toString()}');
    }
  }

  // Get minimum withdrawal amount settings
  static Future<ApiResponse> getMinimumWithdrawalAmount() async {
    try {
      return await _apiService.get('/api/admin/withdrawal-settings/minimum');
    } catch (e) {
      return ApiResponse.error('Failed to get minimum withdrawal amount: ${e.toString()}');
    }
  }
}
