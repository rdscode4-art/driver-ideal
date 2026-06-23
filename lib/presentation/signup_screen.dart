import 'dart:io';
import 'package:rideal_driver/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/utils/app_snackbar.dart';
import '../controllers/auth_controller.dart';
import '../core/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  File? _profileImage;
  final AuthController authController = Get.find();

  // Validate phone number
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }

    String cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');

    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Mobile number must contain only digits';
    }

    if (cleaned.length != 10) {
      return 'Mobile number must be 10 digits';
    }

    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }

    return null;
  }

  // Validate name
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters';
    }
    return null;
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      showErrorSnackBar(
        'Failed to pick image: ${e.toString()}',
        title: 'Error',
      );
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.green[600]),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green[600]),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[600]),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Register with Vehicle',
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
                    SizedBox(height: 20.h),

                    // Profile Image Picker
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          Container(
                            width: 120.w,
                            height: 120.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10.r,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 58.r,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60.w,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _profileImage != null
                          ? 'Tap to change photo'
                          : 'Tap to add profile photo (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Name Field with Validation
                    TextFormField(
                      controller: nameController,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(
                          Icons.person_rounded,
                          color: AppTheme.primary,
                          size: 20.w,
                        ),
                      ),
                      validator: _validateName,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z\s]'),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Phone Number Field with Validation
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter 10 digit mobile number',
                        prefixText: '+91 ',
                        prefixStyle: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        prefixIcon: Icon(
                          Icons.phone_rounded,
                          color: AppTheme.primary,
                          size: 20.w,
                        ),
                        helperText: 'Enter your mobile number',
                      ),
                      validator: _validatePhoneNumber,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Referral Code Field (Optional)
                    TextFormField(
                      controller: referralCodeController,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Referral Code (Optional)',
                        hintText: 'Enter referral code',
                        prefixIcon: Icon(
                          Icons.card_giftcard_rounded,
                          color: AppTheme.primary,
                          size: 20.w,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    SizedBox(height: 40.h),

                    // Create Account Button
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: authController.isLoading.value
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  String cleanedPhone = phoneController.text
                                      .replaceAll(RegExp(r'[\s\-\+]'), '');
                                  if (cleanedPhone.startsWith('91') &&
                                      cleanedPhone.length > 10) {
                                    cleanedPhone = cleanedPhone.substring(2);
                                  }

                                  bool success = await authController.register(
                                    cleanedPhone,
                                    nameController.text.trim(),
                                    referralCode:
                                        referralCodeController.text
                                            .trim()
                                            .isNotEmpty
                                        ? referralCodeController.text.trim()
                                        : null,
                                    profileImage: _profileImage,
                                  );

                                  if (success) {
                                    Get.toNamed(
                                      Routes.OTP_VERIFICATION,
                                      arguments: {
                                        'phone': cleanedPhone,
                                        'isLoginFlow': false,
                                      },
                                    );
                                  }
                                },
                          child: authController.isLoading.value
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
                                      'Creating Account...',
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Create Account',
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 15.sp,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            try {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Get.offAllNamed(Routes.LOGIN);
                              }
                            } catch (e) {
                              Get.offAllNamed(Routes.LOGIN);
                            }
                          },
                          child: Text(
                            'Sign in',
                            style: GoogleFonts.inter(
                              color: AppTheme.primary,
                              fontSize: 15.sp,
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
    );
  }
}
