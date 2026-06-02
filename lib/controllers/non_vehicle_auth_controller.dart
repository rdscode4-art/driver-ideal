import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideal_driver/core/storage_helper.dart';
import 'package:rideal_driver/core/token_manager.dart';
import 'package:rideal_driver/routes/app_pages.dart';
import 'package:rideal_driver/core/utils/app_snackbar.dart';

class NonVehicleAuthController extends GetxController {
  final storage = GetStorage();
  var isLoading = false.obs;

  final String baseUrl =
      'https://backend.ridealmobility.com/api/non-vehicle-driver';

  // 📍 Location Tracking Variables
  Timer? _locationTimer;
  Position? _lastSentPosition;
  bool _isTracking = false;

  @override
  void onInit() {
    super.onInit();
    // Start tracking if already logged in AND was online
    bool isNonVehicle = storage.read('is_non_vehicle_driver') == true;
    bool wasOnline = storage.read('non_vehicle_online_status') == true;
    
    if (isNonVehicle && getToken() != null && wasOnline) {
      startLocationTracking();
    }
  }

  /// Update driver's online status and toggle tracking accordingly
  void setOnlineStatus(bool online) {
    storage.write('non_vehicle_online_status', online);
    if (online) {
      startLocationTracking(forceImmediate: true); // Force immediate upload when going online
    } else {
      stopLocationTracking();
    }
  }

  @override
  void onClose() {
    stopLocationTracking();
    super.onClose();
  }

