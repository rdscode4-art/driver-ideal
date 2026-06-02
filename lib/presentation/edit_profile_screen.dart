// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import '../controllers/profile_controller.dart';
// import 'widgets/app_logo.dart';

// class EditProfileScreen extends StatefulWidget {
//   const EditProfileScreen({super.key});

//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final ProfileController controller = Get.find();

//   late TextEditingController nameController;
//   late TextEditingController emailController;
//   late TextEditingController phoneController; // Added phone controller
//   late TextEditingController carModelController;
//   late TextEditingController carNumberController;
//   late TextEditingController carColorController;
//   late TextEditingController licenseNumberController;

//   String selectedCarType = 'Sedan';
//   final List<String> carTypes = ['Sedan', 'SUV', 'Hatchback', 'Bike', 'EV','Auto'];

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers with current values
//     nameController = TextEditingController(text: controller.name);
//     emailController = TextEditingController(text: controller.email);
//     phoneController = TextEditingController(
//         text: controller.phone); // Initialize phone controller
//     carModelController = TextEditingController(text: controller.carModel.value);
//     carNumberController =
//         TextEditingController(text: controller.carNumber.value);
//     carColorController = TextEditingController(text: controller.carColor.value);
//     licenseNumberController =
//         TextEditingController(text: controller.licenseNumber.value);
//     selectedCarType =
//     controller.carType.value.isNotEmpty ? controller.carType.value : 'Sedan';
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     emailController.dispose();
//     phoneController.dispose(); // Dispose phone controller
//     carModelController.dispose();
//     carNumberController.dispose();
//     carColorController.dispose();
//     licenseNumberController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: CustomScrollView(
//         slivers: [
//           // Custom App Bar with gradient
//           SliverAppBar(
//             expandedHeight: 200,
//             backgroundColor: Colors.transparent,
//             pinned: true,
//             elevation: 0,
//             flexibleSpace: FlexibleSpaceBar(
//               background: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.orange[500]!, Colors.orange[400]!],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(25),
//                     bottomRight: Radius.circular(25),
//                   ),
//                 ),
//                 child: const SafeArea(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // App Logo
//                       AppLogo(
//                         width: 80,
//                         height: 80,
//                         margin: EdgeInsets.only(bottom: 30, top: 0),
//                       ),
//                       Text(
//                         'Edit RiDeal Driver Profile',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'Update your information',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Body content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Profile Photo Section
//                   _buildProfilePhotoSection(),

//                   const SizedBox(height: 1),

//                   // Personal Information
//                   _buildPersonalInfoSection(),

//                   const SizedBox(height: 1),

//                   // Vehicle Information
//                   _buildVehicleInfoSection(),

//                   const SizedBox(height: 12),

//                   // Save Button
//                   _buildSaveButton(),

