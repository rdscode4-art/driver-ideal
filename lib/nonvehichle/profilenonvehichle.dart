import 'package:flutter/material.dart';
import 'package:rideal_driver/core/app_theme.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/nonvehichle/documentscreennonvehichle.dart';
import 'package:rideal_driver/nonvehichle/nonvehichleedit.dart';
import 'package:rideal_driver/presentation/widgets/contact_info_section.dart';
import 'package:rideal_driver/presentation/widgets/social_media_links.dart';
import '../controllers/auth_controller.dart';
import 'package:rideal_driver/nonvehichle/non_vehichle_profile_controller.dart';
import 'package:rideal_driver/presentation/screens/delete_account_screen.dart';
import 'package:rideal_driver/nonvehichle/rewards_screen_nonvehichle.dart';
import 'package:rideal_driver/presentation/support_screen.dart';

class ProfileScreennonvehichle extends StatefulWidget {
  const ProfileScreennonvehichle({super.key});

  @override
  State<ProfileScreennonvehichle> createState() =>
      _ProfileScreennonvehichleState();
}

class _ProfileScreennonvehichleState extends State<ProfileScreennonvehichle> {
  late final NonVehichleProfileController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<NonVehichleProfileController>()) {
      controller = Get.find<NonVehichleProfileController>();
    } else {
      controller = Get.put(NonVehichleProfileController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchProfile(),
          child: CustomScrollView(
            slivers: [
              // Custom App Bar with gradient
              SliverAppBar(
                expandedHeight: 280,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withOpacity(0.8),
                        ],
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
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 20),
                            // App Logo at the top
                            Image.asset(
                              "assets/images/logo.png",
                              width: 140,
                              height: 80,
                            ),

                            const SizedBox(height: 8),
                            // Profile Section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🆕 Profile Image with Network Support
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Obx(() {
                                    final profilePic =
                                        controller.profilePicUrl.value;
                                    print(
                                      '📸 ProfileScreennonvehichle image: $profilePic',
                                    );

                                    return CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: profilePic.isNotEmpty
                                            ? Image.network(
                                                profilePic,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      print(
                                                        '❌ NonVehicle Profile image error: $error',
                                                      );
                                                      return const Icon(
                                                        Icons.person,
                                                        size: 32,
                                                        color: AppTheme.primary,
                                                      );
                                                    },
                                              )
                                            : const Icon(
                                                Icons.person,
                                                size: 32,
                                                color: AppTheme.primary,
                                              ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "RiDeal Driver",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.name.isNotEmpty
                                            ? controller.name.value
                                            : 'Driver',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // RND ID below name
                                      if (controller.rndId.value.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            'ID: ${controller.rndId.value}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 4),

                                      // Phone and Verification Badge
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            controller.phone.value,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          // Verification badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: controller.isVerified.value
                                                  ? Colors.green[100]
                                                  : AppTheme.primary
                                                        .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  controller.isVerified.value
                                                      ? Icons.verified
                                                      : Icons.pending,
                                                  size: 12,
                                                  color:
                                                      controller
                                                          .isVerified
                                                          .value
                                                      ? Colors.green[700]
                                                      : AppTheme.primary,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  controller
                                                      .verificationStatus
                                                      .value,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        controller
                                                            .isVerified
                                                            .value
                                                        ? Colors.green[700]
                                                        : AppTheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
                    children: [
                      // Wallet Balance Card
                      _buildWalletCard(),

                      const SizedBox(height: 16),

                      // Personal Information Card
                      _buildPersonalInfoCard(),

                      const SizedBox(height: 16),

                      // Documents Card
                      _buildDocumentsCard(),

                      const SizedBox(height: 16),

                      // Menu Options Card
                      _buildMenuOptionsCard(context),

                      const SizedBox(height: 20),

                      // Social Media Links
                      const SocialMediaLinksEnhanced(),

                      const ContactInfoSection(),
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

  Widget _buildWalletCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Obx(
                () => Text(
                  controller.formattedWallet,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.blue[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                // 🆕 Edit Button
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreenNon(),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[50]),
                  icon: Icon(
                    Icons.edit_rounded,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(
              () => _buildInfoRow(
                Icons.badge_rounded,
                'Full Name',
                controller.name.value.isNotEmpty
                    ? controller.name.value
                    : 'Not Set',
                Colors.blue[600]!,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => _buildInfoRow(
                Icons.phone_rounded,
                'Phone Number',
                controller.phone.value.isNotEmpty
                    ? controller.phone.value
                    : 'Not Set',
                AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => _buildInfoRow(
                Icons.cake_rounded,
                'Age',
                controller.age.value.isNotEmpty
                    ? '${controller.age.value} years'
                    : 'Not Set',
                Colors.orange[600]!,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => _buildInfoRow(
                Icons.wc_rounded,
                'Gender',
                controller.formattedGender,
                Colors.purple[600]!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(
              () => _buildInfoRow(
                Icons.credit_card_rounded,
                'Driving License',
                controller.maskedDL,
                Colors.orange[600]!,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => _buildInfoRow(
                Icons.pin_rounded,
                'Aadhaar Number',
                controller.maskedAadhaar,
                Colors.blue[600]!,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => _buildInfoRow(
                Icons.verified_user_rounded,
                'Verification Status',
                controller.verificationStatus.value,
                controller.isVerified.value
                    ? AppTheme.primary
                    : Colors.orange[700]!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptionsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            _buildMenuOption(
              icon: Icons.card_giftcard_rounded,
              title: 'Refer & Earn',
              subtitle: 'Invite friends & earn rewards',
              color: Colors.green[600]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RewardsScreenNonVehicle()),
              ),
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.description_rounded,
              title: 'My Documents',
              subtitle: 'View uploaded documents',
              color: Colors.blue[600]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DocumentsScreen()),
              ),
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.help_outline_rounded,
              title: 'Support',
              subtitle: 'Get help with your account',
              color: Colors.purple[600]!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportScreen()),
              ),
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'Sign out of account',
              color: Colors.orange[700]!,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: Colors.red[700]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountScreen(),
                  ),
                );
              },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: title == 'My Documents' ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
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
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 74, right: 24),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Log Out'),
          ],
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              final authController = Get.find<AuthController>();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
