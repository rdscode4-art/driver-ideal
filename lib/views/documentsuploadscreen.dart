import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import '../controllers/non_vehicle_auth_controller.dart';
import '../routes/app_pages.dart';
import '../core/utils/app_snackbar.dart';

class NonVehicleDocumentsScreen extends StatefulWidget {
  const NonVehicleDocumentsScreen({super.key});

  @override
  State<NonVehicleDocumentsScreen> createState() =>
      _NonVehicleDocumentsScreenState();
}

class _NonVehicleDocumentsScreenState extends State<NonVehicleDocumentsScreen> {
  final TextEditingController dlController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final NonVehicleAuthController authController = Get.put(
    NonVehicleAuthController(),
  );

  File? dlImage;
  File? aadhaarFrontImage; // ⭐ CHANGED: Front image
  File? aadhaarBackImage; // ⭐ NEW: Back image
  File? videoKyc;
  VideoPlayerController? _videoController;

  String? selectedDlType;
  final List<String> dlTypes = [
    'LMV',
    'MCWG',
    'MCWOG',
    'HMV',
    'TRANS',
    'COMMERCIAL',
    'INTERNATIONAL'
  ];

  // Data from previous screen
  String? name;
  String? phone;
  String? age;
  String? gender;
  File? profileImage;
  bool isReupload = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    name = args?['name'];
    phone = args?['phone'];
    age = args?['age'];
    gender = args?['gender'];
    profileImage = args?['profileImage'];
    isReupload = args?['isReupload'] ?? false;
  }

  @override
  void dispose() {
    dlController.dispose();
    aadhaarController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String? _validateDL(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter driving license number';
    }

    String cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.length != 15) {
      return 'Driving license must be exactly 15 characters';
    }

    if (!RegExp(r'^[A-Z]{2}').hasMatch(cleaned.toUpperCase())) {
      return 'DL must start with 2 letters (State code)';
    }

    if (!RegExp(r'^[A-Z]{2}[0-9]{2}').hasMatch(cleaned.toUpperCase())) {
      return 'Invalid DL format (RTO code must be 2 digits)';
    }

    if (!RegExp(r'^[A-Z]{2}[0-9]{13}$').hasMatch(cleaned.toUpperCase())) {
      return 'Invalid DL format (must be AA00 00000000000)';
    }

    return null;
  }

  String? _validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter Aadhaar number';
    }

    String cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Aadhaar must contain only digits';
    }

    if (cleaned.length != 12) {
      return 'Aadhaar number must be 12 digits';
    }

    return null;
  }

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

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        File originalFile = File(pickedFile.path);

        String prefix = imageType == 'dl'
            ? 'dl_image'
            : imageType == 'aadhaar_front'
            ? 'aadhaar_front'
            : 'aadhaar_back';

        File convertedFile = await _convertToJpeg(originalFile, prefix);

        setState(() {
          if (imageType == 'dl') {
            dlImage = convertedFile;
          } else if (imageType == 'aadhaar_front') {
            aadhaarFrontImage = convertedFile;
          } else if (imageType == 'aadhaar_back') {
            aadhaarBackImage = convertedFile;
          }
        });

        print('✅ $imageType image picked: ${convertedFile.path}');
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickVideoKyc() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Video Source',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _processVideoKyc(ImageSource.camera);
                    });
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _processVideoKyc(ImageSource.gallery);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue[600], size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _processVideoKyc(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );

      if (pickedFile != null) {
        File videoFile = File(pickedFile.path);

        final fileSize = await videoFile.length();
        final fileSizeInMB = fileSize / (1024 * 1024);

        if (fileSizeInMB > 50) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video size must be less than 50MB. Current size: ${fileSizeInMB.toStringAsFixed(2)}MB'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        _videoController?.dispose();
        _videoController = VideoPlayerController.file(videoFile)
          ..initialize().then((_) {
            setState(() {});
          });

        setState(() {
          videoKyc = videoFile;
        });

        print('✅ Video KYC picked: ${videoFile.path}');
        print('📊 Video size: ${fileSizeInMB.toStringAsFixed(2)}MB');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video uploaded successfully (${fileSizeInMB.toStringAsFixed(2)}MB)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Video picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                            'Upload Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Step 2 of 2',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 8,
                      shadowColor: Colors.orange.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Info Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange[700],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Please upload clear images of your documents (front & back) and a video for verification',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Driving License Section
                              Text(
                                'Driving License',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: dlController,
                                decoration: InputDecoration(
                                  labelText: 'Driving License Number',
                                  hintText: 'e.g., DL01 20220012345',
                                  helperText:
                                      '15 characters (AA00 00000000000)',
                                  prefixIcon: Icon(
                                    Icons.credit_card,
                                    color: Colors.orange[600],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: _validateDL,
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: 15,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]'),
                                  ),
                                  LengthLimitingTextInputFormatter(15),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ⭐ NEW: DL Type Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedDlType,
                                decoration: InputDecoration(
                                  labelText: 'DL Type',
                                  prefixIcon: Icon(
                                    Icons.drive_eta,
                                    color: Colors.orange[600],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: dlTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedDlType = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select DL type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildImageUploadCard(
                                'Upload DL Image',
                                dlImage,
                                () => _pickImage('dl'),
                              ),

                              const SizedBox(height: 32),

                              // Aadhaar Section
                              Text(
                                'Aadhaar Card',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: aadhaarController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Aadhaar Number',
                                  hintText: 'Enter 12 digit Aadhaar number',
                                  prefixIcon: Icon(
                                    Icons.badge,
                                    color: Colors.orange[600],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: _validateAadhaar,
                                maxLength: 12,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(12),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ⭐ NEW: Aadhaar Front Image
                              Text(
                                'Aadhaar Front Side',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildImageUploadCard(
                                'Upload Aadhaar Front',
                                aadhaarFrontImage,
                                () => _pickImage('aadhaar_front'),
                              ),

                              const SizedBox(height: 16),

                              // ⭐ NEW: Aadhaar Back Image
                              Text(
                                'Aadhaar Back Side',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildImageUploadCard(
                                'Upload Aadhaar Back',
                                aadhaarBackImage,
                                () => _pickImage('aadhaar_back'),
                              ),

                              const SizedBox(height: 32),

                              // Video KYC Section
                              Text(
                                'Video KYC',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Record your face while looking around (left, right, up, down) for 10 seconds. (max 2 min, 50MB)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildVideoUploadCard(),

                              const SizedBox(height: 32),

                              // Register Button
                              Obx(
                                () => Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: authController.isLoading.value
                                          ? [
                                              Colors.grey[400]!,
                                              Colors.grey[300]!,
                                            ]
                                          : [
                                              Colors.orange[600]!,
                                              Colors.orange[400]!,
                                            ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (authController.isLoading.value
                                                    ? Colors.grey
                                                    : Colors.orange)
                                                .withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: authController.isLoading.value
                                        ? null
                                        : () async {
                                            if (_validateDocuments()) {
                                              if (isReupload) {
                                                // ⭐ REUPLOAD: Call reupload-kyc API
                                                bool
                                                success = await authController
                                                    .reuploadKyc(
                                                      dl: dlController.text
                                                          .trim(),
                                                      dlType: selectedDlType!, // ⭐ NEW
                                                      aadhaar: aadhaarController
                                                          .text
                                                          .trim(),
                                                      dlImage: dlImage!,
                                                      aadhaarFrontImage:
                                                          aadhaarFrontImage!,
                                                      aadhaarBackImage:
                                                          aadhaarBackImage!,
                                                      videoKyc: videoKyc!,
                                                    );
                                                if (success) {
                                                  Get.offAllNamed(
                                                    Routes.SPLASH,
                                                  );
                                                }
                                              } else {
                                                // ⭐ REGISTRATION: Normal first-time register
                                                bool
                                                success = await authController
                                                    .register(
                                                      name: name!,
                                                      phone: phone!,
                                                      age: age!,
                                                      gender: gender!,
                                                      dl: dlController.text
                                                          .trim(),
                                                      dlType: selectedDlType!, // ⭐ NEW
                                                      aadhaar: aadhaarController
                                                          .text
                                                          .trim(),
                                                      dlImage: dlImage!,
                                                      aadhaarFrontImage:
                                                          aadhaarFrontImage!,
                                                      aadhaarBackImage:
                                                          aadhaarBackImage!,
                                                      profileImage:
                                                          profileImage!,
                                                      videoKyc: videoKyc!,
                                                    );
                                                if (success) {
                                                  Get.offNamed(
                                                    '/non-vehicle-otp',
                                                    arguments: {
                                                      'phone': phone,
                                                      'isLogin': false,
                                                    },
                                                  );
                                                }
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                    ),
                                    child: authController.isLoading.value
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
                                            isReupload
                                                ? 'Re-upload Documents'
                                                : 'Register',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.0,
                                            ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadCard(String label, File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange[50],
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.orange[600]),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoUploadCard() {
    return GestureDetector(
      onTap: _pickVideoKyc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 380, // Much taller to show full instruction image
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue[300]!, width: 2),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: videoKyc == null
                ? Stack(
                    children: [
                      // 1. Full Visibility Image
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/kyc_video_instruction.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // 2. Action Button Overlay (Bottom)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                            color: Colors.white.withOpacity(0.85),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'START VIDEO KYC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            _videoController != null &&
                                _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      if (_videoController != null &&
                          _videoController!.value.isInitialized)
                        Positioned.fill(
                          child: Center(
                            child: IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      if (_videoController != null &&
                          _videoController!.value.isInitialized)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_videoController!.value.duration.inMinutes}:${(_videoController!.value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _validateDocuments() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (dlImage == null) {
      showErrorSnackBar('Please upload driving license image');
      return false;
    }

    // ⭐ UPDATED: Check both Aadhaar images
    if (aadhaarFrontImage == null) {
      showErrorSnackBar('Please upload Aadhaar front image');
      return false;
    }

    if (aadhaarBackImage == null) {
      showErrorSnackBar('Please upload Aadhaar back image');
      return false;
    }

    if (videoKyc == null) {
      showErrorSnackBar('Please upload video KYC');
      return false;
    }

    return true;
  }
}
