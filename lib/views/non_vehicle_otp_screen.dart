import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/non_vehicle_auth_controller.dart';
import '../core/utils/app_snackbar.dart';

class NonVehicleOtpScreen extends StatefulWidget {
  const NonVehicleOtpScreen({super.key});

  @override
  State<NonVehicleOtpScreen> createState() => _NonVehicleOtpScreenState();
}

class _NonVehicleOtpScreenState extends State<NonVehicleOtpScreen> {
  final List<TextEditingController> otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final NonVehicleAuthController authController = Get.put(NonVehicleAuthController());

  String? phone;
  bool? isLogin;

  @override
  void initState() {
    super.initState();
    // Get arguments
    final args = Get.arguments as Map<String, dynamic>?;
    phone = args?['phone'];
    isLogin = args?['isLogin'] ?? false;
  }

  String getOtp() {
    return otpControllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[50]!, Colors.white, Colors.green[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 12,
                      shadowColor: Colors.orange.withOpacity(0.3),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.message,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              'Enter OTP',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                                letterSpacing: 1.2,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'We sent a code to ${phone ?? "your phone"}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // OTP Input Fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) {
                                return SizedBox(
                                  width: 45,
                                  height: 55,
                                  child: TextFormField(
                                    controller: otpControllers[index],
                                    focusNode: focusNodes[index],
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.orange[300]!, width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.orange[600]!, width: 2.5),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                                    },
                                  ),
                                );
                              }),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Verify Button
                            Obx(() => Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange[600]!, Colors.orange[400]!],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: authController.isLoading.value
                                    ? null
                                    : () async {
                                        String otp = getOtp();
                                        
                                        if (otp.length != 6) {
                                            showErrorSnackBar('Please enter complete 6-digit OTP');
                                          return;
                                        }

                                        if (phone == null) {
                                            showErrorSnackBar('Phone number not found');
                                          return;
                                        }

                                        // ⭐ UPDATED: Just verify OTP, controller will handle navigation
                                        await authController.verifyOtp(
                                          phone!,
                                          otp,
                                          isLogin ?? false,
                                        );
                                        
                                        // No manual navigation needed - controller handles it
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: authController.isLoading.value
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Verify OTP',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                              ),
                            )),
                            
                            const SizedBox(height: 20),
                            
                            // Resend OTP
                            TextButton(
                              onPressed: () {
                                if (isLogin == true && phone != null) {
                                  authController.requestLoginOtp(phone!);
                                } else {
                                    showInfoSnackBar('Go back to request a new OTP');
                                }
                              },
                              child: Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}