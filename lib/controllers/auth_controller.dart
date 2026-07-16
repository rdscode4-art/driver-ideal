import 'dart:io';

import 'package:get/get.dart';
import 'dart:convert';
import '../core/storage_helper.dart';
import '../core/token_manager.dart';
import '../routes/app_pages.dart';
import '../services/auth_api_service.dart';
import 'home_controller.dart';
import 'profile_controller.dart';
import 'non_vehicle_auth_controller.dart';
import '../core/utils/app_snackbar.dart';

// Token validation result enum
enum TokenValidationResult { Valid, Invalid, NetworkError }

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var isLoading = false.obs;
  var userData = Rxn<Map<String, dynamic>>();

  // Temporary variables for OTP flow
  var tempPhone = ''.obs;
  var tempName = ''.obs;
  var isLoginFlow =
      false.obs; // Track if current OTP flow is for login or registration

  // Use TokenManager for dynamic token management
  final TokenManager _tokenManager = TokenManager.instance;

  @override
  void onInit() {
    super.onInit();
    // Don't automatically check login status on init to avoid API calls
    // This will be called explicitly by splash screen when needed
    _loadStoredAuthData();
  }

  // Load stored auth data without making API calls
  Future<void> _loadStoredAuthData() async {
    try {
      final loggedIn = await StorageHelper.getLoggedIn();
      final token = await StorageHelper.getAuthToken();

      print(
        '🔍 Loading stored auth data: loggedIn=$loggedIn, token exists=${token != null}',
      );

      if (loggedIn && token != null && token.isNotEmpty) {
        userData.value =
            null; // Optionally, attempt to load user data but allow null

        final userDataString = await StorageHelper.getUserData();
        if (userDataString != null && userDataString.isNotEmpty) {
          try {
            userData.value = json.decode(userDataString);
            print('✅ Loaded user data from storage');
          } catch (e) {
            print('⚠️ Failed to parse stored user data: $e');
          }
        }

        isLoggedIn.value = true;
        print('✅ Marked user as logged in based on stored token');
      } else {
        isLoggedIn.value = false;
        print('❌ No valid stored login found');
      }
    } catch (e) {
      print('❌ Error loading auth data: $e');
      isLoggedIn.value = false;
    }
  }

  // Enhanced login status check with proper null safety and token validation
  // Future<void> checkLoginStatus() async {
  //   try {
  //     final loggedIn = await StorageHelper.getLoggedIn();
  //     final token = await StorageHelper.getAuthToken();

  //     print('🔍 Checking login status: loggedIn=====$loggedIn, hasToken=${token != null}');

  //     if (loggedIn && token != null && token.isNotEmpty) {
  //       // Load user data if available
  //       final userDataString = await StorageHelper.getUserData();
  //       if (userDataString != null && userDataString.isNotEmpty) {
  //         try {
  //           userData.value = json.decode(userDataString);
  //           print('✅ User data loaded: ${userData.value?['name'] ?? 'Unknown'}');
  //         } catch (e) {
  //           print('❌ Error parsing user data: $e');
  //           userData.value = null;
  //         }
  //       }

  //       // Try to validate token, but don't fail completely if validation fails
  //       // final tokenValidationResult = await _validateAuthToken(token);

  //       // if (tokenValidationResult == TokenValidationResult.Valid) {
  //       //   isLoggedIn.value = true;
  //       //   print('✅ Authentication validated successfully with server');

  //       //   // Initialize ProfileController and load profile data
  //       //   await _initializeProfileAfterLogin();
  //       //   return;
  //       // }
  //       // else if (tokenValidationResult == TokenValidationResult.NetworkError) {
  //       //   // Network error - allow offline login
  //       //   isLoggedIn.value = true;
  //       //   print('✅ Authentication allowed offline (network issue)');

  //       //   // Initialize ProfileController and load profile data
  //       //   await _initializeProfileAfterLogin();
  //       //   return;
  //       // }
  //       // else {
  //       //   // Token is actually invalid - clear auth data
  //       //   print('❌ Token validation failed - token is invalid, clearing auth data');
  //       //   await _clearAllAuthData();
  //       // }
  //     }
  //     //  else {
  //     //   print('��� No valid credentials found - loggedIn: $loggedIn, hasToken: ${token != null}');
  //     // }

  //     // If we reach here, user is not properly authenticated
  //     isLoggedIn.value = false;
  //     print('❌ User not authenticated');

  //   } catch (e) {
  //     print('❌ Error checking login status: $e');

  //     // On error, check if we have basic auth data for offline fallback
  //     try {
  //       final loggedIn = await StorageHelper.getLoggedIn();
  //       final token = await StorageHelper.getAuthToken();

  //       if (loggedIn && token != null && token.isNotEmpty) {
  //         print('🔄 Using offline authentication fallback');
  //         isLoggedIn.value = true;

  //         // Load user data if available
  //         final userDataString = await StorageHelper.getUserData();
  //         if (userDataString != null && userDataString.isNotEmpty) {
  //           try {
  //             userData.value = json.decode(userDataString);
  //           } catch (e) {
  //             print('❌ Error parsing user data in fallback: $e');
  //             userData.value = null;
  //           }
  //         }
  //       } else {
  //         isLoggedIn.value = false;
  //         await _clearAllAuthData();
  //       }
  //     } catch (fallbackError) {
  //       print('❌ Fallback authentication also failed: $fallbackError');
  //       isLoggedIn.value = false;
  //       await _clearAllAuthData();
  //     }
  //   }

  Future<void> loadLoginStatus() async {
    final token = await StorageHelper.getAuthToken();
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
    } else {
      isLoggedIn.value = false;
    }
  }

  // Enhanced token validation with result types
  // Future<TokenValidationResult> _validateAuthToken(String token) async {
  //   try {
  //     print('🔄 Validating auth token with server...');

  //     // Set a timeout for token validation to avoid hanging
  //     final response = await AuthApiService.validateToken().timeout(
  //       Duration(seconds: 10),
  //       onTimeout: () {
  //         print('⏰ Token validation timed out');
  //         return ApiResponse.error('Timeout');
  //       },
  //     );

  //     if (response.isSuccess) {
  //       print('✅ Token validation successful');
  //       return TokenValidationResult.Valid;
  //     } else if (response.message?.contains('Timeout') == true) {
  //       print('⏰ Token validation timeout - allowing offline access');
  //       return TokenValidationResult.NetworkError;
  //     } else {
  //       print('❌ Token validation failed: ${response.message}');
  //       return TokenValidationResult.Invalid;
  //     }
  //   } catch (e) {
  //     print('❌ Token validation error: $e');

  //     // Check if it's a network-related error
  //     if (e.toString().contains('SocketException') ||
  //         e.toString().contains('TimeoutException') ||
  //         e.toString().contains('network') ||
  //         e.toString().contains('timeout')) {
  //       print('🌐 Network error during token validation - allowing offline access');
  //       return TokenValidationResult.NetworkError;
  //     } else {
  //       return TokenValidationResult.Invalid;
  //     }
  //   }
  // }

  // Initialize profile controller and load profile data after login
  Future<void> _initializeProfileAfterLogin() async {
    try {
      // Get or put ProfileController
      final profileController = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController(), permanent: true);

      // Load profile data
      await profileController.loadProfile();

      print('✅ Profile initialized after login');
    } catch (e) {
      print('❌ Failed to initialize profile after login: $e');
    }
  }

  // Login with API - sends OTP
  Future<bool> login(String phone) async {
    try {
      isLoading.value = true;

      final response = await AuthApiService.login(phone);

      if (response.isSuccess) {
        // Login API sends OTP, doesn't log in immediately
        showSuccessSnackBar(
          'OTP sent successfully!',
          title: 'Success',
        );

        // Store phone temporarily for OTP verification
        tempPhone.value = phone;
        isLoginFlow.value = true; // Mark as login flow
        print('📱 Login Flow: Set isLoginFlow = true for phone: $phone');

        return true;
      } else {
        showErrorSnackBar(
          response.message ?? 'Failed to send OTP',
          title: 'Login Failed',
        );
        return false;
      }
    } catch (e) {
      showErrorSnackBar(
        'Login failed: ${e.toString()}',
        title: 'Error',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Register with API - Driver Registration (updated to support referral code)
  Future<bool> register(
    String phone,
    String name, {
    String? referralCode,
    File? profileImage,
  }) async {
    try {
      isLoading.value = true;

      final response = await AuthApiService.register(
        phone,
        name,
        referralCode: referralCode,
        profileImage: profileImage,
      );

      if (response.isSuccess) {
        final responseData = response.data ?? {};
        final message = responseData['message'] ?? 'OTP sent successfully!';
        final generatedReferralCode = responseData['referralCode'];

        String displayMessage = message;
        if (generatedReferralCode != null && generatedReferralCode.isNotEmpty) {
          displayMessage += '\nYour referral code: $generatedReferralCode';
        }

        showSuccessSnackBar(
          'OTP sent successfully!',
          title: 'Success',
        );

        tempPhone.value = phone;
        tempName.value = name;
        isLoginFlow.value = false;
        print(
          '📝 Registration Flow: Set isLoginFlow = false for phone: $phone, name: $name',
        );

        return true;
      } else {
        showErrorSnackBar(
          response.message ?? 'Registration failed',
          title: 'Registration Failed',
        );
        return false;
      }
    } catch (e) {
      showErrorSnackBar(
        'Registration failed: ${e.toString()}',
        title: 'Error',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    try {
      isLoading.value = true;

      if (tempPhone.value.isEmpty) {
        showErrorSnackBar(
          'Phone number not found. Please restart registration.',
          title: 'Error',
        );
        return false;
      }

      print(
        '🔐 Attempting OTP verification for phone: ${tempPhone.value}, OTP: $otp',
      );

      final response = await AuthApiService.verifyOtp(tempPhone.value, otp);

      print(
        '🔐 OTP verification response: Success=${response.isSuccess}, Message=${response.message}',
      );

      if (response.isSuccess) {
        isLoggedIn.value = true;
        userData.value =
            response.data?['user'] ??
            {'name': tempName.value, 'phone': tempPhone.value};

        final token = response.data?['token'];
        if (token != null) {
          print('🔐 Saving token and user data persistently');
          await _tokenManager.updateToken(token, userData: userData.value);
          await StorageHelper.saveAuthToken(token);
          await StorageHelper.setLoggedIn(true);
          await StorageHelper.saveUserData(json.encode(userData.value));
          print('✅ Token and auth data saved successfully');
        } else {
          print('⚠️ No token found in OTP response');
        }

        // ✅ ROLE-BASED DATA REFRESH
        final role = _tokenManager.userRole.value;

        if (role == 'driver') {
          // Regular driver - refresh HomeController data
          print('🔄 Triggering data refresh for regular driver...');
          try {
            final homeController = Get.isRegistered<HomeController>()
                ? Get.find<HomeController>()
                : null;
            await homeController?.refreshDataAfterLogin();
            print('✅ Data refresh completed');
          } catch (e) {
            print('⚠️ HomeController not found: $e');
          }
        } else if (role == 'non-vehicle-driver') {
          // Non-vehicle driver - skip HomeController refresh
          print('🚶 Non-vehicle driver - Skipping HomeController refresh');
        }

        await _initializeProfileAfterLogin();

        // Check verification status before navigating
        final profileController = Get.find<ProfileController>();
        print('🛡️ [AUTH] Verification status before Splash: ${profileController.isVerified}');
        print('🛡️ [AUTH] Profile loaded for: ${profileController.driverProfile.value?.name}');

        // Clear temporary flow data
        tempPhone.value = '';
        tempName.value = '';

        showSuccessSnackBar(
          'Welcome to RiDeal Driver App!',
          title: '🎉 Account Verified!',
        );
        
        // Small delay to ensure snackbar shows and state is settled
        await Future.delayed(const Duration(milliseconds: 500));
        
        // ✅ Navigate to Splash to reuse its complex routing logic
        print('🚀 [AUTH] Redirecting to SPLASH for status-based routing');
        Get.offAllNamed(Routes.SPLASH);

        return true;
      } else {
        print('❌ OTP verification failed: ${response.message}');
        showErrorSnackBar(
          response.message ?? 'Invalid OTP',
          title: 'Verification Failed',
        );
        return false;
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      showErrorSnackBar(
        'OTP verification failed: ${e.toString()}',
        title: 'Error',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Resend OTP
  Future<bool> resendOTP() async {
    try {
      isLoading.value = true;

      if (tempPhone.value.isEmpty) {
        showErrorSnackBar(
          'Phone number not found. Please restart registration.',
          title: 'Error',
        );
        return false;
      }

      final response = await AuthApiService.resendOTP(tempPhone.value);

      if (response.isSuccess) {
        showSuccessSnackBar(
          'OTP sent successfully!',
          title: 'Success',
        );
        return true;
      } else {
        showErrorSnackBar(
          response.message ?? 'Failed to resend OTP',
          title: 'Error',
        );
        return false;
      }
    } catch (e) {
      showErrorSnackBar(
        'Failed to resend OTP: ${e.toString()}',
        title: 'Error',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get navigation route after successful OTP verification
  String getPostOTPRoute() {
    String route = isLoginFlow.value ? Routes.DASHBOARD : Routes.KYC_DOCUMENTS;
    print(
      '🚀 Navigation Decision: isLoginFlow=${isLoginFlow.value} → route=$route',
    );
    return route;
  }

  // Clear flow state after navigation (call this after successful navigation)
  void clearFlowState() {
    isLoginFlow.value = false;
    print('🧹 Cleared flow state');
  }

  // Logout with API - Updated to use TokenManager
  Future<void> logout({bool isNonVehicle = false}) async {
    try {
      isLoading.value = true;

      // Call logout API
      await AuthApiService.logout();

      // Clear all auth data using TokenManager
      await _tokenManager.clearToken();

      // Clear profile data
      try {
        final profileController = Get.find<ProfileController>();
        profileController.clearProfile();
        print('✅ Profile data cleared during logout');
      } catch (e) {
        print('⚠️ Could not clear profile during logout: $e');
      }

      // 📍 Stop non-vehicle location tracking if active
      try {
        final nonVehicleAuthController = Get.find<NonVehicleAuthController>();
        nonVehicleAuthController.stopLocationTracking();
      } catch (e) {
        print('⚠️ Could not stop non-vehicle tracking during logout: $e');
      }

      // Reset controller state
      isLoggedIn.value = false;
      userData.value = null;
      tempPhone.value = '';
      tempName.value = '';
      isLoginFlow.value = false;

      showSuccessSnackBar(
        'You have been logged out successfully',
        title: 'Logged Out',
      );

      // Navigate to login screen
      if (isNonVehicle) {
        Get.offAllNamed(Routes.NON_VEHICLE_LOGIN);
      } else {
        Get.offAllNamed('/login');
      }
    } catch (e) {
      print('Logout API error: $e');
      // Force logout locally even if API fails
      await _tokenManager.clearToken();
      isLoggedIn.value = false;
      userData.value = null;
      tempPhone.value = '';
      tempName.value = '';
      isLoginFlow.value = false;

      showSuccessSnackBar(
        'You have been logged out locally',
        title: 'Logged Out',
      );

      if (isNonVehicle) {
        Get.offAllNamed(Routes.NON_VEHICLE_LOGIN);
      } else {
        Get.offAllNamed('/login');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to clear all authentication data - Updated to use TokenManager
  Future<void> _clearAllAuthData() async {
    try {
      await _tokenManager.clearToken();
      print('✅ All authentication data cleared via TokenManager');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  // Forgot Password
  // Future<bool> forgotPassword(String phone) async {
  //   try {
  //     isLoading.value = true;

  //     final response = await AuthApiService.forgotPassword(phone);

  //     if (response.isSuccess) {
  //       Get.snackbar(
  //         'Success',
  //         'Password reset OTP sent to your phone',
  //         snackPosition: SnackPosition.TOP,
  //         backgroundColor: Get.theme.primaryColor,
  //         colorText: Get.theme.colorScheme.onPrimary,
  //       );
  //       return true;
  //     } else {
  //       Get.snackbar(
  //         'Failed',
  //         response.message ?? 'Failed to send OTP',
  //         snackPosition: SnackPosition.TOP,
  //         backgroundColor: Get.theme.colorScheme.error,
  //         colorText: Get.theme.colorScheme.onError,
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     Get.snackbar(
  //       'Error',
  //       'Failed to send OTP: ${e.toString()}',
  //       snackPosition: SnackPosition.TOP,
  //       backgroundColor: Get.theme.colorScheme.error,
  //       colorText: Get.theme.colorScheme.onError,
  //     );
  //     return false;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // Verify OTP for both login and registration flows - FIXED VERSION
  // Future<void> verifyOtp(String otp) async {
  //   if (isLoading.value) return;

  //   isLoading.value = true;

  //   try {
  //     print('🔐 Verifying OTP: ${tempPhone.value}, otp: $otp');

  //     // Validate inputs before API call
  //     if (tempPhone.value.isEmpty) {
  //       Get.snackbar(
  //         'Error',
  //         'Phone number not found. Please restart the process.',
  //         snackPosition: SnackPosition.TOP,
  //         backgroundColor: Colors.red[600],
  //         colorText: Colors.white,
  //       );
  //       return;
  //     }

  //     if (otp.length != 6) {
  //       Get.snackbar(
  //         'Error',
  //         'Please enter a valid 6-digit OTP.',
  //         snackPosition: SnackPosition.TOP,
  //         backgroundColor: Colors.red[600],
  //         colorText: Colors.white,
  //       );
  //       return;
  //     }

  //     final response = await AuthApiService.verifyOtp(tempPhone.value, otp);

  //     if (response.isSuccess) {
  //       final data = response.data;

  //       // Check if response data exists and has success flag
  //       if (data != null && data['success'] == true) {
  //         print('✅ OTP verification successful');

  //         // Store user data from the driver object (null-safe)
  //         final driverData = data['driver'];
  //         if (driverData != null) {
  //           userData.value = driverData;
  //           print('✅ Driver data stored: ${driverData['name'] ?? 'Unknown'}');
  //         }

  //         // Update login state
  //         isLoggedIn.value = true;

  //         // Store token if available (null-safe)
  //         final token = data['token'];
  //         if (token != null && token.toString().isNotEmpty) {
  //           await _tokenManager.updateToken(token.toString(), userData: userData.value);
  //           print('✅ Token updated successfully');
  //         }

  //         // Show success message
  //         Get.snackbar(
  //           'Success! 🎉',
  //           data['message'] ?? 'OTP verified successfully',
  //           snackPosition: SnackPosition.TOP,
  //           backgroundColor: Colors.green[600],
  //           colorText: Colors.white,
  //           duration: Duration(seconds: 2),
  //           icon: Icon(Icons.check_circle, color: Colors.white),
  //         );

  //         // Wait a bit for the success message to show
  //         await Future.delayed(Duration(milliseconds: 500));

  //         // Determine navigation based on flow type
  //         String navigationRoute;
  //         if (isLoginFlow.value) {
  //           // Existing driver login -> go to HOME
  //           navigationRoute = Routes.HOME;
  //           print('🔑 Login flow: Navigating to HOME screen');
  //         } else {
  //           // New driver registration -> go to KYC documents
  //           navigationRoute = Routes.KYC_DOCUMENTS;
  //           print('📝 Registration flow: Navigating to KYC documents screen');
  //         }

  //         // Initialize profile with better error handling
  //         try {
  //           await _initializeProfileAfterLogin();
  //           print('✅ Profile initialized, navigating to: $navigationRoute');
  //         } catch (e) {
  //           print('⚠️ Profile initialization failed, but continuing to navigation: $e');
  //           // Even if profile init fails, still navigate - don't block the user
  //         }

  //         // Clear temporary data before navigation
  //         tempPhone.value = '';
  //         tempName.value = '';
  //         final currentIsLoginFlow = isLoginFlow.value; // Store before clearing
  //         isLoginFlow.value = false;

  //         // Navigate to appropriate screen
  //         Get.offAllNamed(navigationRoute);

  //         print('🚀 Navigation completed to: $navigationRoute (was login: $currentIsLoginFlow)');

  //       } else {
  //         // API returned success=false
  //         final errorMessage = data?['message'] ?? 'OTP verification failed';
  //         print('❌ OTP verification failed: $errorMessage');
  //         Get.snackbar(
  //           'Verification Failed',
  //           errorMessage,
  //           snackPosition: SnackPosition.TOP,
  //           backgroundColor: Colors.red[600],
  //           colorText: Colors.white,
  //           icon: Icon(Icons.error, color: Colors.white),
  //         );
  //       }
  //     } else {
  //       // API call failed
  //       print('❌ API call failed: ${response.message}');
  //       Get.snackbar(
  //         'Network Error',
  //         response.message ?? 'Failed to verify OTP. Please try again.',
  //         snackPosition: SnackPosition.TOP,
  //         backgroundColor: Colors.red[600],
  //         colorText: Colors.white,
  //         icon: Icon(Icons.error, color: Colors.white),
  //       );
  //     }
  //   } catch (e) {
  //     print('❌ OTP verification error: $e');
  //     Get.snackbar(
  //       'Error',
  //       'Something went wrong. Please try again.',
  //       snackPosition: SnackPosition.TOP,
  //       backgroundColor: Colors.red[600],
  //       colorText: Colors.white,
  //       icon: Icon(Icons.error, color: Colors.white),
  //     );
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
}
