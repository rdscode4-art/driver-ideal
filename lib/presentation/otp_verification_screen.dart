import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal_driver/main.dart';
import '../controllers/auth_controller.dart';
import '../controllers/non_vehicle_auth_controller.dart';
import 'widgets/app_logo.dart';
import 'package:rideal_driver/core/utils/app_snackbar.dart';
import '../core/app_theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final List<TextEditingController> otpControllers;
  late final List<FocusNode> focusNodes;
  late final AuthController authController;
  late final NonVehicleAuthController nonVehicleAuthController;

  @override
  void initState() {
    super.initState();
    otpControllers = List.generate(6, (index) => TextEditingController());
    focusNodes = List.generate(6, (index) => FocusNode());
    authController = Get.find<AuthController>();
    nonVehicleAuthController = Get.find<NonVehicleAuthController>();
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Method to clear all OTP fields
  void _clearOtpFields({bool focusFirst = true}) {
    for (var controller in otpControllers) {
      controller.clear();
    }
    // Optionally focus on first field
    if (focusFirst && focusNodes.isNotEmpty && mounted) {
      // Add delay before focusing to avoid keyboard interfering with snackbar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          focusNodes[0].requestFocus();
        }
      });
    }
  }

  // Method to get current OTP value
  String _getOtpValue() {
    return otpControllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final driverType = args['driverType'] ?? 'vehicle';
    final isVehicle = driverType == 'vehicle';
    final isLogin = args['isLogin'] ?? true;
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
          'Verify OTP',
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20.h),

                  // Subtitle
                  Obx(
                    () => Text(
                      'Enter the 6-digit code sent to\n${isVehicle ? authController.tempPhone.value : (args['phone'] ?? '')}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // 6-Digit OTP Input Fields
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double availableWidth = constraints.maxWidth;
                      double totalSpacing = 8.w * 5;
                      double remainingWidth = availableWidth - totalSpacing;
                      double finalBoxSize = (remainingWidth / 6).clamp(
                        40.w,
                        60.w,
                      );

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Container(
                            width: finalBoxSize,
                            height: finalBoxSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: focusNodes[index].hasFocus
                                    ? AppTheme.primary
                                    : Colors.grey[300]!,
                                width: focusNodes[index].hasFocus ? 2.5 : 2,
                              ),
                              color: focusNodes[index].hasFocus
                                  ? AppTheme.primary.withOpacity(0.05)
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: focusNodes[index].hasFocus
                                      ? AppTheme.primary.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 8.r,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: GoogleFonts.inter(
                                fontSize: finalBoxSize * 0.4,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  focusNodes[index - 1].requestFocus();
                                }

                                // Auto-verify when all 6 digits are entered
                                if (index == 5 && value.isNotEmpty) {
                                  String otp = _getOtpValue();
                                  if (otp.length == 6) {
                                    FocusScope.of(context).unfocus();
                                  }
                                }
                              },
                              onTap: () {
                                // Clear any previous snackbars when user taps
                                scaffoldMessengerKey.currentState
                                    ?.clearSnackBars();
                              },
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  SizedBox(height: 40.h),

                  // Verify Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                String otp = _getOtpValue();

                                // Validation: Check if all 6 digits are entered
                                if (otp.length != 6) {
                                  showAppSnackBar(
                                    'Invalid OTP',
                                    'Please enter all 6 digits',
                                  );
                                  return;
                                }

                                // ✅ FIRST: Unfocus keyboard to ensure snackbar visibility
                                FocusScope.of(context).unfocus();

                                // ✅ Add small delay to ensure keyboard is fully dismissed
                                await Future.delayed(
                                  const Duration(milliseconds: 150),
                                );

                                print(
                                  '🔐 UI: Verifying OTP: $otp for $driverType',
                                );

                                bool success = false;
                                if (isVehicle) {
                                  success = await authController.verifyOTP(otp);
                                } else {
                                  final phone = args['phone'] ?? '';
                                  success = await nonVehicleAuthController
                                      .verifyOtp(phone, otp, isLogin);
                                }

                                print('🔐 UI: Verification result: $success');

                                // If verification failed, clear OTP fields after showing snackbar
                                if (!success) {
                                  print(
                                    '❌ UI: OTP verification failed - clearing fields',
                                  );

                                  // ✅ Wait longer to ensure snackbar is visible
                                  await Future.delayed(
                                    const Duration(milliseconds: 1500),
                                  );

                                  // Clear fields without auto-focusing
                                  if (mounted) {
                                    _clearOtpFields(focusFirst: false);

                                    // ✅ Focus after a longer delay to ensure user sees the error
                                    Future.delayed(
                                      const Duration(milliseconds: 500),
                                      () {
                                        if (mounted) {
                                          focusNodes[0].requestFocus();
                                        }
                                      },
                                    );
                                  }
                                } else {
                                  print('✅ UI: OTP verification successful');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading.value
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20.w,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Verifying...',
                                    style: GoogleFonts.inter(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Verify OTP',
                                style: GoogleFonts.inter(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Resend OTP Button
                  Obx(
                    () => TextButton(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              // Unfocus keyboard before resending
                              FocusScope.of(context).unfocus();
                              // Clear OTP fields before resending
                              _clearOtpFields(focusFirst: false);

                              if (isVehicle) {
                                await authController.resendOTP();
                              } else {
                                final phone = args['phone'];
                                if (isLogin && phone != null) {
                                  await nonVehicleAuthController
                                      .requestLoginOtp(phone);
                                } else {
                                  showAppSnackBar(
                                    'Info',
                                    'Go back to request a new OTP',
                                  );
                                }
                              }
                            },
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: isLoading.value
                              ? Colors.grey[400]
                              : AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Back to Login
                  Obx(
                    () => TextButton(
                      onPressed: isLoading.value
                          ? null
                          : () {
                              Get.back();
                            },
                      child: Text(
                        'Back to Login',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: isLoading.value
                              ? Colors.grey[400]
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
