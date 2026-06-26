import 'package:flutter/widgets.dart';
import 'package:rideal_driver/core/token_manager.dart';
import 'package:rideal_driver/nonvehichle/nonvehichledashboard.dart';
import 'package:rideal_driver/presentation/chat_screen.dart';
import 'package:rideal_driver/presentation/privacy_policy_screen.dart';
import 'package:rideal_driver/presentation/ratings_screen.dart';
import 'package:rideal_driver/presentation/screens/subscription_screen.dart';
import 'package:rideal_driver/presentation/screens/verificationpendingscreen.dart';
import 'package:rideal_driver/presentation/settings_screen.dart';
import 'package:rideal_driver/presentation/rewards_screen.dart';
import 'package:rideal_driver/presentation/otp_verification_screen.dart';
import 'package:rideal_driver/presentation/support_screen.dart';
import 'package:rideal_driver/presentation/ride_history_screen.dart';
import 'package:rideal_driver/presentation/ongoing_ride_screen.dart';
import 'package:rideal_driver/presentation/kyc_documents_screen.dart';
import 'package:rideal_driver/presentation/about_screen.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/presentation/terms_of_service_screen.dart';
import 'package:rideal_driver/presentation/screens/withdrawal_request_screen.dart';
import 'package:rideal_driver/presentation/screens/payout_history_screen.dart';
import 'package:rideal_driver/views/documentsuploadscreen.dart';
import 'package:rideal_driver/views/non_vehichle_subscriptionplans_screen.dart';
import 'package:rideal_driver/views/personalinfoscreen.dart';
import 'package:rideal_driver/subscriptionscreen.dart';
import '../controllers/ride_history_controller.dart';
import '../presentation/role_selection_screen.dart';
import '../presentation/login_screen.dart';
import '../presentation/signup_screen.dart';
import '../presentation/profile_screen.dart';
import '../presentation/splash_screen.dart';
import '../presentation/wallet_screen.dart';
import '../presentation/notifications_screen.dart';
import '../presentation/dashboard_screen.dart';
import '../presentation/earnings_screen.dart';

// ✨ Non-Vehicle Driver Screens Import

part 'app_routes.dart';

class AppPages {
  static final routes = [
    // Add the missing HOME route as the first route
    GetPage(
      name: Routes.HOME,
      page: () =>
          const DashboardScreen(), // Use DashboardScreen as the main entry point
    ),
    // Individual screens (accessible via bottom navigation)
    GetPage(name: Routes.EARNINGS, page: () => const EarningsScreen()),
    GetPage(name: Routes.SUBSCRIPTION, page: () => const SubscriptionPlansScreen()),
    GetPage(
      name: Routes.NONVEHICHLEDASHBOARD,
      middlewares: [AuthMiddleware()],
      page: () => const MainScreen(),
    ),
    GetPage(name: Routes.PROFILE, page: () => const ProfileScreen()),
    GetPage(
      name: Routes.ROLE_SELECTION,
      page: () => const RoleSelectionScreen(),
    ),
    GetPage(name: Routes.LOGIN, page: () => const LoginScreen()),
    GetPage(name: Routes.SIGNUP, page: () => const SignupScreen()),
    GetPage(
      name: Routes.OTP_VERIFICATION,
      page: () => const OtpVerificationScreen(),
    ),
    GetPage(name: Routes.SPLASH, page: () => const SplashScreen()),
    GetPage(name: Routes.WALLET, page: () => const WalletScreen()),
    // GetPage(name: Routes.ONBOARDING, page: () => OnboardingScreen()),
    GetPage(
      name: Routes.NOTIFICATIONS,
      page: () => const NotificationsScreen(),
    ),
    GetPage(
      name: '/verification-pending',
      page: () => const VerificationPendingScreen(),
    ),
    GetPage(name: Routes.SETTINGS, page: () => SettingsScreen()),
    GetPage(name: Routes.RATINGS, page: () => RatingsScreen()),
    GetPage(name: Routes.CHAT, page: () => ChatScreen()),
    GetPage(name: Routes.KYC_DOCUMENTS, page: () => const KYCDocumentsScreen()),
    GetPage(name: Routes.REWARDS, page: () => const RewardsScreen()),
    // GetPage(
    //   name: Routes.AVAILABLE_RIDES,
    //   page: () => const AvailableRidesScreen(),
    // ),
    // GetPage(name: Routes.EDIT_PROFILE, page: () => const EditProfileScreen()),
    GetPage(name: Routes.SUPPORT, page: () => const SupportScreen()),
    GetPage(
      name: Routes.TRIP_HISTORY,
      page: () => RideHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<RideHistoryController>(() => RideHistoryController());
      }),
    ),
    GetPage(name: Routes.ONGOING_RIDE, page: () => const OngoingRideScreen()),
    GetPage(name: Routes.TERMS, page: () => const TermsOfServiceScreen()),
    GetPage(
      name: Routes.PRIVACY_POLICY,
      page: () => const PrivacyPolicyScreen(),
    ),
    GetPage(name: Routes.ABOUT, page: () => AboutScreen()),
    // GetPage(name: Routes.FUTURE_RIDE_DETAILS, page: () => FutureRideDetailsScreen()),
    // GetPage(name: Routes.MY_FUTURE_RIDES, page: () => const MyFutureRidesScreen()),

    // ✨ Non-Vehicle Driver Routes
    GetPage(
      name: Routes.NON_VEHICLE_REGISTER,
      page: () => const NonVehiclePersonalInfoScreen(),
    ),
    GetPage(
      name: Routes.NON_VEHICLE_DOCUMENTS,
      page: () => const NonVehicleDocumentsScreen(),
    ),
    GetPage(
      name: Routes.NON_VEHICLE_SUBSCRIPTION,
      page: () => const NonVehicleSubscriptionPlansScreen(),
      // ⭐ IMPORTANT: Add middleware to check subscription status
      middlewares: [SubscriptionCheckMiddleware()],
    ),
    GetPage(name: Routes.MAIN, page: () => const MainScreen()),

    // 💰 Withdrawal/Payout Routes
    GetPage(
      name: Routes.WITHDRAWAL_REQUEST,
      page: () => const WithdrawalRequestScreen(),
    ),
    GetPage(
      name: Routes.PAYOUT_HISTORY,
      page: () => const PayoutHistoryScreen(),
    ),
  ];
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final tokenManager = Get.find<TokenManager>();
    final driverId = tokenManager.userId.value;

    if (driverId == null || driverId.isEmpty) {
      // Not logged in, redirect to login
      return const RouteSettings(name: Routes.NON_VEHICLE_LOGIN);
    }

    // Check if subscription is active
    // You can add subscription check here if needed
    return null; // Allow access
  }
}

// ⭐ NEW: Middleware for subscription screen
class SubscriptionCheckMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // You can add logic here if needed
    return null;
  }
}
