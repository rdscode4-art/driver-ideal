import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/utils/app_snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/rides_api_service.dart';

class PaymentQRScreen extends StatefulWidget {
  final String qrCode;
  final String orderId;
  final String rideId;
  final int amount;
  final String currency;

  const PaymentQRScreen({
    required this.qrCode,
    required this.orderId,
    required this.rideId,
    required this.amount,
    this.currency = 'INR',
    super.key,
  });

  @override
  State<PaymentQRScreen> createState() => _PaymentQRScreenState();
}

class _PaymentQRScreenState extends State<PaymentQRScreen> {
  Timer? _statusCheckTimer;
  final ValueNotifier<int> _secondsCounter = ValueNotifier<int>(0);
  final RidesApiService _ridesApiService = RidesApiService();

  @override
  void initState() {
    super.initState();
    print('🏦 PaymentQRScreen initialized');
    print('📱 Order ID: ${widget.orderId}');
    print('💰 Amount: ₹${widget.amount / 100}');
    _startPaymentStatusCheck();
  }

  void _startPaymentStatusCheck() {
    print('🔄 Starting payment status check (UI update every 1s, API every 3s)');
    
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (mounted) {
          _secondsCounter.value++;
        }

        final int currentSeconds = _secondsCounter.value;

        // Only hit the API every 3 seconds
        if (currentSeconds % 3 == 0) {
          print('🔍 API Payment check at ${currentSeconds}s');
          try {
            final response = await _ridesApiService.verifyRazorpayPayment(widget.rideId);

            if (response['success'] == true) {
              final String paymentStatus = (response['paymentStatus'] ?? '').toString().toLowerCase();

              if (paymentStatus == 'paid') {
                timer.cancel();
                
                print('✅ Payment verified via paymentStatus: paid');
                
                showSuccessSnackBar(
                  response['message'] ?? 'Payment verified and ride completed',
                  title: '✅ Success',
                );

                await Future.delayed(const Duration(seconds: 1));
                Get.offAllNamed('/');
              }
            }
          } catch (e) {
            print('❌ Error checking payment: $e');
          }
        }

        // Timeout after 5 minutes (300 seconds)
        if (currentSeconds >= 300) {
          timer.cancel();
          if (mounted) {
            Get.dialog(
              AlertDialog(
                title: const Text('⏱️ Timeout'),
                content: const Text('Payment verification timeout after 5 minutes'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                      Get.back();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _secondsCounter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Payment'),
        backgroundColor: Colors.orange[600],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Scan QR Code to Pay',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: widget.qrCode.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(widget.qrCode.split(',')[1]),
                        width: 250,
                        height: 250,
                      )
                    : const Icon(Icons.qr_code, size: 250),
              ),
              
              const SizedBox(height: 30),
              
              // Amount
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  '₹${(widget.amount / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.green[700],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Order ID: ${widget.orderId}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              
              const SizedBox(height: 30),
              
              // Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    ValueListenableBuilder<int>(
                      valueListenable: _secondsCounter,
                      builder: (context, seconds, child) {
                        return Text(
                          'Waiting for payment... (${seconds}s)',
                          style: const TextStyle(fontSize: 14),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}