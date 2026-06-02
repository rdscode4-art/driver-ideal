
import 'package:flutter/material.dart';
import 'package:rideal_driver/presentation/about_screen.dart';
import 'package:rideal_driver/presentation/chat_screen.dart';
import 'package:rideal_driver/presentation/privacy_policy_screen.dart';
import 'package:rideal_driver/presentation/refundpolicyscreen.dart';
import 'package:rideal_driver/presentation/terms_of_service_screen.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';

class CustomDrawer extends StatefulWidget {
  
  const CustomDrawer({
    super.key,
    
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
  
  
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool isLoading = true;

   @override
   void initState() {
     super.initState();
      
   }

  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Premium Header with Gradient
            GetBuilder<ProfileController>(
              init: Get.find<ProfileController>(),
              builder: (controller) {
                return Obx(() {
                  final profile = controller.driverProfile.value;
                  final profilePic = controller.profilePicUrl.value;
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[100]!, width: 1),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Profile Avatar
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF10B981), width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.grey[100],
                                backgroundImage: profilePic.isNotEmpty
                                    ? NetworkImage(profilePic)
                                    : null,
                                child: profilePic.isEmpty
                                    ? const Icon(Icons.person, size: 40, color: Color(0xFF10B981))
                                    : null,
                              ),
                            ),
                            // Close button
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          profile?.name ?? 'Driver Name',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'ID: ${controller.ridealid.isNotEmpty ? controller.ridealid : "---"}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 12,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.phone_android_rounded, color: Colors.grey[400], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              profile?.phone ?? "---",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                });
              },
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: "Help And Support",
                    color: Colors.blue,
                    onTap: () => _navigateTo(context, ChatScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: "Refund Policy",
                    color: Colors.orange,
                    onTap: () => _navigateTo(context, const RefundPolicyPage()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.gavel_rounded,
                    title: "Terms & Conditions",
                    color: Colors.teal,
                    onTap: () => _navigateTo(context, const TermsOfServiceScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: "About Us",
                    color: Colors.indigo,
                    onTap: () => _navigateTo(context, AboutScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.security_rounded,
                    title: "Privacy Policy",
                    color: Colors.deepPurple,
                    onTap: () => _navigateTo(context, const PrivacyPolicyScreen()),
                  ),
                ],
              ),
            ),

            // Footer / Logout
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      // Handle Logout
                      _showLogoutDialog(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Logout Account",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "App Version 1.0.0",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
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

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Find AuthController and perform logout
              try {
                if (Get.isRegistered<AuthController>()) {
                  final authController = Get.find<AuthController>();
                  await authController.logout();
                } else {
                  // Fallback if not registered
                  Get.offAllNamed('/login');
                }
              } catch (e) {
                print('Error during drawer logout: $e');
                Get.offAllNamed('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}