import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/storage_helper.dart';
import '../routes/app_pages.dart';
import '../core/utils/app_snackbar.dart';

class SettingsController extends GetxController {
  // Reactive variables
  var driverName = 'John Doe'.obs;
  var driverEmail = 'john.doe@example.com'.obs;
  var selectedLanguage = 'en'.obs;
  var selectedTheme = 'light'.obs;
  var notificationsEnabled = true.obs;
  var locationEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    loadPreferences();
  }

  void loadUserData() async {
    // Load user data from storage or API
    final name = await StorageHelper.getString('driver_name');
    final email = await StorageHelper.getString('driver_email');

    if (name != null) driverName.value = name;
    if (email != null) driverEmail.value = email;
  }

  void loadPreferences() async {
    // Load user preferences
    final language = await StorageHelper.getString('selected_language') ?? 'en';
    final theme = await StorageHelper.getString('selected_theme') ?? 'light';
    final notifications = await StorageHelper.getBool('notifications_enabled');
    final location = await StorageHelper.getBool('location_enabled');
    final autoDetection = await StorageHelper.getBool('auto_detection_enabled');

    selectedLanguage.value = language;
    selectedTheme.value = theme;
    notificationsEnabled.value = notifications;
    locationEnabled.value = location;

    // Apply auto-detection setting globally
    if (autoDetection) {
      _enableAutoDetection();
    }
  }

  // Auto-detection management
  var autoDetectionEnabled = true.obs;

  void toggleAutoDetection(bool value) async {
    autoDetectionEnabled.value = value;
    await StorageHelper.setBool('auto_detection_enabled', value);

    if (value) {
      _enableAutoDetection();
    } else {
      _disableAutoDetection();
    }

    showInfoSnackBar(
      value
          ? 'Location will be detected automatically'
          : 'Manual location detection only',
      title: 'Auto-Detection ${value ? 'Enabled' : 'Disabled'}',
    );
  }

  void _enableAutoDetection() {
    // Enable auto-detection in ongoing ride controller if it exists
    try {
      final ongoingController =
          Get.find<dynamic>(); // Will find any ongoing ride controller
      if (ongoingController.runtimeType.toString().contains(
        'OngoingRideController',
      )) {
        ongoingController.enableAutoDetection();
      }
    } catch (e) {
      // Controller not found, will be enabled when controller is created
    }
  }

  void _disableAutoDetection() {
    // Disable auto-detection in ongoing ride controller if it exists
    try {
      final ongoingController = Get.find<dynamic>();
      if (ongoingController.runtimeType.toString().contains(
        'OngoingRideController',
      )) {
        ongoingController.disableAutoDetection();
      }
    } catch (e) {
      // Controller not found
    }
  }

  void changeLanguage(String language) async {
    selectedLanguage.value = language;
    await StorageHelper.setString('selected_language', language);

    // Update app locale
    Locale locale = language == 'hi'
        ? const Locale('hi', 'IN')
        : const Locale('en', 'US');
    Get.updateLocale(locale);

    showSuccessSnackBar(
      'App language updated successfully',
      title: 'Language Changed',
    );
  }

  void changeTheme(String theme) async {
    selectedTheme.value = theme;
    await StorageHelper.setString('selected_theme', theme);

    // Update app theme
    Get.changeThemeMode(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);

    showSuccessSnackBar(
      'App theme updated successfully',
      title: 'Theme Changed',
    );
  }

  void toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    await StorageHelper.setBool('notifications_enabled', value);

    showInfoSnackBar(
      'Notification settings updated',
      title: 'Notifications ${value ? 'Enabled' : 'Disabled'}',
    );
  }

  void toggleLocation(bool value) async {
    locationEnabled.value = value;
    await StorageHelper.setBool('location_enabled', value);

    showInfoSnackBar(
      'Location settings updated',
      title: 'Location ${value ? 'Enabled' : 'Disabled'}',
    );
  }

  void logout() async {
    try {
      // Clear all stored data
      await StorageHelper.clearAll();

      // Navigate to login screen
      Get.offAllNamed(Routes.LOGIN);

      showSuccessSnackBar(
        'You have been successfully logged out',
        title: 'Logged Out',
      );
    } catch (e) {
      showErrorSnackBar(
        'Failed to logout. Please try again.',
        title: 'Error',
      );
    }
  }
}
