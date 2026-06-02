package com.rds.ridealdriver

import android.os.Bundle
import android.view.WindowManager
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val GPU_FIX_CHANNEL = "razorpay_gpu_fix"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Fix BLASTBufferQueue errors - Multiple strategies
        try {
            // Strategy 1: Enable hardware acceleration (already in manifest but enforce here)
            window.setFlags(
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
            )
            
            // Strategy 2: Keep screen on to prevent buffer issues
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            
            // Strategy 3: Set layout in display cutout mode for better rendering
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                window.attributes.layoutInDisplayCutoutMode = 
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
            
            // Strategy 4: Reduce overdraw by setting window format
            window.setFormat(android.graphics.PixelFormat.RGBA_8888)
            
        } catch (e: Exception) {
            println("⚠️ GPU optimization failed: ${e.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup GPU fix channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GPU_FIX_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "configureWebViewForRazorpay" -> {
                    try {
                        // Enable hardware acceleration for better performance
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("GPU_ERROR", e.message, null)
                    }
                }
                "disableHardwareAcceleration" -> {
                    try {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("GPU_ERROR", e.message, null)
                    }
                }
                "clearWebViewCache" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Ensure UI visibility to prevent rendering issues
        try {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        } catch (e: Exception) {
            println("⚠️ UI visibility setting failed: ${e.message}")
        }
    }
}
