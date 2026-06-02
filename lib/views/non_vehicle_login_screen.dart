import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/non_vehicle_auth_controller.dart';

class NonVehicleLoginScreen extends StatelessWidget {
  const NonVehicleLoginScreen({super.key});

  // Validation function
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any whitespace
    value = value.trim();
    
    // Check if contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Phone number must contain only digits';
    }
    
    // Check length
    if (value.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    
    // Check if starts with valid Indian mobile prefix (6-9)
    if (!RegExp(r'^[6-9]').hasMatch(value)) {
      return 'Phone number must start with 6, 7, 8, or 9';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final NonVehicleAuthController authController = Get.put(NonVehicleAuthController());
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
                      'Login Without Vehicle',
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
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 12,
                        shadowColor: Colors.orange.withOpacity(0.3),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(60),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset("assets/images/logo.png"),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Login to continue driving',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                
                                // Phone Number Field with Validation
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  validator: _validatePhoneNumber,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: 'Enter 10-digit mobile number',
                                    prefixIcon: Icon(Icons.phone, color: Colors.orange[600]),
                                    prefixText: '+91 ',
                                    prefixStyle: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Info text
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange[200]!, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'We will send you an OTP to verify',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 40),
                                
                                // Login Button
                                Obx(() => Container(
                                  width: double.infinity,
                                  height: 56,
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
                                            // Validate form
                                            if (!formKey.currentState!.validate()) {
                                              return;
                                            }

                                            final phone = phoneController.text.trim();
                                            
                                            // Request OTP
                                            bool success = await authController.requestLoginOtp(phone);
                                            
                                            if (success) {
                                              // Navigate to OTP verification
                                              Get.toNamed(
                                                '/non-vehicle-otp',
                                                arguments: {
                                                  'phone': phone,
                                                  'isLogin': true,
                                                },
                                              );
                                            }
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
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                  ),
                                )),
                                
                                const SizedBox(height: 24),
                                
                                // Navigate to Register
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 15,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context); // Go back to option screen
                                      },
                                      child: Text(
                                        'Register',
                                        style: TextStyle(
                                          color: Colors.orange[600],
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}