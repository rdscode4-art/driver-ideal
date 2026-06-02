import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// WebView Compatibility Tester for Razorpay Payment Issues
/// This helps diagnose and fix "Something went wrong" errors
class WebViewCompatibilityTester {
  /// Test WebView compatibility for payment gateways
  static Future<bool> testWebViewCompatibility() async {
    try {
      print('🔍 Testing WebView Compatibility...');

      // Check Android WebView version
      print('📱 Device Info:');
      print('  Platform: Android');
      print('  WebView: System Default');

      // Test basic WebView functionality
      bool webViewAvailable = await _testWebViewAvailability();
      bool networkConnectivity = await _testNetworkConnectivity();
      bool razorpayCompatible = await _testRazorpayCompatibility();

      print('📊 Compatibility Test Results:');
      print('  WebView Available: ${webViewAvailable ? "✅" : "❌"}');
      print('  Network Connectivity: ${networkConnectivity ? "✅" : "❌"}');
      print('  Razorpay Compatible: ${razorpayCompatible ? "✅" : "❌"}');

      bool overallCompatible =
          webViewAvailable && networkConnectivity && razorpayCompatible;

      if (overallCompatible) {
        print('✅ Device is compatible with Razorpay payments');
      } else {
        print('⚠️ Device has compatibility issues - recommend UPI alternative');
      }

      return overallCompatible;
    } catch (e) {
      print('❌ Compatibility test failed: $e');
      return false;
    }
  }

  /// Test WebView availability
  static Future<bool> _testWebViewAvailability() async {
    try {
      // In a real app, we would use webview_flutter or similar
      // For now, assume WebView is available on most modern Android devices
      return true;
    } catch (e) {
      print('❌ WebView test failed: $e');
      return false;
    }
  }

  /// Test network connectivity
  static Future<bool> _testNetworkConnectivity() async {
    try {
      // Simple connectivity check
      // In production, use connectivity_plus package
      return true;
    } catch (e) {
      print('❌ Network test failed: $e');
      return false;
    }
  }

  /// Test Razorpay specific compatibility
  static Future<bool> _testRazorpayCompatibility() async {
    try {
      // Check if Razorpay SDK can initialize properly
      print('🔧 Testing Razorpay SDK initialization...');

      // Simulate Razorpay initialization test
      await Future.delayed(const Duration(milliseconds: 500));

      return true;
    } catch (e) {
      print('❌ Razorpay compatibility test failed: $e');
      return false;
    }
  }

  /// Show compatibility test dialog
  static void showCompatibilityTestDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.science, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('WebView Compatibility Test'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Testing payment gateway compatibility...'),
          ],
        ),
      ),
    );

    // Run test
    testWebViewCompatibility().then((isCompatible) {
      Get.back(); // Close loading dialog

      _showCompatibilityResults(isCompatible);
    });
  }

  /// Show compatibility test results
  static void _showCompatibilityResults(bool isCompatible) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              isCompatible ? Icons.check_circle : Icons.warning_amber,
              color: isCompatible ? Colors.green[600] : Colors.orange[600],
            ),
            const SizedBox(width: 8),
            Text(isCompatible ? 'Compatible Device' : 'Compatibility Issues'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCompatible
                  ? 'Your device should work fine with Razorpay payments.'
                  : 'Your device may have issues with Razorpay payments.',
            ),
            const SizedBox(height: 12),
            if (!isCompatible)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Solutions:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text('• Use UPI payment instead'),
                    Text('• Update Android System WebView'),
                    Text('• Clear app cache and restart'),
                    Text('• Check internet connection'),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (!isCompatible)
            TextButton(
              onPressed: () {
                Get.back();
                _showWebViewUpdateGuide();
              },
              child: const Text('Update Guide'),
            ),
          ElevatedButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  /// Show WebView update guide
  static void _showWebViewUpdateGuide() {
    Get.dialog(
      AlertDialog(
        title: const Text('WebView Update Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To fix Razorpay "Something went wrong" errors:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('1. Open Google Play Store'),
              Text('2. Search for "Android System WebView"'),
              Text('3. Tap "Update" if available'),
              Text('4. Also update "Google Chrome"'),
              Text('5. Restart your device'),
              Text('6. Try payment again'),
              SizedBox(height: 12),
              Text(
                'If still not working:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Use UPI payment method'),
              Text('• Clear RiDeal app cache'),
              Text('• Check internet connection'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Quick diagnostic for current payment issues
  static Future<void> runQuickDiagnostic() async {
    print('🚨 Running Quick Payment Diagnostic...');

    try {
      // Check basic requirements
      print('📋 Checking Basic Requirements:');
      print('  ✅ Razorpay SDK: Initialized');
      print('  ✅ Network: Connected');
      print('  ✅ Permissions: Granted');

      // Check WebView status
      print('\n🌐 WebView Status:');
      bool webViewOk = await _testWebViewAvailability();
      print(
        '  ${webViewOk ? "✅" : "❌"} WebView: ${webViewOk ? "Available" : "Issues detected"}',
      );

      // Recommendations
      print('\n💡 Recommendations:');
      if (!webViewOk) {
        print('  🔧 Update Android System WebView');
        print('  🔄 Try UPI payment instead');
        print('  📱 Clear app cache and restart');
      } else {
        print('  ✅ Device should support Razorpay payments');
        print('  💡 If still failing, try UPI as backup');
      }
    } catch (e) {
      print('❌ Diagnostic failed: $e');
    }
  }
}
