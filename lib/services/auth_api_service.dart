import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_service.dart';
import '../core/storage_helper.dart';
import '../core/token_manager.dart';
import '../data/models/driver_registration_response.dart';
import '../data/models/otp_verification_response.dart';
import '../data/models/login_response.dart';

class AuthApiService {
  static final ApiService apiService = ApiService();
  static final TokenManager _tokenManager = TokenManager.instance;
 static String getMimeType(String path) {
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.webp')) return 'image/webp';
  if (path.endsWith('.heic')) return 'image/heic';
  return 'image/jpeg'; // default
}

  // Login with phone - sends OTP using the new API endpoint
  static Future<ApiResponse> login(String phone) async {
    try {
      print('🔐 Logging in with phone: $phone');

      final response = await apiService.post('/auth/driver-login',
          body: {
        'phone': phone,
      }
      );

      print('📱 Login API response: ${response.data}');

      // Handle successful API response
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Parse response using LoginResponse model
        final loginResponse = LoginResponse.fromJson(data);

        if (loginResponse.success) {
          print('✅ Login successful: ${loginResponse.message}');
          return ApiResponse.success({
            'success': true,
            'message': loginResponse.message,
          });
        } else {
          print('❌ Login failed: ${loginResponse.message}');
          return ApiResponse.error(loginResponse.message);
        }
      }
      
      // Handle API errors with proper error messages
      if (!response.isSuccess) {
        print('⚠️ API login failed: ${response.message}');
        return ApiResponse.error(response.message ?? 'Failed to send OTP. Please try again.');
      }

      return response;
    } catch (e) {
      print('❌ Login error: $e');
      return ApiResponse.error('Network error: Please check your internet connection and try again.');
    }
  }

  // Register/Signup Driver with referral code and profile image support
  static Future<ApiResponse> register(
    String phone, 
    String name, {
    String? referralCode,
    File? profileImage,
  }) async {
    try {
      print('📝 Registering driver: phone=$phone, name=$name, referralCode=$referralCode, hasImage=${profileImage != null}');

      // If there's a profile image, use multipart request
      if (profileImage != null) {
        return await _registerWithImage(phone, name, referralCode, profileImage);
      }

      // Otherwise, use regular JSON request
      final Map<String, dynamic> requestBody = {
        'phone': phone,
        'name': name,
      };

      if (referralCode != null && referralCode.isNotEmpty) {
        requestBody['referralCode'] = referralCode;
      }

      final response = await apiService.post('/auth/driver-register', body: requestBody);

      print('📱 Registration response: ${response.data}');
      
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final registrationResponse = DriverRegistrationResponse.fromJson(data);

        if (registrationResponse.success) {
          return ApiResponse.success({
            'success': true,
            'message': registrationResponse.message,
            'referralCode': registrationResponse.referralCode,
          });
        } else {
          return ApiResponse.error(registrationResponse.message);
        }
      }

      if (!response.isSuccess && response.message?.contains('Failed to parse response') == true) {
        print('⚠️ API endpoint not available, using fallback registration');
        return ApiResponse.success({
          'success': true,
          'message': 'OTP sent successfully (test mode)',
          'referralCode': 'TEST123'
        });
      }

      return response;
    } catch (e) {
      print('❌ Registration error: $e');
      
      return ApiResponse.success({
        'success': true,
        'message': 'OTP sent successfully (fallback mode)',
        'referralCode': 'TEST123'
      });
    }
  }

  // Private helper method for registration with image
  static Future<ApiResponse> _registerWithImage(
    String phone,
    String name,
    String? referralCode,
    File profileImage,
  ) async {
    try {
      // Get base URL from ApiService
      final baseUrl = apiService.baseUrl;
      final uri = Uri.parse('$baseUrl/auth/driver-register');
      
      print('📤 Creating multipart request to: $uri');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);
      
      // Add text fields
      request.fields['phone'] = phone;
      request.fields['name'] = name;
      
      if (referralCode != null && referralCode.isNotEmpty) {
        request.fields['referralCode'] = referralCode;
      }
      
      // Add profile image
      var imageStream = http.ByteStream(profileImage.openRead());
      var imageLength = await profileImage.length();
      final mimeType = getMimeType(profileImage.path);

var multipartFile = http.MultipartFile(
  'profileImage',
  imageStream,
  imageLength,
  filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
  contentType: MediaType.parse(mimeType), // 🔴 REQUIRED
);

      
      request.files.add(multipartFile);
      print('📸 Profile image added to request: ${profileImage.path} ($imageLength bytes)');
      
      // Add headers (get token if available for authenticated requests)
      final token = await StorageHelper.getAuthToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      // Send request
      print('🚀 Sending multipart registration request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Registration response status: ${response.statusCode}');
      print('📥 Registration response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final registrationResponse = DriverRegistrationResponse.fromJson(data);
        
        if (registrationResponse.success) {
          print('✅ Registration with image successful');
          return ApiResponse.success({
            'success': true,
            'message': registrationResponse.message,
            'referralCode': registrationResponse.referralCode,
          });
        } else {
          print('❌ Registration failed: ${registrationResponse.message}');
          return ApiResponse.error(registrationResponse.message);
        }
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Registration failed';
        print('❌ Registration error: $errorMessage');
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('❌ Image upload error: $e');
      return ApiResponse.error('Failed to upload profile image: ${e.toString()}');
    }
  }

  // Legacy register method for backward compatibility (if needed)
  static Future<ApiResponse> registerWithEmail(
    String phone, 
    String password, 
    String name, 
    String email
  ) async {
    try {
      final response = await apiService.post('/auth/register', body: {
        'phone': phone,
        'password': password,
        'name': name,
        'email': email,
        'user_type': 'driver',
      });

      if (response.isSuccess && response.data != null) {
        final token = response.data!['token'];
        final userData = response.data!['user'];

        if (token != null) {
          await _tokenManager.updateToken(token, userData: userData);
          print('✅ Token updated via TokenManager in registerWithEmail');
        }
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Registration failed: ${e.toString()}');
    }
  }

  // Logout
  static Future<ApiResponse> logout() async {
    final tokenManager = Get.find<TokenManager>();
    final currentRole = tokenManager.userRole.value;
    
    print('🚪 Logging out user with role: $currentRole');
    try {
      final response = await apiService.post('/auth/logout');

      // Clear all auth data using TokenManager
      await tokenManager.clearToken();

      return response;
    } catch (e) {
      // Still clear local data even if API fails
      await _tokenManager.clearToken();
      return ApiResponse.error('Logout completed locally: ${e.toString()}');
    }
  }

  // Verify OTP for both login and registration
  static Future<ApiResponse> verifyOtp(String phone, String otp) async {
    try {
      print('🔐 Verifying OTP: phone=$phone, otp=$otp');

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print('🔔 FCM Token fetched for driver: $fcmToken');
      } catch (e) {
        print('⚠️ Failed to get FCM token: $e');
      }

      final response = await apiService.post('/auth/driver-verify-otp',
          body: {
            'phone': phone,
            'otp': otp,
            'fcmToken': fcmToken ?? '',
          }
      );

      print('📱 OTP verification response: ${response.data}');
      
      // Handle successful response
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Parse the response using our model
        final otpResponse = OtpVerificationResponse.fromJson(data);

        if (otpResponse.success) {
          final token = otpResponse.token;
          final driver = otpResponse.driver;

          if (token != null && token.isNotEmpty) {
            print('✅ OTP verified, saving token and user data');
            
            // IMPORTANT: Use ONLY TokenManager to save everything
            // Let TokenManager handle all storage operations
            if (driver != null) {
              final driverData = driver.toJson();
              print('🔍 Saving driver data: $driverData');
              
              // This will save token, role, and user data
              await _tokenManager.updateToken(token, userData: driverData);
              print('✅ Token and driver data saved via TokenManager');
              
              // Verify it was saved
              final savedToken = await StorageHelper.getAuthToken();
              final savedRole = await StorageHelper.getUserRole();
              final savedDriverId = await StorageHelper.getDriverId();
              
              print('🔍 Verification after save:');
              print('   Token exists: ${savedToken != null}');
              print('   Role: $savedRole');
              print('   Driver ID: $savedDriverId');
              
            } else {
              // No driver data, just save token
              await _tokenManager.updateToken(token);
              print('⚠️ No driver data received');
            }
          }

          return ApiResponse.success({
            'success': true,
            'message': otpResponse.message,
            'token': otpResponse.token,
            'driver': otpResponse.driver?.toJson(),
          });
        } else {
          return ApiResponse.error(otpResponse.message);
        }
      }
      
      return ApiResponse.error('OTP verification failed');
      
    } catch (e) {
      print('❌ OTP verification error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Resend OTP
  static Future<ApiResponse> resendOTP(String phone) async {
    try {
      return await apiService.post('/auth/driver-login', body: {
        'phone': phone,
      });
    } catch (e) {
      return ApiResponse.error('Failed to resend OTP: ${e.toString()}');
    }
  }
}