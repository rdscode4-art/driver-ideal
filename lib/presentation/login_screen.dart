import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
import '../controllers/non_vehicle_auth_controller.dart';
import '../routes/app_pages.dart';
import '../core/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Comprehensive phone number validation
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }

    // Remove any spaces, dashes, or +91 prefix
    String cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');

    // Remove country code if present
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }

    // Check if it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Mobile number must contain only digits';
    }

    // Check if it's exactly 10 digits
    if (cleaned.length != 10) {
      return 'Mobile number must be 10 digits';
    }

    // Check if it starts with valid digits (6-9)
    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final AuthController authController = Get.find<AuthController>();
    final NonVehicleAuthController nonVehicleAuthController =
        Get.find<NonVehicleAuthController>();

    final args = Get.arguments as Map<String, dynamic>?;
    final driverType = args?['driverType'] ?? 'vehicle';
    final isVehicle = driverType == 'vehicle';
    final RxBool isLoading = isVehicle
        ? authController.isLoading
        : nonVehicleAuthController.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          !isVehicle ? 'Login Without Vehicle' : '',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20.r,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                'RiDeal',
                                style: GoogleFonts.inter(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Welcome Back!',
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      !isVehicle
                          ? 'Login to continue driving'
                          : 'Sign in to continue driving',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),

                    // Enhanced Phone Number Field
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        prefixIcon: Icon(
                          Icons.phone_rounded,
                          color: AppTheme.primary,
                          size: 20.w,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppTheme.primary),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16.h,
                          horizontal: 16.w,
                        ),
                      ),
                      validator: _validatePhoneNumber,
                      maxLength: 10,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    if (isVehicle)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enter your registered mobile number',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: phoneController,
                            builder: (context, value, child) {
                              return Text(
                                '${value.text.length}/10',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    if (!isVehicle)
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primary,
                              size: 18.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'We will send you an OTP to verify',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 30.h),

                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: isLoading.value
                              ? null
                              : () async {
                                  // Validate form first
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  // Clean phone number (remove any formatting)
                                  String cleanPhone = phoneController.text
                                      .replaceAll(RegExp(r'[\s\-\+]'), '');

                                  // Remove country code if present
                                  if (cleanPhone.startsWith('91') &&
                                      cleanPhone.length > 10) {
                                    cleanPhone = cleanPhone.substring(2);
                                  }

                                  print(
                                    '🔐 Attempting login with phone: $cleanPhone for $driverType',
                                  );

                                  bool success = false;
                                  if (isVehicle) {
                                    success = await authController.login(
                                      cleanPhone,
                                    );
                                  } else {
                                    success = await nonVehicleAuthController
                                        .requestLoginOtp(cleanPhone);
                                  }

                                  if (success) {
                                    // Navigate to unified OTP verification screen
                                    Get.toNamed(
                                      Routes.OTP_VERIFICATION,
                                      arguments: {
                                        'phone': cleanPhone,
                                        'isLoginFlow': true,
                                        'isLogin': true, // for compatibility
                                        'driverType': driverType,
                                      },
                                    );
                                  }
                                },
                          child: isLoading.value
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Sending OTP...',
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  isVehicle ? 'Login with Vehicle' : 'Login',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (isVehicle) {
                              Get.toNamed(Routes.SIGNUP);
                            } else {
                              Get.toNamed(Routes.NON_VEHICLE_REGISTER);
                            }
                          },
                          child: Text(
                            isVehicle ? 'Register driver with vehicle' : 'Register',
                            style: GoogleFonts.inter(
                              color: AppTheme.primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
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
    );
  }
}
