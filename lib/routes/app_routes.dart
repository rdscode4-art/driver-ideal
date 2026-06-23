part of 'app_pages.dart';

abstract class Routes {
  static const HOME = '/';
  static const ROLE_SELECTION = '/role-selection';
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const OTP_VERIFICATION = '/otp-verification';
  static const PROFILE = '/profile';
  static const EDIT_PROFILE = '/edit-profile';
  static const MAP = '/map';
  static const DASHBOARD = '/dashboard';
  static const EARNINGS = '/earnings';
  static const ONBOARDING = '/onboarding';
  static const NOTIFICATIONS = '/notifications';
  static const SPLASH = '/splash';
  static const WALLET = '/wallet';
  static const SETTINGS = '/settings';
  static const RATINGS = '/ratings';
  static const CHAT = '/chat';
  static const KYC_DOCUMENTS = '/kyc-documents';
  static const REWARDS = '/rewards';
  static const AVAILABLE_RIDES = '/available-rides';
  static const RIDE_REQUESTS = '/ride-requests';
  static const FUTURE_RIDES = '/future-rides';
  static const CREATE_FUTURE_RIDE = '/create-future-ride';
  static const MY_FUTURE_RIDES = '/my-future-rides';
  static const TRIP_HISTORY = '/trip-history';
  static const ONGOING_RIDE = '/ongoing-ride';
  static const NAVIGATION = '/navigation';
  static const YOUR_TRIPS = '/your-trips';
  static const HELP = '/help';
  static const SUPPORT = '/support';
  static const FUTURE_RIDE_DETAILS = '/future-ride-details';

  // Additional routes for settings screen
  static const VEHICLE_INFO = '/vehicle-info';
  static const NOTIFICATION_SETTINGS = '/notification-settings';
  static const PRIVACY_SETTINGS = '/privacy-settings';
  static const HELP_CENTER = '/help-center';
  static const RATING_FEEDBACK = '/rating-feedback';
  static const REPORT_ISSUE = '/report-issue';
  static const ABOUT = '/about';
  static const TERMS = '/terms';
  static const PRIVACY_POLICY = '/privacy-policy';
  static const SUBSCRIPTION = '/subscription';
  static const NONVEHICHLEDASHBOARD = '/nonvehichledashboard';
  // ✨ Non-Vehicle Driver Routes
  static const NON_VEHICLE_REGISTER = '/non-vehicle-register';
  static const NON_VEHICLE_DOCUMENTS = '/non-vehicle-documents';
  static const NON_VEHICLE_LOGIN = '/non-vehicle-login';
  static const NON_VEHICLE_OTP = '/non-vehicle-otp';
  static const NON_VEHICLE_SUBSCRIPTION = '/non-vehicle-subscription';
  static const SUBSCRIPTION_TEST = '/subscription-test';

  // 💰 Withdrawal/Payout Routes
  static const WITHDRAWAL_REQUEST = '/withdrawal-request';
  static const PAYOUT_HISTORY = '/payout-history';

  static const MAIN = '/main';
}
