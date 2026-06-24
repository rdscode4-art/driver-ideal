import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal_driver/presentation/about_screen.dart';
import 'package:rideal_driver/presentation/chat_screen.dart';
import 'package:rideal_driver/presentation/privacy_policy_screen.dart';
import 'package:rideal_driver/presentation/refundpolicyscreen.dart';
import 'package:rideal_driver/presentation/terms_of_service_screen.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/presentation/support_screen.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import '../core/app_theme.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32.r),
            bottomRight: Radius.circular(32.r),
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
                    padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 30.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[100]!, width: 1),
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(32.r),
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
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 38.r,
                                backgroundColor: Colors.grey[100],
                                backgroundImage: profilePic.isNotEmpty
                                    ? NetworkImage(profilePic)
                                    : null,
                                child: profilePic.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 40.w,
                                        color: AppTheme.primary,
                                      )
                                    : null,
                              ),
                            ),
                            // Close button
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey[400],
                                size: 24.w,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          profile?.name ?? 'Driver Name',
                          style: GoogleFonts.inter(
                            color: Colors.grey[900],
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 16.w),
                            SizedBox(width: 4.w),
                            Text(
                              'ID: ${controller.ridealid.isNotEmpty ? controller.ridealid : "---"}',
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              width: 1,
                              height: 12.h,
                              color: Colors.grey[300],
                            ),
                            SizedBox(width: 12.w),
                            Icon(
                              Icons.phone_android_rounded,
                              color: Colors.grey[400],
                              size: 14.w,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              profile?.phone ?? "---",
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontSize: 13.sp,
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
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
                children: [
                  _buildDrawerItem(
                    icon: Icons.support_agent_rounded,
                    title: "Help & Support",
                    color: const Color(0xFF0F9D58),
                    onTap: () => _navigateTo(context, const SupportScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: "Refund Policy",
                    color: const Color(0xFF0F9D58),
                    onTap: () => _navigateTo(context, const RefundPolicyPage()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.gavel_rounded,
                    title: "Terms & Conditions",
                    color: const Color(0xFF0F9D58),
                    onTap: () =>
                        _navigateTo(context, const TermsOfServiceScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: "About Us",
                    color: const Color(0xFF0F9D58),
                    onTap: () => _navigateTo(context, AboutScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.security_rounded,
                    title: "Privacy Policy",
                    color: const Color(0xFF0F9D58),
                    onTap: () =>
                        _navigateTo(context, const PrivacyPolicyScreen()),
                  ),
                ],
              ),
            ),

            // Footer / Logout
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  const Divider(height: 1),
                  SizedBox(height: 20.h),
                  InkWell(
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.red[600]!, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 20.w,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            "Logout Account",
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "App Version 1.0.0",
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // lightGreen
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: const Color(0xFF0A6B3C), size: 22.w), // darkGreen
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[400],
          size: 20.w,
        ),
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
