import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/production_subscription_controller.dart';

class UpdatedSubscriptionPlansScreen extends StatefulWidget {
  const UpdatedSubscriptionPlansScreen({super.key});

  @override
  State<UpdatedSubscriptionPlansScreen> createState() =>
      _UpdatedSubscriptionPlansScreenState();
}

class _UpdatedSubscriptionPlansScreenState
    extends State<UpdatedSubscriptionPlansScreen> {
  late ProductionSubscriptionController controller;

  @override
  void initState() {
    super.initState();
    // Initialize production controller
    controller = Get.put(ProductionSubscriptionController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Choose Subscription Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            // Always allow back navigation
            Get.back();
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshSubscriptionStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Current Subscription Status
                _buildSubscriptionStatusCard(),

                const SizedBox(height: 24),

                // Plans Section
                _buildPlansSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatusCard() {
    return Obx(() {
      final details = controller.subscriptionDetails;
      final isActive = controller.hasActiveSubscription;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey[600]!, Colors.grey[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    details['title'] ?? 'Subscription Status',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              details['subtitle'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (details['startDate'] != null)
                    Expanded(
                      child: Text(
                        details['startDate']!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (details['amount'] != null)
                    Text(
                      details['amount']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Plans',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingState();
          }

          if (controller.hasError.value) {
            return _buildErrorState();
          }

          return _buildPlansList();
        }),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading subscription plans...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load subscription status',
            style: TextStyle(
              color: Colors.red[800],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              controller.errorMessage.value,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.loadSubscriptionStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    return Obx(() {
      final plans = controller.subscriptionPlans;

      if (plans.isEmpty) {
        return _buildEmptyPlansState();
      }

      return Column(
        children: plans.map((plan) => _buildPlanCard(plan)).toList(),
      );
    });
  }

  Widget _buildEmptyPlansState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No plans available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check back later or contact support',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(plan) {
    final isActive = controller.hasActiveSubscription;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: plan.id == '68ede14b0efa19665b81303e'
            ? Border.all(color: Colors.orange[400]!, width: 2)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (plan.id == '68ede14b0efa19665b81303e') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'SPECIAL',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.formattedDuration,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${plan.rate}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    plan.formattedMonthlyRate,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            final isCreatingOrder = controller.isCreatingOrder.value;
            final isVerifyingPayment = controller.isVerifyingPayment.value;
            final isProcessing = isCreatingOrder || isVerifyingPayment;

            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (isActive || isProcessing)
                    ? null
                    : () => controller.buySubscription(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.id == '68ede14b0efa19665b81303e'
                      ? Colors.orange[600]
                      : Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCreatingOrder
                                ? 'Creating Order...'
                                : 'Verifying Payment...',
                          ),
                        ],
                      )
                    : Text(
                        isActive ? 'Already Subscribed' : 'Choose Plan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controller if needed
    super.dispose();
  }
}
