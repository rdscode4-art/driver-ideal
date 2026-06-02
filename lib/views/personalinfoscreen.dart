import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../controllers/non_vehicle_auth_controller.dart';
import '../core/utils/app_snackbar.dart';

class NonVehiclePersonalInfoScreen extends StatefulWidget {
  const NonVehiclePersonalInfoScreen({super.key});

  @override
  State<NonVehiclePersonalInfoScreen> createState() => _NonVehiclePersonalInfoScreenState();
}

class _NonVehiclePersonalInfoScreenState extends State<NonVehiclePersonalInfoScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  final NonVehicleAuthController authController = Get.put(NonVehicleAuthController());

  String selectedGender = 'male';
  DateTime? selectedDOB;
  int? calculatedAge;
  File? profileImage;
  
  final ImagePicker _picker = ImagePicker();

  // Calculate age from DOB
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // Show Date Picker
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1924, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange[600]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[600],
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        selectedDOB = picked;
        calculatedAge = _calculateAge(picked);
      });
    }
  }

  // Validate DOB and Age
  String? _validateDOB() {
    if (selectedDOB == null) {
      return 'Please select your date of birth';
    }
    
    int age = _calculateAge(selectedDOB!);
    
    if (age < 18) {
      return 'You must be at least 18 years old to register';
    }
    
    if (age > 100) {
      return 'Please select a valid date of birth';
    }
    
    return null;
  }

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

  // Convert image to JPEG format
  Future<File> _convertToJpeg(File imageFile, String prefix) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(tempDir.path, '${prefix}_$timestamp.jpg');
      final newFile = File(newPath);
      await newFile.writeAsBytes(bytes);
      
      print('✅ Image converted: ${imageFile.path} -> $newPath');
      return newFile;
    } catch (e) {
      print('❌ Image conversion error: $e');
      return imageFile;
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        File originalFile = File(pickedFile.path);
        File convertedFile = await _convertToJpeg(originalFile, 'profile_image');
        
        setState(() {
          profileImage = convertedFile;
        });
        
        print('✅ Profile image picked: ${convertedFile.path}');
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Upload a clear photo of yourself',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange[300]!, width: 3),
              color: Colors.orange[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: profileImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, 
                        size: 50, 
                        color: Colors.orange[600]
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipOval(
                        child: Image.file(
                          profileImage!,
                          fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check, 
                            color: Colors.white, 
                            size: 20
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Without Vehicle',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Step 1 of 2',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 8,
                      shadowColor: Colors.orange.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Image Section
                              _buildProfileImageSection(),
                              
                              const SizedBox(height: 32),
                              
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Name Field
                              TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'Enter your full name',
                                  prefixIcon: Icon(Icons.person, color: Colors.orange[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: _validateName,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Phone Field
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'Enter 10 digit mobile number',
                                  prefixText: '+91 ',
                                  prefixIcon: Icon(Icons.phone, color: Colors.orange[600]),
                                  helperText: 'Enter your mobile number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: _validatePhoneNumber,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Date of Birth Field
                              GestureDetector(
                                onTap: () => _selectDateOfBirth(context),
                                child: AbsorbPointer(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Date of Birth',
                                          hintText: 'Select your date of birth',
                                          prefixIcon: Icon(Icons.calendar_today, color: Colors.orange[600]),
                                          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          errorText: _validateDOB(),
                                        ),
                                        controller: TextEditingController(
                                          text: selectedDOB != null
                                              ? DateFormat('dd MMM yyyy').format(selectedDOB!)
                                              : '',
                                        ),
                                      ),
                                      if (calculatedAge != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: calculatedAge! >= 18 
                                                ? Colors.green[50] 
                                                : Colors.red[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: calculatedAge! >= 18 
                                                  ? Colors.green[300]! 
                                                  : Colors.red[300]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                calculatedAge! >= 18 
                                                    ? Icons.check_circle 
                                                    : Icons.error,
                                                color: calculatedAge! >= 18 
                                                    ? Colors.green[700] 
                                                    : Colors.red[700],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Your age: $calculatedAge years',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: calculatedAge! >= 18 
                                                      ? Colors.green[700] 
                                                      : Colors.red[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Gender Selection
                              Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Male'),
                                      value: 'male',
                                      groupValue: selectedGender,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedGender = value!;
                                        });
                                      },
                                      activeColor: Colors.orange[600],
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Female'),
                                      value: 'female',
                                      groupValue: selectedGender,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedGender = value!;
                                        });
                                      },
                                      activeColor: Colors.orange[600],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Continue Button
                              Obx(() => Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: authController.isLoading.value
                                        ? [Colors.grey[400]!, Colors.grey[300]!]
                                        : [Colors.orange[600]!, Colors.orange[400]!],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (authController.isLoading.value ? Colors.grey : Colors.orange).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authController.isLoading.value
                                      ? null
                                      : () async {
                                          if (_validatePersonalInfo()) {
                                            String cleanedPhone = phoneController.text.replaceAll(RegExp(r'[\s\-\+]'), '');
                                            if (cleanedPhone.startsWith('91') && cleanedPhone.length > 10) {
                                              cleanedPhone = cleanedPhone.substring(2);
                                            }
                                            
                                            // Check if phone already registered
                                            bool isRegistered = await authController.checkPhoneRegistration(cleanedPhone);
                                            
                                            if (isRegistered) {
                                              // Phone already registered - send OTP for login
                                              bool otpSent = await authController.requestLoginOtp(cleanedPhone);
                                              if (otpSent) {
                                                Get.toNamed(
                                                  '/non-vehicle-otp',
                                                  arguments: {
                                                    'phone': cleanedPhone,
                                                    'isLogin': true,
                                                  },
                                                );
                                              }
                                            } else {
                                              // New user - go to documents screen
                                              Get.toNamed(
                                                '/non-vehicle-documents',
                                                arguments: {
                                                  'name': nameController.text.trim(),
                                                  'phone': cleanedPhone,
                                                  'age': calculatedAge.toString(),
                                                  'gender': selectedGender,
                                                  'profileImage': profileImage,
                                                },
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    disabledBackgroundColor: Colors.transparent,
                                  ),
                                  child: authController.isLoading.value
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward, color: Colors.white),
                                          ],
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
            ],
          ),
        ),
      ),
    );
  }

  bool _validatePersonalInfo() {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    
    // Validate DOB
    if (selectedDOB == null) {
      showErrorSnackBar('Please select your date of birth');
      return false;
    }
    
    // Validate age
    if (calculatedAge == null || calculatedAge! < 18) {
      showErrorSnackBar('You must be at least 18 years old to register');
      return false;
    }
    
    // Check profile image
    if (profileImage == null) {
      showErrorSnackBar('Please upload your profile photo');
      return false;
    }
    
    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}