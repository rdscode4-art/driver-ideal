import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal_driver/core/app_theme.dart';
import 'package:rideal_driver/routes/app_pages.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              
              // Top Icon
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.handshake_rounded,
                  color: AppTheme.primary,
                  size: 32.w,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Header
              Text(
                'Partner with RiDeal',
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'How would you like to drive with us today? Choose your role to continue.',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              
              SizedBox(height: 40.h),
              
              // Option 1: Driver with Vehicle
              _buildRoleCard(
                title: 'Driver with Vehicle',
                description: 'I have my own car, auto, or bike and want to drive passengers.',
                icon: Icons.directions_car_rounded,
                iconColor: AppTheme.primary,
                iconBgColor: AppTheme.primary.withOpacity(0.15),
                onTap: () {
                  Get.toNamed(Routes.LOGIN, arguments: {'driverType': 'vehicle'});
                },
              ),
              
              SizedBox(height: 20.h),
              
              // Option 2: Driver without Vehicle
              _buildRoleCard(
                title: 'Driver without Vehicle',
                description: "I want to provide driving services using the customer's vehicle.",
                icon: Icons.person_pin_circle_rounded,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  Get.toNamed(Routes.LOGIN, arguments: {'driverType': 'non-vehicle'});
                },
              ),
              
              const Spacer(),
              
              // Bottom Text
              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32.w,
                color: iconColor,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }
}
