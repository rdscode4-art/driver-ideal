import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class KYCDocumentsViewerController extends GetxController {
  final storage = GetStorage();

  // API endpoint
  final String baseUrl = 'https://backend.ridealmobility.com';

  // Observable variables
  var aadhaarNumber = ''.obs;
  var aadhaarImages = <String>[].obs;
  var drivingLicenseNumber = ''.obs;
  var dlImage = ''.obs;
  var vehicleNumber = ''.obs;
  var vehicleType = ''.obs;
  var vehicleName = ''.obs;
  var vehicleImage = ''.obs;
  var vehicleRC = ''.obs;
  var vehicleInsurance = ''.obs;
  var status = ''.obs;
  var submittedAt = ''.obs;

  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDocuments();
  }

  // Get token from storage
  String? getToken() {
    final token = storage.read('auth_token');
    print("🔑 Retrieved token: $token");
    return token;
  }

  // Get authenticated headers
  Map<String, String> getAuthHeaders() {
    final token = getToken();
    if (token == null) {
      throw Exception("⚠️ No auth token available");
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch KYC documents from API
  Future<void> fetchDocuments() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await http.get(
        Uri.parse('$baseUrl/verification/status'),
        headers: getAuthHeaders(),
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final verification = jsonResponse['verification'];
          final kyc = jsonResponse['kyc'];

          print('🔍 Verification data: $verification');
          print('🔍 KYC data: $kyc');

          /* ---------------- STATUS ---------------- */
          // Priority: verification.status > verificationStatus > kyc.status
          status.value =
              verification?['status'] ??
              jsonResponse['verificationStatus'] ??
              kyc?['status'] ??
              'unknown';

          print('✅ Status set to: ${status.value}');

          /* ---------------- DATES ---------------- */
          if (verification?['submittedAt'] != null) {
            try {
              final date = DateTime.parse(verification['submittedAt']);
              submittedAt.value = DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(date);
            } catch (e) {
              print('⚠️ Date parse error: $e');
              submittedAt.value = '';
            }
          }

          /* ---------------- PERSONAL DOCUMENT NUMBERS ---------------- */
          // Get from KYC object (newly uploaded data)
          aadhaarNumber.value = kyc?['aadhaarNumber'] ?? '';
          drivingLicenseNumber.value = kyc?['licenseNumber'] ?? '';

          print('📋 Aadhaar: ${aadhaarNumber.value}');
          print('📋 License: ${drivingLicenseNumber.value}');

          /* ---------------- IMAGES FROM KYC ---------------- */
          // Clear existing images
          aadhaarImages.clear();

          // Handle Aadhaar images array
          if (kyc?['aadhaarImage'] != null) {
            if (kyc['aadhaarImage'] is List) {
              for (var img in kyc['aadhaarImage']) {
                final formattedUrl = _formatImageUrl(img.toString());
                if (formattedUrl.isNotEmpty) {
                  aadhaarImages.add(formattedUrl);
                  print('✅ Added Aadhaar image: $formattedUrl');
                }
              }
            }
          }

          // Other images
          dlImage.value = _formatImageUrl(kyc?['licenseImage'] ?? '');
          vehicleImage.value = _formatImageUrl(kyc?['vehicleImage'] ?? '');
          vehicleRC.value = _formatImageUrl(kyc?['rcImage'] ?? '');
          vehicleInsurance.value = _formatImageUrl(
            kyc?['insuranceImage'] ?? '',
          );

          print('🖼️ DL Image: ${dlImage.value}');
          print('🖼️ Vehicle Image: ${vehicleImage.value}');
          print('🖼️ RC Image: ${vehicleRC.value}');
          print('🖼️ Insurance Image: ${vehicleInsurance.value}');

          /* ---------------- VEHICLE INFO ---------------- */
          // Check both verification and kyc objects for vehicle info
          vehicleNumber.value =
              verification?['vehicleNumber'] ?? kyc?['vehicleNumber'] ?? '';

          vehicleType.value =
              verification?['vehicleType'] ?? kyc?['vehicleType'] ?? '';

          vehicleName.value =
              verification?['vehicleName'] ?? kyc?['vehicleName'] ?? '';

          print('🚗 Vehicle Number: ${vehicleNumber.value}');
          print('🚗 Vehicle Type: ${vehicleType.value}');
          print('🚗 Vehicle Name: ${vehicleName.value}');

          print('✅ KYC documents loaded successfully');
          print('📊 Total Aadhaar images: ${aadhaarImages.length}');
        } else {
          hasError.value = true;
          errorMessage.value = jsonResponse['message'] ?? 'No KYC data found';
          print('❌ API returned success: false');
        }
      } else if (response.statusCode == 401) {
        hasError.value = true;
        errorMessage.value = 'Session expired. Please login again.';
        print('❌ 401 Unauthorized');
      } else if (response.statusCode == 404) {
        hasError.value = true;
        errorMessage.value =
            'No KYC documents found. Please submit your documents first.';
        print('❌ 404 Not Found');
      } else {
        hasError.value = true;
        errorMessage.value = 'Failed to load documents. Please try again.';
        print('❌ Error status code: ${response.statusCode}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error. Please check your connection.';
      print('💥 Exception in fetchDocuments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to format image URLs
  String _formatImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) {
      print('⚠️ Empty image URL');
      return '';
    }

    print('🔄 Formatting URL: $imageUrl');

    // If already a full URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('✅ Already full URL: $imageUrl');
      return imageUrl;
    }

    // Remove leading slash if present
    String cleanUrl = imageUrl;
    if (cleanUrl.startsWith('/')) {
      cleanUrl = cleanUrl.substring(1);
    }

    // Prepend base URL
    final formattedUrl = '$baseUrl/$cleanUrl';
    print('✅ Formatted URL: $formattedUrl');
    return formattedUrl;
  }

  // Format Aadhaar number with masking
  String get maskedAadhaar {
    if (aadhaarNumber.value.isEmpty) return 'Not Available';
    if (aadhaarNumber.value.length <= 8) return aadhaarNumber.value;

    final length = aadhaarNumber.value.length;
    final lastFour = aadhaarNumber.value.substring(length - 4);
    return 'XXXX-XXXX-$lastFour';
  }

  // Format DL number with masking
  String get maskedDL {
    if (drivingLicenseNumber.value.isEmpty) return 'Not Available';
    if (drivingLicenseNumber.value.length <= 4) {
      return drivingLicenseNumber.value;
    }

    final firstFour = drivingLicenseNumber.value.substring(0, 4);
    final maskedPart = '*' * (drivingLicenseNumber.value.length - 4);
    return '$firstFour$maskedPart';
  }

  // Get status color for UI
  Color getStatusColor() {
    switch (status.value.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return const Color(0xFF4CAF50); // Green
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'rejected':
      case 'failed':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  // Get status icon for UI
  IconData getStatusIcon() {
    switch (status.value.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'rejected':
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Get status display text
  String getStatusText() {
    switch (status.value.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return 'Verified';
      case 'pending':
        return 'Pending Verification';
      case 'rejected':
      case 'failed':
        return 'Rejected';
      default:
        return 'Unknown Status';
    }
  }
}
