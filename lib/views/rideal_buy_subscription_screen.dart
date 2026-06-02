import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/production_subscription_controller.dart';
import '../models/rideal_subscription_models.dart';
import '../core/utils/app_snackbar.dart';

/// Complete Buy Subscription Screen with Razorpay Integration
/// Automatically updates UI based on subscription status
class RidealBuySubscriptionScreen extends StatefulWidget {
  const RidealBuySubscriptionScreen({super.key});

  @override
  State<RidealBuySubscriptionScreen> createState() =>
      _RidealBuySubscriptionScreenState();
}

class _RidealBuySubscriptionScreenState
    extends State<RidealBuySubscriptionScreen> {
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
          'Buy Subscription',
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
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
                // Subscription Status Card - dynamically updates
                _buildSubscriptionStatusCard(),

                const SizedBox(height: 24),

                // Available Plans Section
                _buildAvailablePlansSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build subscription status card that updates automatically
  Widget _buildSubscriptionStatusCard() {
    return Obx(() {
      final status = controller.subscriptionStatus.value;

      // Show different UI based on subscription status
      if (status != null && status.isActive) {
        return _buildActiveSubscriptionCard(status);
      } else {
        return _buildNoSubscriptionCard();
      }
    });
  }

  /// Active Subscription Card Widget
  Widget _buildActiveSubscriptionCard(RidealSubscriptionStatus status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with checkmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Subscription',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status.displayTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Subscription details
          _buildDetailRow(
            'Plan',
            status.plan?.title ?? 'Unknown',
            Icons.local_offer,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Amount',
            status.plan?.formattedTotalPrice ?? '₹0',
            Icons.currency_rupee,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Valid Until',
            status.formattedEndDate,
            Icons.schedule,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Days Remaining',
            '${status.daysRemaining} days',
            Icons.timelapse,
          ),

          const SizedBox(height: 20),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status.daysRemaining > 7 ? Icons.verified : Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status.daysRemaining > 7
                      ? 'Subscription Active'
                      : 'Expires Soon!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// No Subscription Card Widget
  Widget _buildNoSubscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[600]!, Colors.orange[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.subscriptions_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'No Active Subscription',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose a plan below to get started and unlock all features',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 20),

          // Call to action
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Select Plan Below',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build detail row for subscription info
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Available Plans Section
  Widget _buildAvailablePlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Plans',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the plan that works best for you',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Plans list
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

  /// Loading state
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

  /// Error state
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
            'Failed to load plans',
            style: TextStyle(
              color: Colors.red[800],
              fontSize: 18,
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

  /// Plans list
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

  /// Empty plans state
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

  /// Plan Card Widget - Reusable component
  Widget _buildPlanCard(RidealSubscriptionPlan plan) {
    final isActive = controller.hasActiveSubscription;
    final isCurrentPlan =
        controller.subscriptionStatus.value?.plan?.id == plan.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular
              ? Colors.orange[400]!
              : isCurrentPlan
              ? Colors.green[400]!
              : Colors.grey[200]!,
          width: plan.isPopular || isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badges
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (plan.isPopular) ...[
                          const SizedBox(width: 8),
                          _buildPopularBadge(),
                        ],
                        if (isCurrentPlan) ...[
                          const SizedBox(width: 8),
                          _buildCurrentPlanBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.formattedDuration,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (plan.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.description!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.formattedTotalPrice,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: plan.isPopular
                          ? Colors.orange[700]
                          : Colors.blue[700],
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

          // Features list (if available)
          if (plan.features != null && plan.features!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...plan.features!.map((feature) => _buildFeatureItem(feature)),
          ],

          const SizedBox(height: 20),

          // Buy button with loading state
          Obx(() {
            final isProcessing =
                controller.isCreatingOrder.value ||
                controller.isVerifyingPayment.value;

            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (isActive && !isCurrentPlan) || isProcessing
                    ? null
                    : () => _handleBuySubscription(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.isPopular
                      ? Colors.orange[600]
                      : isCurrentPlan
                      ? Colors.green[600]
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
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            controller.isCreatingOrder.value
                                ? 'Creating Order...'
                                : 'Verifying Payment...',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : Text(
                        _getButtonText(plan, isActive, isCurrentPlan),
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

  /// Popular badge widget
  Widget _buildPopularBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'POPULAR',
        style: TextStyle(
          color: Colors.orange[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Current plan badge widget
  Widget _buildCurrentPlanBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'CURRENT',
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Feature item widget
  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Get button text based on state
  String _getButtonText(
    RidealSubscriptionPlan plan,
    bool isActive,
    bool isCurrentPlan,
  ) {
    if (isCurrentPlan) {
      return 'Current Plan';
    } else if (isActive) {
      return 'Switch to This Plan';
    } else {
      return 'Buy Subscription - ${plan.formattedTotalPrice}';
    }
  }

  /// Handle buy subscription with complete Razorpay flow
  Future<void> _handleBuySubscription(RidealSubscriptionPlan plan) async {
    try {
      // Show confirmation dialog for expensive plans
      if (plan.rate > 200) {
        final confirmed = await _showConfirmationDialog(plan);
        if (!confirmed) return;
      }

      // Start the complete payment flow
      await controller.buySubscription(plan);
    } catch (e) {
      // Show error message
      showErrorSnackBar('Failed to start payment: $e');
    }
  }

  /// Show confirmation dialog for expensive plans
  Future<bool> _showConfirmationDialog(RidealSubscriptionPlan plan) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Purchase'),
            content: Text(
              'You are about to purchase ${plan.title} for ${plan.formattedTotalPrice}. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    // Cleanup controller if needed
    super.dispose();
  }
}
