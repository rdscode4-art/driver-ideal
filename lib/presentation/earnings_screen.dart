import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/presentation/rewards_screen.dart';
import '../controllers/earnings_controller.dart';
import 'widgets/app_logo.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String selectedPeriod = 'Daily';

  @override
  void initState() {
    super.initState();
    // Fetch earnings data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<EarningsController>();
      controller.fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final EarningsController controller = Get.find();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        // Show loading indicator while fetching data
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: Colors.orange[600]),
          );
        }

        // Show error message if API call failed
        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load earnings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    controller.error.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => controller.fetchEarnings(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: CustomScrollView(
            slivers: [
              // Custom App Bar with gradient
              SliverAppBar(
                expandedHeight: 330,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[600]!, Colors.orange[300]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Column(
                          children: [
                            // App Logo at the top
                            const AppLogo(
                              width: 120,
                              height: 120,
                              margin: EdgeInsets.only(bottom: 20),
                            ),

                            // Period Selection Tabs
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(38),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: ['Daily', 'Weekly', 'Monthly'].map((
                                  period,
                                ) {
                                  bool isSelected = selectedPeriod == period;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => selectedPeriod = period,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          period,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.orange[600]
                                                : Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Main Earnings Display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$selectedPeriod Earnings',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Obx(() {
                                      double value = selectedPeriod == 'Daily'
                                          ? controller.todayEarnings.value
                                          : selectedPeriod == 'Weekly'
                                          ? controller.weekEarnings.value
                                          : controller.monthEarnings.value;
                                      return Text(
                                        '₹${value.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.trending_up,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Body content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Earnings Summary Cards
                      _buildEarningsSummarySection(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEarningsSummarySection() {
    final controller = Get.find<EarningsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        // Total Earnings Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  Colors.green[600]!.withOpacity(0.1),
                  Colors.green[400]!.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
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
                        'Wallet Earnings',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          '₹${controller.walletEarnings.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Withdrawal Button - Disabled when balance is zero
        Obx(
          () {
            final hasBalance = controller.walletEarnings.value > 0;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasBalance
                    ? () {
                        Get.toNamed('/withdrawal-request');
                      }
                    : null, // null makes button disabled
                icon: const Icon(Icons.payments, size: 22),
                label: Text(
                  hasBalance ? 'Withdraw Money' : 'No Balance Available',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasBalance ? Colors.green[700] : Colors.grey[400],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: hasBalance ? 3 : 0,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // View Withdrawal History Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Get.toNamed('/payout-history');
            },
            icon: Icon(Icons.history, size: 22, color: Colors.green[700]),
            label: Text(
              'Withdrawal History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.green[700]!, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Period-wise Earnings Grid
        Row(
          children: [
            Expanded(
              child: _buildPeriodCard(
                'Today',
                controller.todayEarnings.value,
                Icons.today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPeriodCard(
                'This Week',
                controller.weekEarnings.value,
                Icons.calendar_view_week,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildPeriodCard(
                'This Month',
                controller.monthEarnings.value,
                Icons.calendar_month,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Bonuses Section - Show as potential/available bonuses
        Text(
          'Available Bonuses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete these goals to earn extra rewards',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        // Excellence Bonus
        _buildBonusCard(
          title: 'Excellence Bonus',
          subtitle: '${controller.driverRating.value}★ rating maintained',
          amount: controller.ratingBonus.value,
          icon: Icons.star,
          color: Colors.purple,
          description: 'Maintain 4.8+ rating for weekly bonus',
          isActive: controller.driverRating.value >= 4.8,
        ),

        const SizedBox(height: 12),

        // Referral Bonus
        _buildBonusCard(
          title: 'Referral Bonus',
          subtitle: '${controller.referredDrivers.value} drivers referred',
          amount: controller.referralBonus.value,
          icon: Icons.people,
          color: Colors.green,
          description: 'Earn ₹500 for each driver you refer',
          isActive: controller.referredDrivers.value > 0,
        ),

        const SizedBox(height: 12),

        // Weekly Goal Bonus
        _buildBonusCard(
          title: 'Weekly Goal Bonus',
          subtitle:
              '${controller.weeklyTripsCompleted.value}/${controller.weeklyTripsTarget.value} trips',
          amount: controller.weeklyGoalBonus.value,
          icon: Icons.flag,
          color: Colors.indigo,
          description:
              'Complete ${controller.weeklyTripsTarget.value} trips for bonus',
          isActive:
              controller.weeklyTripsCompleted.value >=
              controller.weeklyTripsTarget.value,
          progress:
              controller.weeklyTripsCompleted.value /
              controller.weeklyTripsTarget.value,
        ),

        const SizedBox(height: 20),

        // Quick Actions
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Refer Driver',
                Icons.person_add,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RewardsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Refresh',
                Icons.refresh,
                Colors.blue,
                () => controller.fetchEarnings(),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildPeriodCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(14),
        height: 105,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusCard({
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
    required Color color,
    required String description,
    required bool isActive,
    double? progress,
    bool isLimitedTime = false,
  }) {
    return Card(
      elevation: isActive ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: color.withValues(alpha: 0.3), width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isActive ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (isLimitedTime) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'LIMITED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amount > 0 ? '+₹${amount.toStringAsFixed(0)}' : '₹0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: amount > 0 ? Colors.green[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
