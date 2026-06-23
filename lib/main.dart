import 'package:get_storage/get_storage.dart';
import 'package:rideal_driver/controllers/earnings_controller.dart';
import 'package:rideal_driver/controllers/non_vehicle_auth_controller.dart';
import 'package:rideal_driver/core/token_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/presentation/kyc_documents_screen.dart';
import 'package:rideal_driver/subscriptioncontroller.dart';
import 'package:rideal_driver/views/documentsuploadscreen.dart';
import 'package:rideal_driver/views/nonvehicle_subscription_controller.dart';
import 'controllers/auth_controller.dart';
import 'routes/app_pages.dart';
import 'core/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'fcm_service.dart';
import 'core/services/android_gpu_fixer.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('************************************************');
  print('🚀 APP STARTING - RIDEAL DRIVER');
  print('************************************************');

  // Fix Android GPU/BLASTBufferQueue errors
  await AndroidGpuFixer.fixAndroidGpuIssues();

  await Firebase.initializeApp();

  // Initialize FCM - this will handle token retrieval properly
  await FCMService().initialize();

  await GetStorage.init();

  // ⭐ CRITICAL: Initialize TokenManager first
  Get.put(TokenManager.instance, permanent: true);
  await TokenManager.instance.loadToken();

  print('🔍 Loaded Token at startup: ${TokenManager.instance.authToken.value}');
  print('🔍 User Role: ${TokenManager.instance.userRole.value}');
  print('🔍 User ID: ${TokenManager.instance.userId.value}');

  // ⭐ ALWAYS initialize these core controllers
  Get.put(AuthController(), permanent: true);
  Get.put(EarningsController(), permanent: true);
  Get.put(NonVehicleAuthController(), permanent: true);

  //UNCOMMENT WHEN PAYMENT INTEGRATION COME
  Get.put(SubscriptionController(), permanent: true);
  Get.put(NonVehicleSubscriptionController(), permanent: true);

  // ⭐ FIX: ONLY initialize dashboard controllers if user has active subscription
  // DO NOT load ProfileController, HomeController, etc. during app startup
  // They will be lazily loaded only when user reaches dashboard

  print('✅ Core controllers initialized');
  print('📱 Dashboard controllers will load on-demand');

  // 🧪 API Test (uncomment for testing)
  // APIIntegrationTest.runAllTests();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard iPhone X / 11 Pro size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Rideal Partner',
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          initialRoute: Routes.SPLASH,
          defaultTransition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 300),
          getPages: AppPages.routes,
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