  /// Start periodic location tracking (every 6 seconds)
  void startLocationTracking({bool forceImmediate = false}) {
    if (_isTracking) {
      if (forceImmediate) {
        _checkAndUploadLocation(force: true);
      }
      return;
    }
    
    print('📍 Starting background location tracking for non-vehicle driver...');
    _isTracking = true;

    // 🆕 Upload immediately if requested
    if (forceImmediate) {
      _checkAndUploadLocation(force: true);
    }
    
    _locationTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      await _checkAndUploadLocation();
    });
  }

  /// Stop location tracking
  void stopLocationTracking() {
    print('🛑 Stopping location tracking...');
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
  }

  /// Core logic: Check current location and upload if moved > 100m
  Future<void> _checkAndUploadLocation({bool force = false}) async {
    try {
      // 1. Check if we have permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return;
      }

      // 2. Get current position
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 3. Check movement (100m threshold)
      if (!force && _lastSentPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastSentPosition!.latitude, 
          _lastSentPosition!.longitude, 
          currentPosition.latitude, 
          currentPosition.longitude
        );
        
        print('📍 Current distance from last update: ${distance.toStringAsFixed(2)}m');
        
        if (distance < 100) {
          // Haven't moved 100m yet
          return;
        }
      }

      // 4. Call Update API
      await updateLocation(currentPosition.latitude, currentPosition.longitude);
      
      // 5. Update last known position
      _lastSentPosition = currentPosition;
      
    } catch (e) {
      print('❌ Error in location tracking tick: $e');
    }
  }

  /// API Call to update location
  Future<void> updateLocation(double lat, double lng) async {
    try {
      final token = getToken();
      if (token == null) return;

      print('📤 Updating non-vehicle location: $lat, $lng');

      final response = await http.post(
        Uri.parse('$baseUrl/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Location updated successfully');
      } else {
        print('⚠️ Location update failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Location update error: $e');
    }
  }

  String? getToken() {
    final token = storage.read('auth_token');
    print("🔑 Retrieved token: $token");
    return token;
  }

  Future<bool> checkPhoneRegistration(String phone) async {
    try {
      isLoading.value = true;

      print('🔍 Checking if phone is registered using login API...');
      print('📞 Phone: $phone');

      final response = await http.post(
        Uri.parse('$baseUrl/login/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      isLoading.value = false;

      if (response.statusCode == 200) {
        print('✅ Phone is registered - OTP sent');
        return true;
      } else if (response.statusCode == 404 || response.statusCode == 400) {
        var jsonResponse = json.decode(response.body);
        String message = jsonResponse['message'] ?? '';

        if (message.toLowerCase().contains('not found') ||
            message.toLowerCase().contains('not registered') ||
            message.toLowerCase().contains('does not exist')) {
          print('⚠️ Phone not registered - New user');
          return false;
        }

        print('⚠️ Unknown error, treating as new user');
        return false;
      } else {
        print('⚠️ Could not check registration status, treating as new user');
        return false;
      }
    } catch (e) {
      print('❌ Error checking phone registration: $e');
      isLoading.value = false;
      return false;
    }
  }

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

  // ⭐ REUPLOAD KYC: For rejected drivers who need to re-submit documents
  Future<bool> reuploadKyc({
    required String dl,
    required String dlType, // ⭐ NEW
    required String aadhaar,
    required File dlImage,
    required File aadhaarFrontImage,
    required File aadhaarBackImage,
    required File videoKyc,
  }) async {
    try {
      isLoading.value = true;

      print('🔄 Starting KYC re-upload...');

      final token = getToken();
      if (token == null) {
        showErrorSnackBar('Not logged in. Please login again.', title: 'Error');
        isLoading.value = false;
        return false;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/reupload-kyc'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['dl'] = dl;
      request.fields['dlType'] = dlType; // ⭐ NEW
      request.fields['aadhaar'] = aadhaar;

      // Add DL image
      request.files.add(await http.MultipartFile.fromPath(
        'dlImage',
        dlImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      // Add Aadhaar front image
      request.files.add(await http.MultipartFile.fromPath(
        'aadhaarImage',
        aadhaarFrontImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      // Add Aadhaar back image
      request.files.add(await http.MultipartFile.fromPath(
        'aadhaarImage',
        aadhaarBackImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      // Add video KYC
      String videoPath = videoKyc.path.toLowerCase();
      String videoMimeType = videoPath.endsWith('.mov') ? 'video/quicktime'
          : videoPath.endsWith('.avi') ? 'video/x-msvideo'
          : videoPath.endsWith('.mkv') ? 'video/x-matroska'
          : 'video/mp4';

      request.files.add(await http.MultipartFile.fromPath(
        'videoKyc',
        videoKyc.path,
        contentType: MediaType.parse(videoMimeType),
      ));

      print('📤 Sending reupload request with ${request.files.length} files...');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Reupload Status: ${response.statusCode}');
      print('📥 Reupload Body: ${response.body}');

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Future.delayed(const Duration(milliseconds: 300), () {
          showSuccessSnackBar(
            'Your documents have been re-submitted for review.',
            title: '✅ Re-upload Successful',
          );
        });
        isLoading.value = false;
        return true;
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          showErrorSnackBar(
            jsonResponse['message'] ?? 'Something went wrong. Please try again.',
            title: 'Re-upload Failed',
          );
        });
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      print('❌ Reupload error: $e');
      showErrorSnackBar('Failed to re-upload documents: $e', title: 'Error');
      isLoading.value = false;
      return false;
    }
  }

  // ⭐ UPDATED: Register with 2 Aadhaar images
  Future<bool> register({
    required String name,
    required String phone,
    required String age,
    required String gender,
    required String dl,
    required String dlType, // ⭐ NEW
    required String aadhaar,
    required File dlImage,
    required File aadhaarFrontImage, // ⭐ CHANGED: Front image
    required File aadhaarBackImage, // ⭐ NEW: Back image
    required File profileImage,
    required File videoKyc,
  }) async {
    try {
      isLoading.value = true;

      print('🚀 Starting registration with 2 Aadhaar images and video KYC...');
      print('📞 Phone: $phone');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register'),
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['phone'] = phone;
      request.fields['age'] = age;
      request.fields['gender'] = gender;
      request.fields['dl'] = dl;
      request.fields['dlType'] = dlType; // ⭐ NEW
      request.fields['aadhaar'] = aadhaar;

      print('✅ Fields added');

      // Add DL image
      var dlFile = await http.MultipartFile.fromPath(
        'dlImage',
        dlImage.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(dlFile);
      print('✅ DL image added');

      // ⭐ UPDATED: Add Aadhaar front image
      var aadhaarFrontFile = await http.MultipartFile.fromPath(
        'aadhaarImage', // First aadhaarImage
        aadhaarFrontImage.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(aadhaarFrontFile);
      print('✅ Aadhaar front image added');

      // ⭐ NEW: Add Aadhaar back image (same field name for array)
      var aadhaarBackFile = await http.MultipartFile.fromPath(
        'aadhaarImage', // Second aadhaarImage (backend expects array)
        aadhaarBackImage.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(aadhaarBackFile);
      print('✅ Aadhaar back image added');

      // Add profile image
      var profileFile = await http.MultipartFile.fromPath(
        'profileImage',
        profileImage.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(profileFile);
      print('✅ Profile image added');

      // Add video KYC
      String videoPath = videoKyc.path.toLowerCase();
      String videoMimeType = 'video/mp4';

      if (videoPath.endsWith('.mp4')) {
        videoMimeType = 'video/mp4';
      } else if (videoPath.endsWith('.mov')) {
        videoMimeType = 'video/quicktime';
      } else if (videoPath.endsWith('.avi')) {
        videoMimeType = 'video/x-msvideo';
      } else if (videoPath.endsWith('.mkv')) {
        videoMimeType = 'video/x-matroska';
      }

      var videoFile = await http.MultipartFile.fromPath(
        'videoKyc',
        videoKyc.path,
        contentType: MediaType.parse(videoMimeType),
      );
      request.files.add(videoFile);

      print('✅ Video KYC added with MIME type: $videoMimeType');
      print(
        '📊 Video file size: ${(await videoKyc.length()) / (1024 * 1024)} MB',
      );
      print(
        '📤 Sending request with ${request.files.length} files (3 images + 1 profile + 1 video)...',
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        storage.write('pending_phone', phone);

        Future.delayed(const Duration(milliseconds: 300), () {
          showSuccessSnackBar(
            'OTP sent successfully!',
            title: 'Success',
          );
        });

        isLoading.value = false;
        return true;
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          showErrorSnackBar(
            jsonResponse['message'] ?? 'Something went wrong',
            title: 'Registration Failed',
          );
        });
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      print('❌ Error: $e');
      Future.delayed(const Duration(milliseconds: 100), () {
        showErrorSnackBar(
          'Failed to register: $e',
          title: 'Error',
        );
      });
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> requestLoginOtp(String phone) async {
    try {
      isLoading.value = true;

      print('🚀 Requesting login OTP...');
      print('📞 Phone: $phone');

      final response = await http.post(
        Uri.parse('$baseUrl/login/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone}),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        storage.write('pending_phone', phone);

        print('✅ OTP sent successfully!');

        showSuccessSnackBar('OTP sent successfully!');

        isLoading.value = false;
        return true;
      } else {
        print('❌ Failed to send OTP: ${response.statusCode}');

        showErrorSnackBar(jsonResponse['message'] ?? 'Failed to send OTP', title: 'Failed');
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      print('❌ Exception occurred: $e');

      showErrorSnackBar('Failed to send OTP: $e');
      isLoading.value = false;
      return false;
    }
  }

  Future<String> _checkVerificationStatus() async {
    try {
      print('🔍 Checking verification status...');

      final tokenManager = Get.find<TokenManager>();
      await Future.delayed(const Duration(milliseconds: 500));

      final driverId = tokenManager.userId.value;
      final token = tokenManager.authToken.value;

      print('🆔 Driver ID: $driverId');
      print('🔑 Token available: ${token != null}');

      if (driverId == null ||
          driverId.isEmpty ||
          token == null ||
          token.isEmpty) {
        print('❌ No driver ID or token found');
        return 'pending';
      }

      final url =
          'https://backend.ridealmobility.com/api/non-vehicle-driver/profile/$driverId';
      print('📤 Fetching verification status from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Verification Status Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String verificationStatus = 'pending';

        if (data['driver'] != null && data['driver']['status'] != null) {
          verificationStatus = data['driver']['status']
              .toString()
              .toLowerCase();
        } else if (data['status'] != null) {
          verificationStatus = data['status'].toString().toLowerCase();
        } else if (data['verificationStatus'] != null) {
          verificationStatus = data['verificationStatus']
              .toString()
              .toLowerCase();
        }

        print('📊 Verification Status: $verificationStatus');
        return verificationStatus;
      } else {
        print('❌ Failed to fetch verification status: ${response.statusCode}');
        return 'pending';
      }
    } catch (e) {
      print('❌ Error checking verification status: $e');
      return 'pending';
    }
  }

  Future<bool> verifyOtp(String phone, String otp, bool isLogin) async {
    try {
      isLoading.value = true;
      print('🚀 Verifying OTP...');
      print('📞 Phone: $phone');
      print('🔢 OTP: $otp');

      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print('🔔 FCM Token: $fcmToken');

      String endpoint = isLogin
          ? '$baseUrl/login/verify-otp'
          : '$baseUrl/verify-otp';

      final requestBody = {
        'phone': phone,
        'otp': otp,
        'fcmToken': fcmToken ?? '',
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        if (jsonResponse['token'] != null) {
          final token = jsonResponse['token'];
          final userData = jsonResponse['driver'] ?? {};
          userData['role'] = 'non-vehicle-driver';

          final tokenManager = Get.find<TokenManager>();
          await tokenManager.updateToken(token, userData: userData);
          print('✅ Token saved via TokenManager with role: non-vehicle-driver');
          print('✅ User ID: ${tokenManager.userId.value}');
        }

        if (jsonResponse['driver'] != null) {
          final driverMap = jsonResponse['driver'] as Map<String, dynamic>;
          storage.write('driver_data', driverMap);
          await StorageHelper.saveUserData(json.encode(driverMap));
          await StorageHelper.saveDriverProfile(driverMap);
        }

        storage.write('is_non_vehicle_driver', true);

        showSuccessSnackBar(isLogin ? 'Login successful!' : 'Registration successful!');

        isLoading.value = false;

        // 📍 Start location tracking right after login/registration
        startLocationTracking();

        await _checkVerificationAndNavigate();

        return true;
      } else {
        showErrorSnackBar(jsonResponse['message'] ?? 'Invalid OTP', title: 'Verification Failed');
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      showErrorSnackBar('Failed to verify OTP: $e');
      isLoading.value = false;
      return false;
    }
  }

  Future<void> _checkVerificationAndNavigate() async {
    try {
      print('🔍 Starting verification and navigation check...');

      final verificationStatus = await _checkVerificationStatus();

      print('📊 Verification Status: $verificationStatus');

      if (verificationStatus == 'approved' ||
          verificationStatus == 'accepted' ||
          verificationStatus == 'active') {
        print('✅ Verification approved, checking subscription...');
        await _checkSubscriptionAndNavigate();
      } else if (verificationStatus == 'rejected' ||
          verificationStatus == 'declined') {
        print('❌ Verification rejected - Navigating to pending screen to show reason');
        Get.offAllNamed('/verification-pending');
      } else {
        print('⏳ Verification pending');
        Get.offAllNamed('/verification-pending');
      }
    } catch (e) {
      print('❌ Error in verification check: $e');
      Get.offAllNamed('/verification-pending');
    }
  }

  Future<void> _checkSubscriptionAndNavigate() async {
    try {
      print('🔍 Checking subscription status...');

      final tokenManager = Get.find<TokenManager>();
      await Future.delayed(const Duration(milliseconds: 500));

      final driverId = tokenManager.userId.value;
      final token = tokenManager.authToken.value;

      print('🆔 Driver ID: $driverId');
      print('🔑 Token available: ${token != null}');

      if (driverId == null || driverId.isEmpty) {
        print('❌ No driver ID found, navigating to subscription screen');
        Get.offAllNamed('/non-vehicle-subscription');
        return;
      }

      if (token == null || token.isEmpty) {
        print('❌ No token found, navigating to subscription screen');
        Get.offAllNamed('/non-vehicle-subscription');
        return;
      }

      final url =
          'https://backend.ridealmobility.com/api/non-vehicle-driver/status/$driverId';
      print('📤 Fetching subscription status from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Subscription Status Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status =
            data['status']?.toString().toLowerCase() ?? 'not_subscribed';

        print('📊 Subscription Status: $status');

        if (status == 'active') {
          print('✅ Subscription is active, navigating to dashboard');
          Get.offAllNamed(Routes.NONVEHICHLEDASHBOARD);
        } else {
          print('⚠️ No active subscription, navigating to subscription screen');
          Get.offAllNamed('/non-vehicle-subscription');
        }
      } else if (response.statusCode == 404) {
        print(
          '⚠️ No subscription found (404), navigating to subscription screen',
        );
        Get.offAllNamed('/non-vehicle-subscription');
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized (401) - Token might be invalid');
        Get.offAllNamed('/non-vehicle-subscription');
      } else {
        print('❌ Failed to fetch subscription status: ${response.statusCode}');
        Get.offAllNamed('/non-vehicle-subscription');
      }
    } catch (e) {
      print('❌ Error checking subscription: $e');
      print('⚠️ Navigating to subscription screen due to error');
      Get.offAllNamed('/non-vehicle-subscription');
    }
  }
}
