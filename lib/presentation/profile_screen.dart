import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/presentation/screens/editprofilescreen.dart';
import 'package:rideal_driver/presentation/widgets/contact_info_section.dart';
import 'package:rideal_driver/presentation/widgets/social_media_links.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import 'screens/delete_account_screen.dart';
import 'widgets/app_logo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _itemAnimationControllers;
  late List<Animation<double>> _itemAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late final ProfileController controller;
  
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ProfileController>()) {
      controller = Get.find<ProfileController>();
    } else {
      controller = Get.put(ProfileController());
    }
    
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create individual controllers for each contact item
    _itemAnimationControllers = List.generate(8, (index) =>
        AnimationController(
          duration: const Duration(milliseconds: 600),
          vsync: this,
        )
    );

    // Create fade animations for each item
    _itemAnimations = _itemAnimationControllers.map((controller) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        )
    ).toList();

    // Create slide animations for each item
    _slideAnimations = _itemAnimationControllers.map((controller) =>
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        )
    ).toList();

    // Start animations with staggered delays
    _startStaggeredAnimations();
  }

  // 🔥 NEW: Refresh profile when screen becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          print('🔄 Profile screen focused - refreshing data');
          controller.refreshProfile();
        }
      });
    }
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _itemAnimationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 150)), () {
        if (mounted) {
          _itemAnimationControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildWalletCard(BuildContext context) {
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[100]!, Colors.blue[100]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.purple[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    '₹${controller.walletBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace:
             FlexibleSpaceBar(
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const AppLogo(
                          width: 120,
                          height: 120,
                          margin: EdgeInsets.only(bottom: 20),
                        ),
                        // 🔥 FIXED Profile Section with proper image & verification handling
                        Row(
                          children: [
                        Obx(() {
                              final profilePic = controller.profilePicUrl.value;
                              print('📸 ProfileScreen image: $profilePic');
                              
                              return CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: profilePic.isNotEmpty
                                      ? Image.network(
                                          profilePic,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('❌ ProfileScreen image error: $error');
                                            return Icon(Icons.person, size: 35, color: Colors.orange[600]);
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                          },
                                        )
                                      : Icon(Icons.person, size: 35, color: Colors.orange[600]),
                                ),
                              );
                            }),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "RiDeal Driver",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  Obx(() => Text(
                                    controller.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Obx(() => Text(
                                        controller.phone,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      )),
                                      const SizedBox(width: 8),
                                      // 🔥 FIXED Verification badge
                                      Obx(() {
                                        final isVerified = controller.isVerified;
                                        final status = controller.verificationStatus;
                                        
                                        print('🔍 Verification badge: $isVerified - $status');
                                        
                                        return Container(
                                          key: ValueKey('verify_$isVerified'),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isVerified
                                                ? Colors.green[100]
                                                : Colors.orange[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isVerified ? Icons.verified : Icons.pending,
                                                size: 12,
                                                color: isVerified
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                status,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isVerified
                                                      ? Colors.green[700]
                                                      : Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Obx(() => Text(
                                    'Member since ${controller.memberSince}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  )),
                                  const SizedBox(height: 10),
                                  Obx(() => Text(
                                    controller.ridealid.isNotEmpty
                                        ? 'RiDeal ID: ${controller.ridealid}'
                                        : '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            // 🔥 FIXED Edit button with refresh on return
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen()),
                                );
                                if (mounted) {
                                  await controller.refreshProfile();
                                  print('🔄 Profile refreshed after edit');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // _buildVehicleInfoCard(controller, context),
                  // const SizedBox(height: 16),
                  _buildWalletCard(context),
                  const SizedBox(height: 16),
                  _buildMenuOptionsCard(context),
                  const SocialMediaLinksEnhanced(),
                  const ContactInfoSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard(ProfileController controller, BuildContext context) {
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
                    Icons.directions_car,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() => _buildEnhancedVehicleInfoRow(
              icon: Icons.directions_car_filled,
              iconColor: Colors.blue[700]!,
              label: 'Vehicle Name',
              value: controller.carModel.value.isNotEmpty
                  ? controller.carModel.value
                  : 'Not Set',
              backgroundColor: Colors.blue[50]!,
            )),
            const SizedBox(height: 16),
            Obx(() => _buildEnhancedVehicleInfoRow(
              icon: Icons.palette_outlined,
              iconColor: Colors.purple[700]!,
              label: 'Vehicle Color/Type',
              value: controller.carColor.value.isNotEmpty
                  ? controller.carColor.value
                  : 'Not Set',
              backgroundColor: Colors.purple[50]!,
            )),
            const SizedBox(height: 16),
            Obx(() => _buildEnhancedVehicleInfoRow(
              icon: Icons.confirmation_number_outlined,
              iconColor: Colors.orange[700]!,
              label: 'Vehicle Number',
              value: controller.carNumber.value.isNotEmpty
                  ? controller.carNumber.value
                  : 'Not Set',
              backgroundColor: Colors.orange[50]!,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedVehicleInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: iconColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.info_outline,
              color: iconColor.withValues(alpha: 0.5),
              size: 12,
            ),
          ),
        ],
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
              icon: Icons.chat_bubble_outline,
              title: 'In-App Chat',
              subtitle: 'Message support',
              color: Colors.green,
              onTap: () => Get.toNamed('/chat'),
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out of account',
              color: Colors.red,
              onTap: () => _showLogoutDialog(context),
            ),
            _buildDivider(),
            _buildMenuOption(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: Colors.red[800]!,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeleteAccountScreen())),
            ),
          ],
        ),
      ),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
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