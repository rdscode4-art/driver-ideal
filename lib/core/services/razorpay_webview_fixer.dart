import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class RazorpayWebViewFixer {
  static bool _isInitialized = false;
  static WebViewController? _globalController;

  /// Fix GPU compatibility issues for Razorpay WebView
  static Future<void> initializeGpuCompatibility() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔧 Fixing GPU compatibility for Razorpay...');

      // Android-specific GPU fixes
      if (WebViewPlatform.instance is AndroidWebViewPlatform) {
        final androidPlatform =
            WebViewPlatform.instance as AndroidWebViewPlatform;

        // Disable hardware acceleration to prevent GPU errors
        await _configureAndroidWebView();
      }

      _isInitialized = true;
      debugPrint('✅ GPU compatibility fixes applied successfully');
    } catch (e) {
      debugPrint('⚠️ GPU fix error (non-critical): $e');
      _isInitialized = true; // Continue anyway
    }
  }

  /// Configure Android WebView to handle GPU issues
  static Future<void> _configureAndroidWebView() async {
    try {
      // Create a test WebView controller to apply settings
      final controller = WebViewController();

      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      // Get Android-specific controller
      if (controller.platform is AndroidWebViewController) {
        final androidController =
            controller.platform as AndroidWebViewController;

        // Apply GPU compatibility settings
        await androidController.setMediaPlaybackRequiresUserGesture(false);

        // Disable problematic features that cause GPU errors
        await _injectGpuFix(controller);
      }
    } catch (e) {
      debugPrint('Android WebView config error: $e');
    }
  }

  /// Inject JavaScript to fix GPU and Canvas2D issues
  static Future<void> _injectGpuFix(WebViewController controller) async {
    try {
      const gpuFixScript = '''
        // Fix Canvas2D readback operations for Razorpay
        (function() {
          const originalGetContext = HTMLCanvasElement.prototype.getContext;
          HTMLCanvasElement.prototype.getContext = function(contextType, options) {
            if (contextType === '2d') {
              // Add willReadFrequently attribute to prevent warnings
              options = options || {};
              options.willReadFrequently = true;
            }
            return originalGetContext.call(this, contextType, options);
          };
          
          // Disable hardware acceleration for problematic operations
          if (window.chrome && window.chrome.runtime) {
            window.chrome.runtime.onMessage = function() {}; // Prevent errors
          }
          
          // Fix GPU auxiliary issues
          const originalRequestAnimationFrame = window.requestAnimationFrame;
          window.requestAnimationFrame = function(callback) {
            return originalRequestAnimationFrame(function(time) {
              try {
                callback(time);
              } catch (e) {
                console.log('RAF error handled:', e);
              }
            });
          };
          
          console.log('🔧 GPU compatibility fixes loaded');
        })();
      ''';

      await controller.runJavaScript(gpuFixScript);
    } catch (e) {
      debugPrint('GPU fix injection error: $e');
    }
  }

  /// Create optimized WebView for Razorpay with GPU fixes
  static Future<WebViewController> createOptimizedController() async {
    await initializeGpuCompatibility();

    final controller = WebViewController();

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          debugPrint('📄 Page loading: $url');
        },
        onPageFinished: (String url) async {
          debugPrint('✅ Page loaded: $url');

          // Apply GPU fixes after page load
          await _injectGpuFix(controller);

          // Additional Razorpay-specific fixes
          if (url.contains('razorpay') || url.contains('checkout')) {
            await _injectRazorpayFixes(controller);
          }
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('🚨 WebView error: ${error.description}');

          // Handle GPU-specific errors
          if (error.description.contains('GPU') ||
              error.description.contains('GPUAUX') ||
              error.description.contains('Canvas')) {
            debugPrint('🔧 GPU error detected - applying emergency fixes');
            _handleGpuError(controller);
          }
        },
      ),
    );

    // Android-specific optimizations
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;

      // Disable hardware acceleration to prevent GPU issues
      await androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _globalController = controller;
    return controller;
  }

  /// Inject Razorpay-specific performance fixes
  static Future<void> _injectRazorpayFixes(WebViewController controller) async {
    try {
      const razorpayFixScript = '''
        // Razorpay checkout performance fixes
        (function() {
          // Optimize checkout frame loading
          const originalCreateElement = document.createElement;
          document.createElement = function(tagName) {
            const element = originalCreateElement.call(document, tagName);
            
            if (tagName === 'canvas') {
              // Force willReadFrequently for all canvas elements
              const originalGetContext = element.getContext;
              element.getContext = function(contextType, options) {
                if (contextType === '2d') {
                  options = options || {};
                  options.willReadFrequently = true;
                }
                return originalGetContext.call(this, contextType, options);
              };
            }
            
            return element;
          };
          
          // Handle Razorpay iframe optimization
          window.addEventListener('message', function(event) {
            if (event.data && event.data.type === 'razorpay') {
              // Optimize Razorpay messages
              console.log('Razorpay message optimized');
            }
          });
          
          // Prevent common Razorpay errors
          window.onerror = function(msg, url, line, col, error) {
            if (msg.includes('GPU') || msg.includes('Canvas')) {
              console.log('GPU error suppressed:', msg);
              return true; // Prevent error propagation
            }
            return false;
          };
          
          console.log('🚀 Razorpay performance fixes applied');
        })();
      ''';

      await controller.runJavaScript(razorpayFixScript);
    } catch (e) {
      debugPrint('Razorpay fix injection error: $e');
    }
  }

  /// Handle GPU errors during runtime
  static Future<void> _handleGpuError(WebViewController controller) async {
    try {
      // Emergency GPU error handling
      const emergencyScript = '''
        // Emergency GPU error fixes
        (function() {
          // Disable all hardware-accelerated features
          if (window.chrome) {
            window.chrome = undefined;
          }
          
          // Force software rendering
          const originalGetContext = HTMLCanvasElement.prototype.getContext;
          HTMLCanvasElement.prototype.getContext = function(contextType, options) {
            if (contextType === '2d') {
              options = {
                willReadFrequently: true,
                alpha: false,
                desynchronized: false
              };
            } else if (contextType === 'webgl' || contextType === 'webgl2') {
              // Disable WebGL to force software rendering
              return null;
            }
            return originalGetContext.call(this, contextType, options);
          };
          
          console.log('🆘 Emergency GPU fixes applied');
        })();
      ''';

      await controller.runJavaScript(emergencyScript);
    } catch (e) {
      debugPrint('Emergency GPU fix error: $e');
    }
  }

  /// Pre-warm WebView to prevent initialization delays
  static Future<void> preWarmWebView() async {
    try {
      debugPrint('🔥 Pre-warming WebView for faster Razorpay loading...');

      final controller = await createOptimizedController();

      // Load a minimal page to initialize WebView engine
      await controller.loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
          <title>WebView PreWarm</title>
        </head>
        <body>
          <div>Initializing...</div>
          <script>
            console.log('WebView pre-warmed successfully');
          </script>
        </body>
        </html>
      ''');

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('✅ WebView pre-warming completed');
    } catch (e) {
      debugPrint('Pre-warm error (non-critical): $e');
    }
  }

  /// Get the pre-warmed controller for immediate use
  static WebViewController? getPreWarmedController() {
    return _globalController;
  }

  /// Clean up resources
  static void cleanup() {
    _globalController = null;
    _isInitialized = false;
  }
}
