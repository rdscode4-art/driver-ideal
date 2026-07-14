import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../core/utils/app_snackbar.dart';
import 'non_vehichle_referral_controller.dart';
import '../data/models/referral_model.dart';
import 'non_vehichle_profile_controller.dart';
import 'package:share_plus/share_plus.dart';

class RewardsScreenNonVehicle extends StatefulWidget {
  const RewardsScreenNonVehicle({super.key});

  @override
  State<RewardsScreenNonVehicle> createState() => _RewardsScreenNonVehicleState();
}

class _RewardsScreenNonVehicleState extends State<RewardsScreenNonVehicle>
    with SingleTickerProviderStateMixin {
  final NonVehichleProfileController _profileController = Get.put(NonVehichleProfileController());

  String get myReferralCode => 
      _profileController.referralCode.value.isNotEmpty ? _profileController.referralCode.value : 'RIDEAL123';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final NonVehicleReferralController _referralController = Get.put(NonVehicleReferralController());

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Refer & Earn',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (_referralController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          );
        }

        final data = _referralController.referralData.value;
        final totalEarnings = data?.totalEarnings ?? 0;
        final totalFriends = data?.totalFriends ?? 0;
        final referrerBonus = data?.rewardScheme?.referrerBonus ?? 500;
        final refereeBonus = data?.rewardScheme?.refereeBonus ?? 300;
        final friends = data?.friends ?? [];

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner
                _buildHeroBanner(referrerBonus, refereeBonus),
                const SizedBox(height: 24),

                // Referral Code Section
                _buildReferralCodeSection(refereeBonus),
                const SizedBox(height: 24),

                // Statistics Section
                _buildStatisticsSection(totalEarnings, totalFriends),
                const SizedBox(height: 24),

                // How it Works Section
                _buildSectionTitle('How it Works'),
                const SizedBox(height: 16),
                _buildHowItWorksSteps(referrerBonus, refereeBonus),
                const SizedBox(height: 24),

                // Recent Referrals Section
                if (friends.isNotEmpty) ...[
                  _buildSectionTitle('Recent Referrals'),
                  const SizedBox(height: 16),
                  _buildRecentReferralsList(friends),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeroBanner(double referrerBonus, double refereeBonus) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Refer Friends & Earn',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            referrerBonus > 0 && refereeBonus > 0
                ? 'Get ₹${referrerBonus.toInt()} for each successful driver referral upon sign up, and your friend gets ₹${refereeBonus.toInt()}.'
                : referrerBonus > 0
                ? 'Get ₹${referrerBonus.toInt()} for each successful driver referral upon sign up.'
                : refereeBonus > 0
                ? 'Invite a friend and they get ₹${refereeBonus.toInt()} upon sign up.'
                : 'Invite your friends to join RiDeal!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(double refereeBonus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Your Referral Code'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      myReferralCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: myReferralCode));
                        showSuccessSnackBar(
                          'Referral code copied to clipboard',
                          title: 'Copied!',
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _shareReferralCode(refereeBonus),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  'Share Code',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(double totalEarnings, int totalFriends) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Your Earnings'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Earned',
                '₹${totalEarnings.toInt()}',
                const Color(0xFF10B981),
                Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Friends Joined',
                '$totalFriends',
                const Color(0xFF3B82F6),
                Icons.people_alt_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSteps(double referrerBonus, double refereeBonus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStepItem(
            '1',
            'Share Code',
            'Send your unique code to friends.',
            isLast: false,
          ),
          _buildStepItem(
            '2',
            'Friend Signs Up',
            'They register on RiDeal using your code.',
            isLast: false,
          ),
          _buildStepItem(
            '3',
            'Friend Joins',
            'Friend successfully registers on the app.',
            isLast: false,
          ),
          _buildStepItem(
            '4',
            'Earn Reward',
            referrerBonus > 0 && refereeBonus > 0
                ? 'You get ₹${referrerBonus.toInt()} & your friend gets ₹${refereeBonus.toInt()}.'
                : referrerBonus > 0
                ? 'You get ₹${referrerBonus.toInt()}.'
                : refereeBonus > 0
                ? 'Your friend gets ₹${refereeBonus.toInt()}.'
                : 'You both enjoy the RiDeal experience.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    String step,
    String title,
    String subtitle, {
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
              ),
              child: Center(
                child: Text(
                  step,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey[200]),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReferralsList(List<ReferralFriend> friends) {
    return Column(
      children: friends.map((friend) {
        return _buildReferralListItem(
          name: friend.name,
          status:
              'Joined on ${friend.createdAt.day}/${friend.createdAt.month}/${friend.createdAt.year}',
          amount: '₹${friend.referrerBonus.toInt()}',
          isCompleted: friend.referrerBonus > 0,
        );
      }).toList(),
    );
  }

  Widget _buildReferralListItem({
    required String name,
    required String status,
    required String amount,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isCompleted
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFFF59E0B).withOpacity(0.1),
            child: Text(
              name[0].toUpperCase(),
              style: GoogleFonts.inter(
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : Colors.grey[600],
                    fontWeight: isCompleted
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.grey[500],
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ),
    );
  }

  void _shareReferralCode(double refereeBonus) {
    String bonusText = refereeBonus > 0
        ? '🎁 ₹${refereeBonus.toInt()} bonus for new drivers\n'
        : '';
    final String message =
        '''
Use my referral code $myReferralCode to join RiDeal!
$bonusText
Download the app and start your journey as a driver today!
https://play.google.com/store/apps/details?id=com.rds.ridealdriver
''';

    Share.share(message);
  }
}
