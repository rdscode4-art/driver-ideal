import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/main.dart';
import '../controllers/auth_controller.dart';
import 'widgets/app_logo.dart';
import 'package:rideal_driver/core/utils/app_snackbar.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final List<TextEditingController> otpControllers;
  late final List<FocusNode> focusNodes;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    otpControllers = List.generate(6, (index) => TextEditingController());
    focusNodes = List.generate(6, (index) => FocusNode());
    authController = Get.find();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final isTablet = screenWidth >= 600;

    // Calculate OTP box dimensions based on screen size
    double otpBoxSize = isSmallScreen ? 45 : isMediumScreen ? 55 : isTablet ? 70 : 60;
    double otpBoxSpacing = isSmallScreen ? 6 : isMediumScreen ? 8 : 12;
    double horizontalPadding = isSmallScreen ? 16 : isMediumScreen ? 24 : 32;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.white, Colors.orange[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 12,
                  shadowColor: Colors.green.withOpacity(0.3),
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isSmallScreen ? 24 : 40
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header - Logo
                        AppLogo(
                          width: isSmallScreen ? 80 : isMediumScreen ? 100 : 120,
                          height: isSmallScreen ? 80 : isMediumScreen ? 100 : 120,
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 32),

                        // Title
                        Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : isMediumScreen ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Obx(() => Text(
                          'Enter the 6-digit code sent to\n${authController.tempPhone.value}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        )),
                        SizedBox(height: isSmallScreen ? 24 : 40),

                        // 6-Digit OTP Input Fields
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double availableWidth = constraints.maxWidth;
                            double totalSpacing = otpBoxSpacing * 5;
                            double remainingWidth = availableWidth - totalSpacing;
                            double calculatedBoxSize = (remainingWidth / 6).clamp(40.0, 80.0);
                            double finalBoxSize = calculatedBoxSize < otpBoxSize ? calculatedBoxSize : otpBoxSize;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) {
                                return Container(
                                  width: finalBoxSize,
                                  height: finalBoxSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: focusNodes[index].hasFocus
                                          ? Colors.green[500]!
                                          : Colors.grey[300]!,
                                      width: focusNodes[index].hasFocus ? 2.5 : 2,
                                    ),
                                    color: focusNodes[index].hasFocus
                                        ? Colors.green[50]
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: focusNodes[index].hasFocus
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                        blurRadius: 8,
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
                                    style: TextStyle(
                                      fontSize: finalBoxSize * 0.4,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
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
                                      scaffoldMessengerKey.currentState?.clearSnackBars();
                                    },
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 40),

                        // Verify Button
                        Obx(() => Container(
                          width: double.infinity,
                          height: isSmallScreen ? 48 : 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: authController.isLoading.value
                                  ? [Colors.grey[400]!, Colors.grey[300]!]
                                  : [Colors.green[600]!, Colors.green[400]!],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (authController.isLoading.value ? Colors.grey : Colors.green).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: authController.isLoading.value ? null : () async {
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
                              await Future.delayed(const Duration(milliseconds: 150));

                              print('🔐 UI: Verifying OTP: $otp');

                              // Call verifyOTP and handle the response
                              bool success = await authController.verifyOTP(otp);
                              
                              print('🔐 UI: Verification result: $success');
                              
                              // If verification failed, clear OTP fields after showing snackbar
                              if (!success) {
                                print('❌ UI: OTP verification failed - clearing fields');
                                
                                // ✅ Wait longer to ensure snackbar is visible
                                await Future.delayed(const Duration(milliseconds: 1500));
                                
                                // Clear fields without auto-focusing
                                if (mounted) {
                                  _clearOtpFields(focusFirst: false);
                                  
                                  // ✅ Focus after a longer delay to ensure user sees the error
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (mounted) {
                                      focusNodes[0].requestFocus();
                                    }
                                  });
                                }
                              } else {
                                print('✅ UI: OTP verification successful');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: authController.isLoading.value
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Verifying...',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        )),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Resend OTP Button
                        Obx(() => TextButton(
                          onPressed: authController.isLoading.value ? null : () async {
                            // Unfocus keyboard before resending
                            FocusScope.of(context).unfocus();
                            // Clear OTP fields before resending
                            _clearOtpFields(focusFirst: false);
                            await authController.resendOTP();
                          },
                          child: Text(
                            'Resend OTP',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: authController.isLoading.value ? Colors.grey[400] : Colors.green[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )),
                        SizedBox(height: isSmallScreen ? 8 : 16),

                        // Back to Login
                        Obx(() => TextButton(
                          onPressed: authController.isLoading.value ? null : () {
                            Get.back();
                          },
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: authController.isLoading.value ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}