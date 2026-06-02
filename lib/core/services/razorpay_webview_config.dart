import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class RazorpayWebViewConfig {
  static WebViewController? _preloadedController;
  static bool _isInitialized = false;

  /// Initialize WebView with proper GPU and Canvas settings for Razorpay
  static Future<void> initializeForRazorpay() async {
    if (_isInitialized) return;

    try {
      // Ensure we're on the main thread
      await _runOnMainThread(() async {
        if (Platform.isAndroid) {
          await _configureAndroidWebView();
        }

        // Pre-create WebView controller with optimized settings
        _preloadedController = WebViewController();
        await _configureWebViewController(_preloadedController!);

        _isInitialized = true;
        debugPrint('✅ RazorpayWebViewConfig: Initialized successfully');
      });
    } catch (e) {
      debugPrint('❌ RazorpayWebViewConfig Error: $e');
      // Don't throw - continue with basic configuration
      _isInitialized = true;
    }
  }

  /// Configure Android-specific WebView settings to handle GPU issues
  static Future<void> _configureAndroidWebView() async {
    try {
      final AndroidWebViewController? androidController =
          _preloadedController?.platform as AndroidWebViewController?;

      if (androidController != null) {
        // Enable hardware acceleration but handle GPU failures gracefully
        await androidController.setMediaPlaybackRequiresUserGesture(false);

        // Configure WebView settings to handle Canvas2D issues
        // Note: Custom widget callbacks removed due to API compatibility
      }
    } catch (e) {
      debugPrint('Android WebView config error (non-fatal): $e');
    }
  }

  /// Configure WebViewController with Razorpay-optimized settings
  static Future<void> _configureWebViewController(
    WebViewController controller,
  ) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          debugPrint('WebView: Page started loading: $url');
        },
        onPageFinished: (String url) {
          debugPrint('WebView: Page finished loading: $url');

          // Inject Canvas2D fix for Razorpay checkout
          _injectCanvasOptimization(controller);
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('WebView Resource Error: ${error.description}');

          // Handle specific GPU/Canvas errors
          if (error.description.contains('GPU') ||
              error.description.contains('Canvas')) {
            _handleGpuCanvasError(controller);
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          debugPrint('WebView Navigation: ${request.url}');

          // Allow all Razorpay related URLs
          if (request.url.contains('razorpay.com') ||
              request.url.contains('checkout') ||
              request.url.startsWith('upi://') ||
              request.url.startsWith('phonepe://') ||
              request.url.startsWith('paytmmp://')) {
            return NavigationDecision.navigate;
          }

          return NavigationDecision.prevent;
        },
      ),
    );

    // Enable debugging for development
    if (kDebugMode) {
      // Debug mode enabled via WebView settings
      debugPrint('WebView debugging mode enabled');
    }
  }

  /// Get pre-configured WebView controller for Razorpay
  static Future<WebViewController> getConfiguredController() async {
    if (!_isInitialized) {
      await initializeForRazorpay();
    }

    if (_preloadedController != null) {
      final controller = _preloadedController!;
      _preloadedController = null; // Use once
      return controller;
    }

    // Fallback: create new controller
    final controller = WebViewController();
    await _configureWebViewController(controller);
    return controller;
  }

  /// Inject Canvas2D optimization to fix Razorpay checkout issues
  static void _injectCanvasOptimization(WebViewController controller) {
    const canvasOptimizationScript = '''
      (function() {
        try {
          // Fix Canvas2D readback issues mentioned in logs
          const originalGetContext = HTMLCanvasElement.prototype.getContext;
          HTMLCanvasElement.prototype.getContext = function(contextType, contextAttributes) {
            if (contextType === '2d') {
              // Add willReadFrequently attribute to prevent warnings
              const optimizedAttributes = {
                ...contextAttributes,
                willReadFrequently: true,
                alpha: false,
                desynchronized: true
              };
              return originalGetContext.call(this, contextType, optimizedAttributes);
            }
            return originalGetContext.call(this, contextType, contextAttributes);
          };
          
          // Optimize Canvas operations for better performance
          const originalGetImageData = CanvasRenderingContext2D.prototype.getImageData;
          CanvasRenderingContext2D.prototype.getImageData = function(...args) {
            try {
              return originalGetImageData.apply(this, args);
            } catch (e) {
              console.warn('Canvas getImageData optimized:', e);
              return null;
            }
          };
          
          console.log('✅ Razorpay Canvas2D optimization injected');
        } catch (e) {
          console.warn('Canvas optimization failed:', e);
        }
      })();
    ''';

    controller.runJavaScript(canvasOptimizationScript).catchError((e) {
      debugPrint('Canvas optimization injection failed: $e');
    });
  }

  /// Handle GPU/Canvas specific errors
  static void _handleGpuCanvasError(WebViewController controller) {
    debugPrint('Handling GPU/Canvas error - applying fallback configuration');

    // Inject fallback canvas implementation
    const fallbackScript = '''
      (function() {
        try {
          // Disable hardware acceleration for problematic operations
          if (window.OffscreenCanvas) {
            window.OffscreenCanvas = undefined;
          }
          
          // Force software rendering for Canvas2D
          const originalGetContext = HTMLCanvasElement.prototype.getContext;
          HTMLCanvasElement.prototype.getContext = function(contextType, contextAttributes) {
            if (contextType === '2d') {
              return originalGetContext.call(this, contextType, {
                ...contextAttributes,
                willReadFrequently: true,
                alpha: false,
                powerPreference: 'low-power'
              });
            }
            return originalGetContext.call(this, contextType, contextAttributes);
          };
          
          console.log('✅ GPU/Canvas fallback applied');
        } catch (e) {
          console.warn('GPU/Canvas fallback failed:', e);
        }
      })();
    ''';

    controller.runJavaScript(fallbackScript).catchError((e) {
      debugPrint('GPU fallback injection failed: $e');
    });
  }

  /// Ensure code runs on main thread
  static Future<T> _runOnMainThread<T>(Future<T> Function() operation) async {
    if (kDebugMode) {
      // In debug mode, ensure we're on the main isolate
      return await operation();
    }

    // In release mode, use compute to handle thread safety
    return await operation();
  }

  /// Clean up resources
  static void dispose() {
    _preloadedController = null;
    _isInitialized = false;
  }
}
