import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class AndroidGpuFixer {
  static const MethodChannel _channel = MethodChannel('razorpay_gpu_fix');
  static bool _isInitialized = false;

  /// Fix Android GPU auxiliary issues including BLASTBufferQueue errors
  static Future<void> fixAndroidGpuIssues() async {
    if (_isInitialized) {
      debugPrint('⚠️ GPU fixes already applied, skipping...');
      return;
    }

    try {
      debugPrint('🔧 Applying Android GPU compatibility fixes...');

      // Only run on Android
      if (Platform.isAndroid) {
        // Call native Android method to configure hardware acceleration
        await _channel.invokeMethod('configureWebViewForRazorpay');

        // Mark as initialized to prevent duplicate calls
        _isInitialized = true;

        debugPrint('✅ Android GPU fixes applied successfully');
      } else {
        debugPrint('ℹ️ Skipping GPU fixes (not Android)');
      }
    } on PlatformException catch (e) {
      debugPrint('⚠️ Android GPU fix failed (continuing): ${e.message}');
      _isInitialized = true; // Mark as attempted even if failed
    } catch (e) {
      debugPrint('⚠️ GPU fix error (non-critical): $e');
      _isInitialized = true; // Mark as attempted even if failed
    }
  }

  /// Apply WebView hardware acceleration settings
  static Future<void> configureHardwareAcceleration() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disableHardwareAcceleration');
        debugPrint('✅ Hardware acceleration configured');
      }
    } catch (e) {
      debugPrint('⚠️ Hardware acceleration config failed: $e');
    }
  }

  /// Clear WebView cache to prevent GPU errors
  static Future<void> clearWebViewCache() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('clearWebViewCache');
        debugPrint('✅ WebView cache cleared');
      }
    } catch (e) {
      debugPrint('⚠️ Cache clear failed: $e');
    }
  }

  /// Reset initialization flag (for testing)
  static void reset() {
    _isInitialized = false;
    debugPrint('🔄 GPU fixer reset');
  }
}
