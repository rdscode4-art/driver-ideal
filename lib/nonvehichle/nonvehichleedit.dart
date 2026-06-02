import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideal_driver/nonvehichle/non_vehichle_profile_controller.dart';

class EditProfileScreenNon extends StatefulWidget {
  const EditProfileScreenNon({super.key});

  @override
  State<EditProfileScreenNon> createState() => _EditProfileScreenNonState();
}

class _EditProfileScreenNonState extends State<EditProfileScreenNon> {
  final controller = Get.find<NonVehichleProfileController>();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController nameController;
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: controller.name.value);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (image != null) {
        final file = File(image.path);
        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }

        final extension = image.path.toLowerCase().split('.').last;
        final validExtensions = ['jpg', 'jpeg', 'png', 'webp', 'avif', 'heic'];
        
        if (!validExtensions.contains(extension)) {
          Get.snackbar(
            'Invalid File',
            'Please select a valid image file (jpg, jpeg, png, webp, avif, heic)',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        setState(() {
          selectedImage = file;
        });
        
        print('✅ Image selected: ${image.path}');
        print('✅ File size: ${await file.length()} bytes');
        print('✅ Extension: $extension');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop(); // Dialog band karo
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop(); // Dialog band karo
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await controller.updateProfile(
        name: nameController.text.trim(),
        
        profileImage: selectedImage,
      );

      // Pehle snackbars band karo
      Get.closeAllSnackbars();
      
      // Thoda wait karo
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Ab navigate karo
      if (mounted) {
        Navigator.of(context).pop(); // Safe navigation
      }
      
      // Success message thodi der baad dikhao
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      });
    } catch (e) {
      print('❌ Error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.orange[500],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.closeAllSnackbars();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Image Section
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Obx(() {
                        final profilePic = controller.profilePicUrl.value;
                        print('📸 EditProfileScreenNon image: $profilePic');
                        
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: selectedImage != null
                                ? Image.file(
                                    selectedImage!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : (profilePic.isNotEmpty
                                    ? Image.network(
                                        profilePic,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ NonVehicle Edit image error: $error');
                                          return const Icon(Icons.person, size: 60, color: Colors.grey);
                                        },
                                      )
                                    : const Icon(Icons.person, size: 60, color: Colors.grey)),
                          ),
                        );
                      }),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),

                // Name Field (Only editable field)
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone (Read-only)
                TextFormField(
                  initialValue: controller.phone.value,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[500],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}