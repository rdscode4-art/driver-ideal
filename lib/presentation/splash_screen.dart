// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal_driver/core/app_theme.dart';
import 'package:rideal_driver/controllers/earnings_controller.dart';
import 'package:rideal_driver/controllers/home_controller.dart';
import 'package:rideal_driver/controllers/profile_controller.dart';
import 'package:rideal_driver/core/token_manager.dart';
import 'package:http/http.dart' as http;
import 'package:rideal_driver/subscriptioncontroller.dart';
import 'package:rideal_driver/views/nonvehicle_subscription_controller.dart';
import 'dart:convert';
import '../routes/app_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add a minimal delay to ensure smooth transition from native splash screen
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final tokenManager = TokenManager.instance;
      await tokenManager.loadToken();

      final token = tokenManager.authToken.value;
      final role = tokenManager.userRole.value;
      final userId = tokenManager.userId.value;

      print('🔍 Splash Check - Token: ${token != null}, Role: $role');
      print('🔍 Splash Check - User ID: $userId');

      // ❌ No token - go to login
      if (token == null || token.isEmpty) {
        print('❌ No token - Going to ROLE SELECTION');
        Get.offAllNamed(Routes.ROLE_SELECTION);
        return;
      }

      // ✅ NON-VEHICLE DRIVER - Check subscription first!
      if (role == 'non-vehicle-driver') {
        print('🚶 Non-vehicle driver detected - Checking subscription...');
        await _handleNonVehicleDriverRouting(token);
        return;
      }

      // ✅ REGULAR DRIVER - Full KYC + Subscription check
      if (role == 'driver') {
        print('🚗 Regular driver - Starting comprehensive checks...');

        // 🔍 CRITICAL: Check if user ID exists
        if (userId == null || userId.isEmpty) {
          print('⚠️ Driver ID missing - Attempting to extract from token...');

          final extractedId = _extractIdFromToken(token);
          if (extractedId != null) {
            tokenManager.userId.value = extractedId;
            print('✅ User ID extracted: $extractedId');
          } else {
            print('❌ Could not extract user ID - Forcing re-login');
            await tokenManager.clearToken();
            Get.offAllNamed(Routes.ROLE_SELECTION);
            return;
          }
        }

        await _handleDriverRouting(token);
        return;
      }

      // ❌ Unknown role
      print('⚠️ Unknown role - Going to ROLE SELECTION');
      Get.offAllNamed(Routes.ROLE_SELECTION);
    } catch (e) {
      print('❌ Splash Error: $e');
      Get.offAllNamed(Routes.ROLE_SELECTION);
    }
  }

  /// 🚶 Handle Non-Vehicle Driver Routing
  Future<void> _handleNonVehicleDriverRouting(String token) async {
    try {
      print('═══════════════════════════════════════');
      print('🚶 NON-VEHICLE DRIVER ROUTING');
      print('═══════════════════════════════════════');

      // STEP 1: Check Verification Status
      print('📋 STEP 1: Checking Verification Status...');
      final verificationStatus = await _checkNonVehicleVerificationStatus(
        token,
      );
      print('📋 Verification Status Result: $verificationStatus');
      print('═══════════════════════════════════════');

      // Handle verification status
      if (verificationStatus == 'pending') {
        print('⏰ Verification pending - Going to VERIFICATION PENDING screen');
        Get.offAllNamed('/verification-pending');

        // Silent redirect to verification pending
        return;
      }

      if (verificationStatus == 'rejected' ||
          verificationStatus == 'declined') {
        print('❌ Verification rejected - Showing error');
        Get.offAllNamed(
          '/verification-pending',
        ); // or create a rejection screen

        // Silent redirect to verification pending
        return;
      }

      // STEP 2: Verification approved - Check subscription
      if (verificationStatus == 'approved' ||
          verificationStatus == 'accepted' ||
          verificationStatus == 'active') {
        print('✅ Verification approved - Checking subscription...');
        print('═══════════════════════════════════════');
        print('💳 STEP 2: Checking Subscription Status...');

        // Ensure controller is registered
        if (!Get.isRegistered<NonVehicleSubscriptionController>()) {
          Get.put(NonVehicleSubscriptionController(), permanent: true);
        }

        final subscriptionController =
            Get.find<NonVehicleSubscriptionController>();
        await subscriptionController.loadSubscriptionStatus();

        final subStatus = subscriptionController.subscriptionStatus.value
            .toLowerCase();
        print('💳 Subscription Status: $subStatus');
        print('═══════════════════════════════════════');

        // ✅ CHECK: Active subscription
        if (subStatus == 'active' ||
            subStatus == 'subscribed' ||
            subStatus == true) {
          print('✅ Active subscription - Going to NON-VEHICLE DASHBOARD');
          Get.offAllNamed(Routes.NONVEHICHLEDASHBOARD);
          return;
        }

        // ❌ No subscription - Go to NON-VEHICLE subscription screen
        print(
          '❌ No active subscription - Going to NON-VEHICLE SUBSCRIPTION SCREEN',
        );
        Get.offAllNamed(Routes.NON_VEHICLE_SUBSCRIPTION);

        // Silent redirect to subscription
        return;
      }

      // Fallback - if status is unknown
      print('⚠️ Unknown verification status - Going to VERIFICATION PENDING');
      Get.offAllNamed('/verification-pending');
    } catch (e) {
      print('❌ Error in non-vehicle driver routing: $e');
      print('   Stack trace: $e');
      print('═══════════════════════════════════════');

      // On error, go to verification pending (safe fallback)
      Get.offAllNamed('/verification-pending');
    }
  }

  /// Check Non-Vehicle Driver Verification Status
  Future<String> _checkNonVehicleVerificationStatus(String token) async {
    try {
      print('📡 Calling Non-Vehicle Verification Status API...');
      final tokenManager = TokenManager.instance;
      final driverId = tokenManager.userId.value;

      if (driverId == null || driverId.isEmpty) {
        print('⚠️ No driver ID found - treating as pending');
        return 'pending';
      }

      final response = await http
          .get(
            Uri.parse(
              'https://backend.ridealmobility.com/api/non-vehicle-driver/profile/$driverId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ Verification API Timeout');
              throw Exception('Timeout');
            },
          );

      print('📡 Verification Status API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Response data: $data');

        // ⭐ FIX: Check the correct field path - status is inside driver object
        String? status;

        // Priority 1: Check driver.status (this is where your API returns it)
        if (data['driver'] != null && data['driver']['status'] != null) {
          status = data['driver']['status'].toString().toLowerCase();
          print('✅ Found status in driver.status: $status');
        }
        // Priority 2: Check top-level status
        else if (data['status'] != null) {
          status = data['status'].toString().toLowerCase();
          print('✅ Found status in top-level status: $status');
        }
        // Priority 3: Check driver.verificationStatus
        else if (data['driver'] != null &&
            data['driver']['verificationStatus'] != null) {
          status = data['driver']['verificationStatus']
              .toString()
              .toLowerCase();
          print('✅ Found status in driver.verificationStatus: $status');
        }
        // Priority 4: Check top-level verificationStatus
        else if (data['verificationStatus'] != null) {
          status = data['verificationStatus'].toString().toLowerCase();
          print('✅ Found status in top-level verificationStatus: $status');
        }

        if (status == null || status.isEmpty) {
          print('⚠️ Verification status is null/empty - treating as pending');
          return 'pending';
        }

        print('✅ Verification Status from API: $status');
        return status;
      } else if (response.statusCode == 404) {
        print('📋 Driver profile not found (404) - treating as pending');
        return 'pending';
      }

      print('⚠️ Unexpected response - treating as pending');
      return 'pending';
    } catch (e) {
      print('❌ Error checking verification status: $e');
      if (e.toString().contains('Timeout')) {
        return 'pending';
      }
      return 'pending';
    }
  }

  /// 🚗 Handle Regular Driver Routing (with KYC + Subscription)
  Future<void> _handleDriverRouting(String token) async {
    try {
      print('🚀 [SPLASH] Starting _handleDriverRouting');

      // STEP 0: Fetch Profile to check verification status
      print('👤 [SPLASH] STEP 0: Checking Profile Verification Status...');
      if (!Get.isRegistered<ProfileController>()) {
        Get.put(ProfileController(), permanent: true);
      }
      final profileController = Get.find<ProfileController>();

      // ALWAYS refresh profile to get the latest verification status from backend
      print('🔄 [SPLASH] Fetching fresh profile data...');
      await profileController.loadProfile();

      final bool isAlreadyVerified = profileController.isVerified;

      print(
        '👤 [SPLASH] Profile loaded for: ${profileController.driverProfile.value?.name}',
      );
      print('👤 [SPLASH] Profile Verification Status: $isAlreadyVerified');

      // STEP 1: Check KYC Status
      // We must check the actual KYC status, not just profile's isVerified (which might just mean phone is verified)
      String kycStatus = 'not_submitted';

      // First check if profile has KYC data
      if (profileController.driverProfile.value?.verification != null) {
        final profileKycStatus = profileController
            .driverProfile
            .value
            ?.verification
            ?.status
            ?.toLowerCase();
        if (profileKycStatus != null && profileKycStatus.isNotEmpty) {
          kycStatus = profileKycStatus;
          print('📋 [SPLASH] KYC Status from Profile: $kycStatus');
        } else {
          // Fallback to API if profile has empty status
          print('📋 [SPLASH] Profile KYC status empty, fetching from API...');
          kycStatus = await _checkKYCStatus(token);
        }
      } else {
        // No verification data in profile, fetch from API to be sure
        print('📋 [SPLASH] No KYC data in profile, fetching from API...');
        kycStatus = await _checkKYCStatus(token);
      }
      print('═══════════════════════════════════════');

      if (kycStatus == 'not_submitted' ||
          kycStatus == 'notsubmitted' ||
          kycStatus == 'unknown') {
        print('📝 [SPLASH] KYC not submitted - Redirecting to KYC DOCUMENTS');
        Get.offAllNamed('/kyc-documents');
        return;
      }

      if (kycStatus == 'pending') {
        print('⏰ [SPLASH] KYC pending - Redirecting to VERIFICATION PENDING');
        Get.offAllNamed('/verification-pending');
        return;
      }

      if (kycStatus == 'rejected' || kycStatus == 'declined') {
        print('❌ [SPLASH] KYC rejected - Redirecting to KYC DOCUMENTS');
        Get.offAllNamed('/kyc-documents');
        return;
      }

      // STEP 2: KYC approved - Check subscription
      if (kycStatus == 'approved' ||
          kycStatus == 'accepted' ||
          kycStatus == 'verified') {
        print(
          '✅ [SPLASH] KYC status is OK (${kycStatus}) - Checking subscription...',
        );
        print('═══════════════════════════════════════');
        print('💳 [SPLASH] STEP 2: Checking Subscription Status...');

        final subscriptionController = Get.find<SubscriptionController>();
        await subscriptionController.loadSubscriptionStatus();

        final hasActiveSubscription =
            subscriptionController.hasSubscription.value;
        print('💳 [SPLASH] Has Active Subscription: $hasActiveSubscription');
        print('═══════════════════════════════════════');

        if (hasActiveSubscription) {
          print(
            '✅ [SPLASH] Active subscription found - Preparing dashboard...',
          );

          // Initialize dashboard controllers
          if (!Get.isRegistered<HomeController>()) {
            Get.lazyPut(() => HomeController());
          }
          if (!Get.isRegistered<EarningsController>()) {
            Get.lazyPut(() => EarningsController());
          }

          print('✅ [SPLASH] DASHBOARD READY - Navigating to HOME');
          Get.offAllNamed(Routes.HOME);
          return;
        }

        // ❌ No subscription - Go to subscription screen
        print(
          '❌ [SPLASH] No active subscription - Navigating to SUBSCRIPTION SCREEN',
        );
        Get.offAllNamed(Routes.SUBSCRIPTION);
        return;
      }

      // Fallback
      print(
        '⚠️ [SPLASH] Fallback hit - No specific status matched. Going to KYC page as safety measure.',
      );
      Get.offAllNamed('/kyc-documents');
    } catch (e, stack) {
      print('❌ [SPLASH] Error in driver routing: $e');
      print('❌ [SPLASH] Stack trace: $stack');
      Get.offAllNamed('/kyc-documents');
    }
  }

  /// Check KYC status from API using KycApiService
  Future<String> _checkKYCStatus(String token) async {
    try {
      print('📡 Calling KYC Status API via KycApiService...');

      // Import kyc_api_service if not already imported, but let's just use http to hit the correct endpoint to avoid import issues if not present
      final response = await http
          .get(
            Uri.parse('https://backend.ridealmobility.com/driver/kyc/status'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ KYC API Timeout');
              throw Exception('Timeout');
            },
          );

      print('📡 KYC Status API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Response data: $data');

        if (data['success'] == true && data['data'] != null) {
          final status = (data['data']['status'] ?? data['status'])
              ?.toString()
              .toLowerCase();

          if (status == null || status.isEmpty) {
            print('⚠️ Status is null/empty - treating as not_submitted');
            return 'not_submitted';
          }

          print('✅ KYC Status from API: $status');
          return status;
        }
      } else if (response.statusCode == 404) {
        print('📋 KYC not found (404) - treating as not_submitted');
        return 'not_submitted';
      }

      print('⚠️ Unexpected response - treating as not_submitted');
      return 'not_submitted';
    } catch (e) {
      print('❌ Error checking KYC status: $e');

      if (e.toString().contains('Timeout')) {
        return 'pending';
      }

      return 'not_submitted';
    }
  }

  /// Extract user ID from JWT token
  String? _extractIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = json.decode(payload);

      return data['id']?.toString() ??
          data['_id']?.toString() ??
          data['userId']?.toString();
    } catch (e) {
      print('❌ Error extracting ID from token: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Image(
            image: const AssetImage("assets/images/logo.png"),
            width: 320.w, // Significantly larger for brand focus as requested
            height: 320.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
