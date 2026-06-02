import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Demo screen to test the complete Razorpay subscription flow
class RazorpaySubscriptionDemo extends StatelessWidget {
  const RazorpaySubscriptionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Razorpay Subscription Demo'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'RiDeal Subscription System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete Razorpay integration with:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              '1️⃣ CREATE ORDER',
              'POST /api/non-vehicle-driver/buy-subscription',
              'Creates Razorpay order with driverId, planId, amount',
              Colors.blue,
            ),
            _buildFeatureCard(
              '2️⃣ PAYMENT FLOW',
              'Razorpay Flutter SDK',
              'Opens payment UI → handles success/failure',
              Colors.orange,
            ),
            _buildFeatureCard(
              '3️⃣ VERIFY PAYMENT',
              'POST /api/non-vehicle-driver/verify-payment',
              'Verifies signature & activates subscription',
              Colors.green,
            ),
            _buildFeatureCard(
              '4️⃣ UPDATE UI',
              'GET /api/non-vehicle-driver/status/{id}',
              'Refreshes subscription status automatically',
              Colors.purple,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Get.toNamed('/rideal-subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Open Buy Subscription Screen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🔧 Configuration Needed:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const Text(
              '• Update Razorpay key in ProductionSubscriptionController\n'
              '• Replace placeholder user phone/email methods\n'
              '• Test with your backend endpoints',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    String description,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 4, height: 60, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add this to your routes (app_pages.dart):
/*
GetPage(
  name: '/rideal-subscription-demo',
  page: () => const RazorpaySubscriptionDemo(),
),
GetPage(
  name: '/rideal-subscription',
  page: () => const RidealBuySubscriptionScreen(),
),
*/
