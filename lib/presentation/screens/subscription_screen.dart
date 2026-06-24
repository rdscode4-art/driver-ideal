import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_controller.dart';
import '../../services/new_razorpay_service.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_colors.dart';

/// 🎯 Complete Subscription Screen
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late PaymentController controller;

  @override
  void initState() {
    super.initState();
    // Initialize dependencies
    Get.put(ApiService(), permanent: true);
    Get.put(RazorpayService(), permanent: true);
    controller = Get.put(PaymentController(), permanent: true);

    // Fetch plans after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.availablePlans.isEmpty &&
          !controller.isLoadingPlans.value) {
        controller.fetchAvailablePlans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Choose Subscription',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchAvailablePlans(),
            tooltip: 'Refresh Plans',
          ),
        ],
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // Current Status Card
              _buildStatusCard(controller),
              const SizedBox(height: 24),

              // Available Plans
              _buildPlansSection(controller),
              const SizedBox(height: 24),

              // Payment Button
              _buildPaymentButton(controller),
              const SizedBox(height: 24),

              // Debug Information (for development)
              if (controller.paymentStatus.value != PaymentStatus.idle)
                _buildDebugSection(controller),
            ],
          ),
        );
      }),
    );
  }

  /// Header section with app info
  Widget _buildHeaderSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [darkGreen, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.star, color: Colors.white, size: 32),
            SizedBox(height: 12),
            Text(
              'RiDeal Driver Subscription',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unlock premium features and start earning more with our subscription plans.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Status card showing current payment state
  Widget _buildStatusCard(PaymentController controller) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusSubtext;

    switch (controller.paymentStatus.value) {
      case PaymentStatus.idle:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
        statusText = 'Ready to Subscribe';
        statusSubtext = 'Choose a plan to get started';
        break;
      case PaymentStatus.processing:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Processing Payment';
        statusSubtext = 'Please wait while we process your payment...';
        break;
      case PaymentStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Payment Successful';
        statusSubtext = controller.successMessage.value;
        break;
      case PaymentStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Payment Failed';
        statusSubtext = controller.errorMessage.value;
        break;
      case PaymentStatus.verifying:
        statusColor = Colors.blue;
        statusIcon = Icons.verified;
        statusText = 'Verifying Payment';
        statusSubtext = 'Confirming your payment with our servers...';
        break;
      case PaymentStatus.externalWallet:
        statusColor = Colors.purple;
        statusIcon = Icons.account_balance_wallet;
        statusText = 'External Wallet';
        statusSubtext = 'Redirecting to external wallet...';
        break;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusSubtext,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (controller.isProcessingPayment.value)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  /// Available subscription plans
  Widget _buildPlansSection(PaymentController controller) {
    return Obx(() {
      // Show loading indicator
      if (controller.isLoadingPlans.value) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading subscription plans...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      // Show message if no plans
      if (controller.availablePlans.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Subscription Plans Available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to load plans. Please check your internet connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => controller.fetchAvailablePlans(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Show plans
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Plans',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.availablePlans.length} plans',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...controller.availablePlans.map(
            (plan) => _buildPlanCard(plan, controller),
          ),
        ],
      );
    });
  }

  /// Individual plan card
  Widget _buildPlanCard(SubscriptionPlan plan, PaymentController controller) {
    final isSelected = controller.selectedPlan.value?.id == plan.id;
    final isPopular = plan.name.toLowerCase().contains('premium');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 8 : 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isSelected
                  ? const BorderSide(color: primaryGreen, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => controller.selectPlan(plan),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? primaryGreen
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '₹${plan.amount.toInt()}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? primaryGreen
                                : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (plan.duration != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Duration: ${plan.duration}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (plan.features != null && plan.features!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...plan.features!.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Payment button
  Widget _buildPaymentButton(PaymentController controller) {
    final isDisabled =
        controller.selectedPlan.value == null ||
        controller.isProcessingPayment.value;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isDisabled
            ? null
            : () async {
                final plan = controller.selectedPlan.value!;
                await controller.buySubscription(
                  planName: plan.name,
                  planId: plan.id!,
                  amount: plan.amount,
                  contact: '9876543210',
                  email: 'driver@example.com',
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: controller.isLoading.value
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : Text(
                controller.selectedPlan.value != null
                    ? 'Buy ${controller.selectedPlan.value!.name} - ₹${controller.selectedPlan.value!.amount.toInt()}'
                    : 'Select a Plan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Debug section
  Widget _buildDebugSection(PaymentController controller) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: const Text('Debug Information'),
        subtitle: Text('Status: ${controller.paymentStatus.value.name}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Debug Info:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.getDebugInfo().toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.paymentStatus.value == PaymentStatus.failed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => controller.retryPayment(),
                      child: const Text('Retry Payment'),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => controller.cleanupPaymentSession(),
                    child: const Text('Reset Session'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
