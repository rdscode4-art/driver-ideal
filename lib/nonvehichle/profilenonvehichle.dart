import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/nonvehichle/documentscreennonvehichle.dart';
import 'package:rideal_driver/nonvehichle/nonvehichleedit.dart';
import 'package:rideal_driver/presentation/widgets/contact_info_section.dart';
import 'package:rideal_driver/presentation/widgets/social_media_links.dart';
import '../controllers/auth_controller.dart';
import 'package:rideal_driver/nonvehichle/non_vehichle_profile_controller.dart';
import 'package:rideal_driver/presentation/screens/delete_account_screen.dart';

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
                        colors: [Colors.orange[500]!, Colors.orange[400]!],
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
                                    final profilePic = controller.profilePicUrl.value;
                                    print('📸 ProfileScreennonvehichle image: $profilePic');
                                    
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
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('❌ NonVehicle Profile image error: $error');
                                                  return const Icon(Icons.person, size: 32, color: Colors.orange);
                                                },
                                              )
                                            : const Icon(Icons.person, size: 32, color: Colors.orange),
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
                                                  : Colors.orange[100],
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
                                                      : Colors.orange[700],
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
                                                        : Colors.orange[700],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.purple[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.purple[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 20),
            Center(
              child: Obx(() => Text(
                controller.formattedWallet,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildPersonalInfoCard() {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 2,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: Colors.blue[700], size: 24),
                  ),
                  const SizedBox(width: 12),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreenNon()));
                },
                icon: Icon(Icons.edit, color: Colors.blue[700]),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => _buildInfoRow(
            Icons.person_outline,
            'Full Name',
            controller.name.value.isNotEmpty
                ? controller.name.value
                : 'Not Set',
            Colors.blue,
          )),
          const SizedBox(height: 16),
          Obx(() => _buildInfoRow(
            Icons.phone_outlined,
            'Phone Number',
            controller.phone.value.isNotEmpty
                ? controller.phone.value
                : 'Not Set',
            Colors.green,
          )),
          const SizedBox(height: 16),
          Obx(() => _buildInfoRow(
            Icons.cake_outlined,
            'Age',
            controller.age.value.isNotEmpty
                ? '${controller.age.value} years'
                : 'Not Set',
            Colors.orange,
          )),
          const SizedBox(height: 16),
          Obx(() => _buildInfoRow(
            Icons.wc_outlined,
            'Gender',
            controller.formattedGender,
            Colors.purple,
          )),
        ],
      ),
    ),
  );
}
  Widget _buildDocumentsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 20),
            Obx(() => _buildInfoRow(
              Icons.credit_card,
              'Driving License',
              controller.maskedDL,
              Colors.blue,
            )),
            const SizedBox(height: 16),
            Obx(() => _buildInfoRow(
              Icons.badge_outlined,
              'Aadhaar Number',
              controller.maskedAadhaar,
              Colors.orange,
            )),
            const SizedBox(height: 16),
            Obx(() => _buildInfoRow(
              Icons.verified_user_outlined,
              'Verification Status',
              controller.verificationStatus.value,
              controller.isVerified.value ? Colors.green : Colors.orange,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptionsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildMenuOption(
              icon: Icons.description,
              title: 'My Documents',
              subtitle: 'View uploaded documents',
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>DocumentsScreen())),
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out of account',
              color: Colors.red,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: Colors.red[800]!,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DeleteAccountScreen()));
              },
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 20,
      color: Colors.grey[200],
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