//                   const SizedBox(height: 16),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfilePhotoSection() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 2,
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           gradient: LinearGradient(
//             colors: [Colors.blue[50]!, Colors.white],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[100],
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.photo_camera,
//                     color: Colors.blue[700],
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Text(
//                   'RiDeal Driver Profile Photo',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: Stack(
//                 children: [
//                   Obx(() =>
//                       Container(
//                         width: 120,
//                         height: 120,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.blue[200]!,
//                               width: 3),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.1),
//                               blurRadius: 10,
//                               offset: const Offset(0, 5),
//                             ),
//                           ],
//                         ),
//                         child: CircleAvatar(
//                           radius: 57,
//                           backgroundColor: Colors.blue[50],
//                           backgroundImage: controller.profilePicUrl.value
//                               .isNotEmpty
//                               ? NetworkImage(controller.profilePicUrl.value)
//                               : null,
//                           child: controller.profilePicUrl.value.isEmpty
//                               ? Icon(Icons.person, size: 50, color: Colors
//                               .blue[400])
//                               : null,
//                         ),
//                       )),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: GestureDetector(
//                       onTap: _showPhotoOptions,
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[400],
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 2),
//                         ),
//                         child: const Icon(
//                           Icons.camera_alt,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPersonalInfoSection() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 2,
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           gradient: LinearGradient(
//             colors: [Colors.green[50]!, Colors.white],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.green[100],
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.person,
//                     color: Colors.green[700],
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'RiDeal Driver Personal Information',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildInputField(
//               'RiDeal Driver Full Name',
//               nameController,
//               Icons.person_outline,
//               Colors.green,
//             ),
//             const SizedBox(height: 16),
//             _buildInputField(
//               'RiDeal Driver Email Address',
//               emailController,
//               Icons.email_outlined,
//               Colors.blue,
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 16),
//             _buildInputField(
//               'RiDeal Driver Phone Number',
//               phoneController,
//               Icons.phone_outlined,
//               Colors.orange,
//               keyboardType: TextInputType.phone,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVehicleInfoSection() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 2,
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           gradient: LinearGradient(
//             colors: [Colors.orange[50]!, Colors.white],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.orange[100],
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.directions_car,
//                     color: Colors.orange[700],
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'Vehicle Information',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildDropdownField(
//               'Vehicle Type',
//               selectedCarType,
//               carTypes,
//               Icons.category,
//               Colors.orange,
//                   (String? newValue) {
//                 setState(() {
//                   selectedCarType = newValue!;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
//             _buildInputField(
//               'Vehicle Name',
//               carModelController,
//               Icons.car_rental,
//               Colors.orange,
//             ),
//             const SizedBox(height: 16),
//             _buildInputField(
//               'Vehicle Number',
//               carNumberController,
//               Icons.confirmation_number,
//               Colors.blue,
//             ),
//             const SizedBox(height: 16),
//             _buildInputField(
//               'Vehicle Color',
//               carColorController,
//               Icons.palette,
//               Colors.purple,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInputField(
//     String label,
//     TextEditingController controller,
//     IconData icon,
//     Color color, {
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey[700],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [color.withValues(alpha: 0.1), Colors.white],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: color.withValues(alpha: 0.3)),
//           ),
//           child: TextField(
//             controller: controller,
//             keyboardType: keyboardType,
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[800],
//             ),
//             decoration: InputDecoration(
//               prefixIcon: Container(
//                 margin: const EdgeInsets.all(8),
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withValues(alpha: 0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   color: color,
//                   size: 20,
//                 ),
//               ),
//               hintText: 'Enter $label',
//               hintStyle: TextStyle(color: Colors.grey[500]),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField(
//     String label,
//     String value,
//     List<String> options,
//     IconData icon,
//     Color color,
//     ValueChanged<String?> onChanged,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey[700],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [color.withValues(alpha: 0.1), Colors.white],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: color.withValues(alpha: 0.3)),
//           ),
//           child: DropdownButtonFormField<String>(
//             initialValue: value,
//             decoration: InputDecoration(
//               prefixIcon: Container(
//                 margin: const EdgeInsets.all(8),
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withValues(alpha: 0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   color: color,
//                   size: 20,
//                 ),
//               ),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             ),
//             items: options.map((String option) {
//               return DropdownMenuItem<String>(
//                 value: option,
//                 child: Text(option),
//               );
//             }).toList(),
//             onChanged: onChanged,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSaveButton() {
//     return Container(
//       width: double.infinity,
//       height: 56,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green[600]!, Colors.green[400]!],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withAlpha(102),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed: _saveProfile,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.save,
//               color: Colors.white,
//               size: 20,
//             ),
//             SizedBox(width: 8),
//             Text(
//               'Save Changes',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showPhotoOptions() {
//     Get.bottomSheet(
//       Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Choose Photo',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildPhotoOption(
//                   'Camera',
//                   Icons.camera_alt,
//                   Colors.blue,
//                   () => _pickImage(ImageSource.camera),
//                 ),
//                 _buildPhotoOption(
//                   'Gallery',
//                   Icons.photo_library,
//                   Colors.green,
//                   () => _pickImage(ImageSource.gallery),
//                 ),
//                 if (controller.profilePicUrl.value.isNotEmpty)
//                   _buildPhotoOption(
//                     'Remove',
//                     Icons.delete,
//                     Colors.red,
//                     () => _removePhoto(),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPhotoOption(String label, IconData icon, Color color, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: () {
//         Get.back();
//         onTap();
//       },
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: color.withValues(alpha: 0.1),
//               shape: BoxShape.circle,
//               border: Border.all(color: color.withValues(alpha: 0.3)),
//             ),
//             child: Icon(
//               icon,
//               color: color,
//               size: 30,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _pickImage(ImageSource source) async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: source,
//         maxWidth: 800,
//         maxHeight: 800,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         // Show loading
//         Get.dialog(
//           const Center(
//             child: CircularProgressIndicator(),
//           ),
//           barrierDismissible: false,
//         );

//         // Here you would upload the image to your server
//         // For now, we'll just update the local path
//         await Future.delayed(const Duration(seconds: 2)); // Simulate upload

//         Get.back(); // Close loading dialog

//         // Update the profile picture URL (replace with actual upload response)
//         controller.updateProfilePicture(image.path);

//         Get.snackbar(
//           'Success',
//           'Profile picture updated successfully!',
//           backgroundColor: Colors.green[600],
//           colorText: Colors.white,
//           snackPosition: SnackPosition.TOP,
//         );
//       }
//     } catch (e) {
//       Get.back(); // Close loading dialog if open
//       Get.snackbar(
//         'Error',
//         'Failed to update profile picture: $e',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//     }
//   }

//   void _removePhoto() {
//     controller.updateProfilePicture('');
//     Get.snackbar(
//       'Success',
//       'Profile picture removed successfully!',
//       backgroundColor: Colors.orange[600],
//       colorText: Colors.white,
//       snackPosition: SnackPosition.TOP,
//     );
//   }

//   void _saveProfile() async {
//     // Validate required fields
//     if (nameController.text.trim().isEmpty) {
//       Get.snackbar(
//         'Validation Error',
//         'Please enter your name',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }

//     if (phoneController.text.trim().isEmpty) {
//       Get.snackbar(
//         'Validation Error',
//         'Please enter your phone number',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }

//     try {
//       // Show loading dialog
//       Get.dialog(
//         Center(
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Updating Profile...',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         barrierDismissible: false,
//       );

//       // Update vehicle information immediately to ProfileController
//       await _updateVehicleInformation();

//       // Call the API through controller for name and phone
//       final success = await controller.updateDriverProfile(
//         name: nameController.text.trim(),
//         phone: phoneController.text.trim(),
//       );

//       Get.back(); // Close loading dialog

//       if (success) {
//         Get.back(); // Go back to profile screen
//         Get.snackbar(
//           'Success',
//           'Profile and vehicle information updated successfully!',
//           backgroundColor: Colors.green[600],
//           colorText: Colors.white,
//           snackPosition: SnackPosition.TOP,
//           icon: const Icon(Icons.check_circle, color: Colors.white),
//         );
//       } else {
//         Get.snackbar(
//           'Error',
//           'Failed to update profile. Please try again.',
//           backgroundColor: Colors.red[600],
//           colorText: Colors.white,
//           snackPosition: SnackPosition.TOP,
//           icon: const Icon(Icons.error, color: Colors.white),
//         );
//       }
//     } catch (e) {
//       Get.back(); // Close loading dialog if still open
//       Get.snackbar(
//         'Error',
//         'Failed to update profile: $e',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//         icon: const Icon(Icons.error, color: Colors.white),
//       );
//     }
//   }

//   // Update vehicle information in ProfileController and save to storage
//   Future<void> _updateVehicleInformation() async {
//     try {
//       print('🚗 Updating vehicle information from edit profile...');

//       // Update reactive variables in ProfileController with correct mapping
//       controller.carModel.value = carModelController.text.trim();
//       controller.carNumber.value = carNumberController.text.trim();
//       controller.carColor.value = carColorController.text.trim();
//       controller.carType.value = selectedCarType;
//       controller.licenseNumber.value = licenseNumberController.text.trim();

//       // Since saveVehicleInfoFromKyc doesn't exist, we'll just update the controller values
//       // The vehicle information will be stored in the reactive variables
//       print('✅ Vehicle information updated locally: ${controller.carModel.value} (${controller.carNumber.value})');
//     } catch (e) {
//       print('❌ Failed to update vehicle information: $e');
//     }
//   }
// }
