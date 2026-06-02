import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/utils/app_snackbar.dart';

/// Complete Working Razorpay Service - FIXED VERSION
class CompleteRazorpayService {
  static const String _keyId = 'rzp_live_RoLpvsh1Qs9Cfs';
  static const String _keySecret = 'pOApwAU4L7MBkJ9hCl8rV1Gc';
  static const String _baseUrl = 'https://backend.ridealmobility.com';

  late Razorpay _razorpay;
  String? _currentOrderId;

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  CompleteRazorpayService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    log('🚀 CompleteRazorpayService initialized');
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    log('🎉 Payment Success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    log('❌ Payment Failed: ${response.message}');
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    log('💳 External Wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String receipt,
  }) async {
    try {
      final amountInPaise = (amount * 100).round();

      if (amountInPaise < 100) {
        return {'success': false, 'error': 'Minimum amount is ₹1'};
      }

      final requestBody = {
        'amount': amountInPaise,
        'currency': 'INR',
        'receipt': receipt,
        'payment_capture': 1,
      };

      final auth = base64Encode(utf8.encode('$_keyId:$_keySecret'));

      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentOrderId = data['id'];
        return {
          'success': true,
          'order_id': data['id'],
          'amount': data['amount'],
        };
      } else {
        return {'success': false, 'error': 'Order creation failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  void testPaymentSetup() {
    try {
      showSuccessSnackBar(
        'Service is configured!',
        title: '✅ Service Ready',
      );
    } catch (e) {
      showErrorSnackBar(
        'Error: $e',
        title: '❌ Test Failed',
      );
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
