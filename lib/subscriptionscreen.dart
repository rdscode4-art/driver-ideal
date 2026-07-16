import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/utils/app_snackbar.dart';
import 'package:rideal_driver/subscriptioncontroller.dart';
import 'models/active_subscription_model.dart';
import 'core/token_manager.dart';

class Plan {
  final String id;
  final String title;
  final int rate;
  final int durationInMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.title,
    required this.rate,
    required this.durationInMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['_id'],
      title: json['title'],
      rate: json['rate'],
      durationInMonths: json['durationInMonths'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

// 🔥 EMERGENCY BYPASS DIALOG
void showEmergencyBypass(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('🔥 Emergency Bypass'),
      content: const Text(
        'Razorpay payment is failing.\n\n'
        'IMMEDIATE OPTIONS:\n\n'
        '1. Skip payment & activate subscription\n'
        '2. Pay via UPI manually\n'
        '3. Contact support\n\n'
        'Choose your preferred option:',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);

            // BYPASS - Direct activation
            showSuccessSnackBar(
              'Subscription activated without payment',
              title: '✅ Bypass Activated',
            );

            Future.delayed(const Duration(seconds: 1), () {
              final tokenManager = Get.find<TokenManager>();
              if (tokenManager.isNonVehicleDriver) {
                Get.offAllNamed('/nonvehichledashboard');
              } else {
                Get.offAllNamed('/dashboard');
              }
            });
          },
          child: const Text('Skip Payment'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);

            // Manual UPI
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('UPI Payment'),
                content: const Text(
                  'Pay ₹1 to:\n\n'
                  'UPI ID: payment@rideal.com\n'
                  'Or PhonePe: 9999999999\n\n'
                  'Send screenshot to support.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('UPI Payment'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  late SubscriptionController controller;
  @override
  void initState() {
    super.initState();
    controller = Get.put(SubscriptionController());

    // Listen to subscription status changes for auto-redirect after payment
    ever(controller.subscriptionStatus, (status) {
      if (status.toLowerCase() == 'active' || status.toLowerCase() == 'subscribed') {
        // Only auto-redirect if we are not already on the dashboard
        if (Get.currentRoute != '/dashboard') {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Get.offAllNamed('/dashboard');
              Get.snackbar(
                'Welcome!',
                'You can now start accepting rides.',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            }
          });
        }
      }
    });
  }
  void _showPaymentMethodSheet(BuildContext context, SubscriptionPlan plan) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to pay ₹${plan.rate} for ${plan.title}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Wallet Option
            ListTile(
              onTap: () {
                Get.back(); // Close sheet
                controller.buySubscription(plan, paymentMethod: 'wallet');
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet, color: Colors.orange[700]),
              ),
              title: const Text('Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pay instantly using your driver wallet'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            const SizedBox(height: 12),
            
            // Online Option
            ListTile(
              onTap: () {
                Get.back(); // Close sheet
                controller.buySubscription(plan, paymentMethod: 'online');
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.credit_card, color: Colors.blue[700]),
              ),
              title: const Text('Online Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('UPI, Cards, Netbanking via Razorpay'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(SubscriptionController());
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
            if (controller.subscriptionActive.value) {
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
            onPressed: () => controller.refreshSubscriptionStatus(),
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
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadSubscriptionPlans(),
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
          onRefresh: () => controller.refreshSubscriptionStatus(),
          color: Colors.orange[700],
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
              ),
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
                        border: Border.all(
                          color: Colors.orange[300]!,
                          width: 2,
                        ),
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

                  // Plans List - Use fixed container height in scrollable content
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.subscriptionPlans.length,
                      itemBuilder: (context, index) {
                        final plan = controller.subscriptionPlans[index];
                        return PlanCard(
                          plan: plan,
                          isProcessing:
                              controller.isProcessingPayment.value &&
                              controller.selectedPlanId.value == plan.id,
                          onBuy: () async {
                            print('💳 Starting payment process for ${plan.title}');
                            
                            // Show processing state while checking wallet balance
                            controller.isProcessingPayment.value = true;
                            controller.selectedPlanId.value = plan.id;
                            
                            bool hasBalance = await controller.hasEnoughWalletBalance(plan.rate.toDouble());
                            
                            // Stop processing state before showing sheet or razorpay
                            controller.isProcessingPayment.value = false;
                            
                            if (hasBalance) {
                              _showPaymentMethodSheet(context, plan);
                            } else {
                              // If not enough balance, directly trigger online payment
                              controller.buySubscription(plan, paymentMethod: 'online');
                            }
                          },
                        );
                      },
                    ),
                  ),


                ],
              ),
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!controller.isSubscriptionActive) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
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
                  Get.offAllNamed('/dashboard');
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
        );
      }),
    );
  }

  Widget _buildStatusBanner(SubscriptionController controller) {
    return Obx(() {
      // Check if we have active subscription from API
      if (controller.activeSubscription.value != null) {
        final subscription = controller.activeSubscription.value!;
        return _buildActiveSubscriptionCard(subscription);
      }

      // Fallback to status-based display
      Color bgColor;
      Color textColor;
      Color iconColor;
      IconData icon;
      String title;
      String message;

      final status = controller.subscriptionStatus.value.toLowerCase();

      switch (status) {
        case 'active':
          bgColor = Colors.green[50]!;
          textColor = Colors.green[900]!;
          iconColor = Colors.green[600]!;
          icon = Icons.check_circle;
          title = 'Subscription Active';
          message = 'Your subscription is active. You can now accept rides.';
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
                  Text(
                    message,
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActiveSubscriptionCard(ActiveSubscriptionModel subscription) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with plan name and active badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[50]!, Colors.green[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.planName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${subscription.amount}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${subscription.duration}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expires on ${subscription.formattedExpiry}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (subscription.daysRemaining > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: subscription.daysRemaining <= 7
                          ? Colors.orange[50]
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: subscription.daysRemaining <= 7
                            ? Colors.orange[200]!
                            : Colors.blue[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          subscription.daysRemaining <= 7
                              ? Icons.warning_amber
                              : Icons.info_outline,
                          color: subscription.daysRemaining <= 7
                              ? Colors.orange[600]
                              : Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${subscription.daysRemaining} days remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: subscription.daysRemaining <= 7
                                ? Colors.orange[700]
                                : Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.durationInMonths == 12 || plan.durationInDays >= 360 || plan.title.toLowerCase().contains('year'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      Text(
                        plan.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
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
            // _buildFeature(Icons.check_circle, 'Unlimited ride requests'),
            // const SizedBox(height: 8),
            // _buildFeature(Icons.support_agent, '24/7 Priority support'),
            // const SizedBox(height: 8),
            // _buildFeature(Icons.calendar_today, 'Valid for ${plan.durationInMonths} months'),
            // const SizedBox(height: 8),
            // _buildFeature(Icons.security, 'Secure payment gateway'),
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
                    color: (isProcessing ? Colors.grey : Colors.orange)
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
}

// Plan Card Widget
