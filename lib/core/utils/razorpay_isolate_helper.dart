import 'package:flutter/foundation.dart';

/// Critical fix for WebView blocking - runs Razorpay in isolate
class RazorpayIsolateHelper {
  /// Process Razorpay options in background isolate to prevent main thread blocking
  static Future<Map<String, dynamic>> processRazorpayOptionsInIsolate({
    required String keyId,
    required int amountInPaise,
    required String orderId,
    required String phone,
    required String email,
    required String name,
    required String driverId,
    required String planType,
  }) async {
    // Use compute to run in separate isolate
    return await compute(_processRazorpayOptionsBackground, {
      'keyId': keyId,
      'amountInPaise': amountInPaise,
      'orderId': orderId,
      'phone': phone,
      'email': email,
      'name': name,
      'driverId': driverId,
      'planType': planType,
    });
  }

  /// Background function that runs in isolate (must be top-level function)
  static Map<String, dynamic> _processRazorpayOptionsBackground(
    Map<String, dynamic> params,
  ) {
    // Create optimized Razorpay options without blocking main thread
    return {
      'key': params['keyId'],
      'amount': params['amountInPaise'],
      'currency': 'INR',
      'name': 'RiDeal Driver',
      'description': 'Subscription: ${params['planType']}',
      'order_id': params['orderId'],
      'timeout': 120, // Reduced to 2 minutes for faster failure
      'prefill': {
        'contact': params['phone'],
        'email': params['email'],
        'name': params['name'],
      },
      'theme': {'color': '#2196F3'},
      'method': {'upi': true, 'card': true, 'netbanking': true, 'wallet': true},
      'notes': {
        'driver_id': params['driverId'],
        'plan_type': params['planType'],
      },
      // Critical: Remove all closures and complex nested objects
      'modal': {
        'backdropclose': false,
        'escape': false,
        'handleback': true,
        'confirm_close': true,
      },
    };
  }

  /// Pre-process payment data to reduce runtime processing
  static Map<String, String> preprocessPaymentData({
    required String phone,
    required String email,
    required String name,
  }) {
    // Process phone number
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final validPhone = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : '9999999999';

    // Process email
    final trimmedEmail = email.trim();
    final validEmail = trimmedEmail.isEmpty
        ? 'driver@rideal.app'
        : trimmedEmail;

    // Process name
    final trimmedName = name.trim();
    final validName = trimmedName.isEmpty ? 'Driver' : trimmedName;

    return {'phone': validPhone, 'email': validEmail, 'name': validName};
  }
}
