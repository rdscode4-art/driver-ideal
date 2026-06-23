import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal_driver/presentation/rewards_screen.dart';
import '../controllers/earnings_controller.dart';
// import 'widgets/app_logo.dart'; // Kept commented if needed later

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String selectedPeriod = 'Daily';
  final Color primaryGreen = const Color(0xFF0F9D58); // Fresh Green

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<EarningsController>();
      controller.fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final EarningsController controller = Get.find();

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Earnings',
            style: GoogleFonts.inter(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (controller.error.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: Colors.red[400]),
                  SizedBox(height: 16.h),
                  Text(
                    'Failed to load earnings',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      controller.error.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchEarnings(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refreshAll,
            color: primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(controller),
                    SizedBox(height: 24.h),
                    _buildEarningsSummarySection(controller),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopHeader(EarningsController controller) {
    return Column(
      children: [
        // Period Selection Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: ['Daily', 'Weekly', 'Monthly'].map((period) {
              bool isSelected = selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedPeriod = period),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4.r,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      period,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: isSelected ? primaryGreen : Colors.grey[600],
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 24.h),

        // Main Earnings Display
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10.r,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedPeriod Earnings',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(() {
                    double value = selectedPeriod == 'Daily'
                        ? controller.todayEarnings.value
                        : selectedPeriod == 'Weekly'
                        ? controller.weekEarnings.value
                        : controller.monthEarnings.value;
                    return Text(
                      '₹${value.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up, color: primaryGreen, size: 28.w),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSummarySection(EarningsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Summary',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16.h),

        // Total Earnings Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10.r,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: primaryGreen.withOpacity(0.3)),
          ),
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: primaryGreen,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Earnings',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Obx(
                      () => Text(
                        '₹${controller.walletEarnings.value.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Withdrawal Button
        Obx(() {
          final hasBalance = controller.walletEarnings.value > 0;
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasBalance
                  ? () => Get.toNamed('/withdrawal-request')
                  : null,
              icon: Icon(Icons.payments, size: 22.w),
              label: Text(
                hasBalance ? 'Withdraw Money' : 'No Balance Available',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasBalance ? primaryGreen : Colors.grey[200],
                foregroundColor: hasBalance ? Colors.white : Colors.grey[500],
                elevation: hasBalance ? 2 : 0,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          );
        }),

        SizedBox(height: 12.h),

        // View Withdrawal History Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.toNamed('/payout-history'),
            icon: Icon(Icons.history, size: 22.w, color: primaryGreen),
            label: Text(
              'Withdrawal History',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              side: BorderSide(
                color: primaryGreen.withOpacity(0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ),

        SizedBox(height: 24.h),

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
            SizedBox(width: 12.w),
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
        SizedBox(height: 12.h),
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
            SizedBox(width: 12.w),
            Expanded(child: Container()),
          ],
        ),

        SizedBox(height: 24.h),

        // Bonuses Section
        Text(
          'Available Bonuses',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Complete these goals to earn extra rewards',
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[500]),
        ),
        SizedBox(height: 16.h),

        // Excellence Bonus
        _buildBonusCard(
          title: 'Excellence Bonus',
          subtitle: '${controller.driverRating.value}★ rating maintained',
          amount: controller.ratingBonus.value,
          icon: Icons.star,
          color: primaryGreen,
          description: 'Maintain 4.8+ rating for weekly bonus',
          isActive: controller.driverRating.value >= 4.8,
        ),
        SizedBox(height: 12.h),

        // Referral Bonus
        _buildBonusCard(
          title: 'Referral Bonus',
          subtitle: '${controller.referredDrivers.value} drivers referred',
          amount: controller.referralBonus.value,
          icon: Icons.people,
          color: primaryGreen,
          description: 'Earn ₹500 for each driver you refer',
          isActive: controller.referredDrivers.value > 0,
        ),
        SizedBox(height: 12.h),

        // Weekly Goal Bonus
        _buildBonusCard(
          title: 'Weekly Goal Bonus',
          subtitle:
              '${controller.weeklyTripsCompleted.value}/${controller.weeklyTripsTarget.value} trips',
          amount: controller.weeklyGoalBonus.value,
          icon: Icons.flag,
          color: primaryGreen,
          description:
              'Complete ${controller.weeklyTripsTarget.value} trips for bonus',
          isActive:
              controller.weeklyTripsCompleted.value >=
              controller.weeklyTripsTarget.value,
          progress:
              controller.weeklyTripsCompleted.value /
              (controller.weeklyTripsTarget.value > 0
                  ? controller.weeklyTripsTarget.value
                  : 1),
        ),

        SizedBox(height: 24.h),

        // Quick Actions
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16.h),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Refer Driver',
                Icons.person_add,
                primaryGreen,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RewardsScreen(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildQuickActionCard(
                'Refresh',
                Icons.refresh,
                primaryGreen,
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
    return Container(
      padding: EdgeInsets.all(16.w),
      height: 110.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 18.w),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
        border: isActive
            ? Border.all(color: color.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.grey[100]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isActive ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? color : Colors.grey[400],
                    size: 22.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (isLimitedTime) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'LIMITED',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[600],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amount > 0 ? '+₹${amount.toStringAsFixed(0)}' : '₹0',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: amount > 0 ? color : Colors.grey[400],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              SizedBox(height: 16.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6.h,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24.w),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
