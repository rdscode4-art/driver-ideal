// Test file for debugging Razorpay Payment Service
// Run: flutter run lib/test_razorpay_debug.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'services/razorpay_payment_service.dart';
import 'core/utils/app_snackbar.dart';

void main() {
  runApp(RazorpayTestApp());
}

class RazorpayTestApp extends StatelessWidget {
  const RazorpayTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(title: 'Razorpay Test', home: RazorpayTestScreen());
  }
}

class RazorpayTestScreen extends StatefulWidget {
  const RazorpayTestScreen({super.key});

  @override
  _RazorpayTestScreenState createState() => _RazorpayTestScreenState();
}

class _RazorpayTestScreenState extends State<RazorpayTestScreen> {
  late RazorpayPaymentService _paymentService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentService = RazorpayPaymentService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _testPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    print('🧪 ═══════════════════════════════════════');
    print('🧪 STARTING RAZORPAY TEST PAYMENT');
    print('🧪 ═══════════════════════════════════════');

    await _paymentService.processPayment(
      amount: 99.0, // ₹99 test amount
      description: 'Test Plan',
      driverId: 'test_driver_123',
      planId: 'test_plan_456',
      driverName: 'Test Driver',
      driverEmail: 'test@example.com',
      driverPhone: '9876543210',
      planType: 'Test Plan',
      onVerificationSuccess: (result) {
        print('✅ Payment Success: $result');
        showSuccessSnackBar(
          'Payment completed successfully',
          title: 'Success!',
        );
        setState(() {
          _isProcessing = false;
        });
      },
      onError: (error) {
        print('❌ Payment Error: $error');
        showErrorSnackBar(
          error,
          title: 'Error!',
        );
        setState(() {
          _isProcessing = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Razorpay Test'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Razorpay Payment Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isProcessing ? null : _testPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: _isProcessing
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Test Payment ₹99',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
            SizedBox(height: 20),
            if (_isProcessing)
              Text(
                'Processing payment...',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
