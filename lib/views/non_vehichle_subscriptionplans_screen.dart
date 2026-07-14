import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'nonvehicle_subscription_controller.dart';
import '../core/utils/app_snackbar.dart';

class NonVehicleSubscriptionPlansScreen extends StatefulWidget {
  const NonVehicleSubscriptionPlansScreen({super.key});

  @override
  State<NonVehicleSubscriptionPlansScreen> createState() =>
      _NonVehicleSubscriptionPlansScreenState();
}

class _NonVehicleSubscriptionPlansScreenState
    extends State<NonVehicleSubscriptionPlansScreen> {
  late NonVehicleSubscriptionController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    controller = Get.put(NonVehicleSubscriptionController());

    // 🆕 Listen to subscription status changes for auto-redirect after payment
    ever(controller.subscriptionStatus, (status) {
      print('🔄 Status changed to: $status');
      // Only redirect if status becomes active (after payment success)
      final statusLower = status.toLowerCase();
      if (statusLower == 'active' || statusLower == 'subscribed') {
        print('✅ Payment success detected - subscription now active');
        _handlePaymentSuccessRedirect();
      }
    });

    // Load initial status when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadSubscriptionStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscription Plans',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null,
        actions: [
          Obx(() {
            if (controller.isSubscriptionActive) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.green[600],
                  avatar: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              // ❌ REMOVED: Auto-redirect flag
              // controller.hasAutoRedirected = false;
              controller.refreshSubscriptionStatus();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange[700]),
                const SizedBox(height: 16),
                Text(
                  'Loading plans...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // ❌ REMOVED: Auto-redirect flag
                    // controller.hasAutoRedirected = false;
                    controller.refreshSubscriptionStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // ❌ REMOVED: Auto-redirect flag
            // controller.hasAutoRedirected = false;
            await controller.refreshSubscriptionStatus();
          },
          color: Colors.orange[700],
          child: Column(
            children: [
              // Status Banner
              _buildStatusBanner(controller),

              // Warning Banner (only if not active)
              if (!controller.isSubscriptionActive)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subscription Required',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You must activate a subscription to access the dashboard and start accepting rides.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the best plan for your needs',
                      style: TextStyle(color: Colors.green[700], fontSize: 15),
                    ),
                  ],
                ),
              ),

              // Plans List
              Expanded(
                child: controller.subscriptionPlans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.grey[400],
                            ),
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
                            TextButton.icon(
                              onPressed: () {
                                // ❌ REMOVED: Auto-redirect flag
                                // controller.hasAutoRedirected = false;
                                controller.refreshSubscriptionStatus();
                              },
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.orange[700],
                              ),
                              label: Text(
                                'Refresh',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.subscriptionPlans.length,
                        itemBuilder: (context, index) {
                          final plan = controller.subscriptionPlans[index];
                          return PlanCard(
                            plan: plan,
                            isProcessing:
                                controller.isProcessingPayment.value &&
                                controller.selectedPlanId.value == plan.id,
                            onBuy: () => controller.buySubscription(plan),
                          );
                        },
                      ),
              ),

              // Continue Button (only show when active)
              if (controller.isSubscriptionActive)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[600]!, Colors.green[700]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.offAllNamed('/nonvehichledashboard');
                        showSuccessSnackBar(
                          'You can now start accepting rides.',
                          title: 'Welcome!',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue to Dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusBanner(NonVehicleSubscriptionController controller) {
    Color bgColor;
    Color textColor;
    Color iconColor;
    IconData icon;
    String title;
    String message;

    final status = controller.subscriptionStatus.value.toLowerCase();

    switch (status) {
      case 'active':
      case 'subscribed': // Handle both active and subscribed status
        bgColor = Colors.green[50]!;
        textColor = Colors.green[900]!;
        iconColor = Colors.green[600]!;
        icon = Icons.check_circle;
        title = 'Subscription Active';
        message = 'ubscription Active – Priority Leads & Support';
        break;
      case 'pending':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[900]!;
        iconColor = Colors.orange[600]!;
        icon = Icons.schedule;
        title = 'Payment Pending';
        message = 'Your payment is being processed. Please wait.';
        break;
      case 'expired':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[900]!;
        iconColor = Colors.red[600]!;
        icon = Icons.error_outline;
        title = 'Subscription Expired';
        message = 'Please renew your subscription to continue.';
        break;
      default:
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[900]!;
        iconColor = Colors.blue[600]!;
        icon = Icons.info_outline;
        title = 'No Active Subscription';
        message = 'Select a plan below to get started.';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
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
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(fontSize: 13, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle redirect after payment success - similar to vehicle drivers
  void _handlePaymentSuccessRedirect() {
    print('🎉 Payment successful - showing success and redirecting...');

    // Show success message
    showSuccessSnackBar(
      'Your subscription is now active. Redirecting to dashboard...',
      title: '🎉 Payment Successful!',
    );

    // Redirect to dashboard after showing success message
    Future.delayed(const Duration(milliseconds: 2000), () {
      // Use GetX navigation which doesn't require mounted check
      print('🚀 Redirecting to dashboard after payment success');
      Get.back(); // Go back to dashboard using GetX navigation
    });
  }
}

// Plan Card Widget
class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isProcessing;
  final VoidCallback onBuy;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isProcessing,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    plan.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.currency_rupee, color: Colors.green[700], size: 32),
                Text(
                  '${plan.rate}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '/total',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.formattedMonthlyRate,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.green[200], thickness: 1.5),
            const SizedBox(height: 12),

            // Features
            _buildFeature(Icons.check_circle, 'Unlimited ride requests'),
            const SizedBox(height: 8),
            _buildFeature(Icons.support_agent, '24/7 Priority support'),
            const SizedBox(height: 8),
            _buildFeature(
              Icons.calendar_today,
              'Valid for ${plan.formattedDuration}',
            ),
            const SizedBox(height: 8),
            _buildFeature(Icons.security, 'Secure payment gateway'),

            const SizedBox(height: 16),

            // Buy Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProcessing
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : [Colors.green[600]!, Colors.green[700]!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isProcessing ? Colors.grey : Colors.green)
                        .withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isProcessing ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.transparent,
                ),
                child: isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Buy Subscription',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
