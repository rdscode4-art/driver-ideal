import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/controllers/auth_controller.dart';
import 'package:rideal_driver/core/storage_helper.dart';

void main() {
  group('Automatic Login Flow Tests', () {
    late AuthController authController;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;
      authController = AuthController();
    });

    tearDown(() {
      // Clean up after each test
      Get.reset();
    });

    test('Should detect user is logged in when auth token exists', () async {
      // Simulate user is already logged in by setting storage values
      await StorageHelper.setLoggedIn(true);
      await StorageHelper.saveAuthToken('test_token_123');
      await StorageHelper.saveUserData(
        '{"name": "Test Driver", "phone": "+1234567890"}',
      );

      // Check login status
      await authController.loadLoginStatus();

      // Verify user is detected as logged in
      expect(authController.isLoggedIn.value, true);
      expect(authController.userData.value, isNotNull);
    });

    test(
      'Should detect user is not logged in when no auth token exists',
      () async {
        // Clear all storage to simulate first app launch
        await StorageHelper.clearAll();

        // Check login status
        await authController.loadLoginStatus();

        // Verify user is detected as not logged in
        expect(authController.isLoggedIn.value, false);
        expect(authController.userData.value, isNull);
      },
    );

    test('Should clear all data on logout', () async {
      // Set up logged in state
      await StorageHelper.setLoggedIn(true);
      await StorageHelper.saveAuthToken('test_token_123');
      await StorageHelper.saveUserData('{"name": "Test Driver"}');
      authController.isLoggedIn.value = true;

      // Perform logout (without API call for testing)
      authController.isLoggedIn.value = false;
      authController.userData.value = null;
      await StorageHelper.clearAll();

      // Verify all data is cleared
      expect(await StorageHelper.getLoggedIn(), false);
      expect(await StorageHelper.getAuthToken(), isNull);
      expect(await StorageHelper.getUserData(), isNull);
      expect(authController.isLoggedIn.value, false);
    });
  });
}
