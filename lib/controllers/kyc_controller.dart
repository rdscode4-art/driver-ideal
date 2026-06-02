import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rideal_driver/controllers/vehicle_type_controller.dart';
import 'package:rideal_driver/subscriptioncontroller.dart';
import '../routes/app_pages.dart';
import '../services/kyc_api_service.dart';
import '../core/storage_helper.dart';
import '../data/models/kyc_verification_model.dart';
import '../core/utils/app_snackbar.dart';
// ADD THIS IMPORT
import 'dart:io';

class KYCController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();
final VehicleTypeController vehicleTypeController = Get.put(VehicleTypeController());
  // Loading states
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Verification data from new API
  var verificationStatusResponse = Rx<KycVerificationStatusResponse?>(null);
  var verificationData = Rx<KycVerification?>(null);
  var verificationStatus = ''.obs;
  var overallStatus = ''.obs;

  // Text controllers for form inputs
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController drivingLicenseController =
      TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController vehicleNameController = TextEditingController();

  // Image observables - store File objects for local images and URLs for API images
  var aadhaarFrontImage = Rx<String?>(null);
  var aadhaarBackImage = Rx<String?>(null);
  var drivingLicenseImage = Rx<String?>(null);
  var vehicleImage = Rx<String?>(null);
  var vehicleRC = Rx<String?>(null);
  var vehicleInsurance = Rx<String?>(null);

  // Local file storage for new uploads
  var aadhaarFrontFile = Rx<File?>(null);
  var aadhaarBackFile = Rx<File?>(null);
  var drivingLicenseFile = Rx<File?>(null);
  var vehicleImageFile = Rx<File?>(null);
  var vehicleRCFile = Rx<File?>(null);
  var vehicleInsuranceFile = Rx<File?>(null);

  // Vehicle type dropdown - default to "sedan" as requested
  var selectedVehicleType = 'sedan'.obs;
  

  // Aadhaar masking
  var showFullAadhaar = false.obs;
 List<String> get vehicleTypes => vehicleTypeController.vehicleTypes;
 // ADD: Get vehicle type display name
  String getVehicleTypeDisplayName(String type) {
    return vehicleTypeController.getDisplayName(type);
  }

  // ADD: Check if loading vehicle types
  bool get isLoadingVehicleTypes => vehicleTypeController.isLoading.value;

  // ADD: Refresh vehicle types
  Future<void> refreshVehicleTypes() async {
    await vehicleTypeController.refreshVehicleTypes();
  }
  @override
  void onInit() {
    super.onInit();
    fetchVerificationStatus(); // Fetch data from new API on init
 vehicleTypeController.fetchVehicleTypes();
    // Add listener to Aadhaar controller for masking
    aadhaarController.addListener(() {
      if (!showFullAadhaar.value && aadhaarController.text.length > 4) {
        // Auto-hide after typing stops
        Future.delayed(const Duration(seconds: 2), () {
          showFullAadhaar.value = false;
        });
      }
    });
  }

  @override
  void onClose() {
    // Dispose text controllers
    aadhaarController.dispose();
    drivingLicenseController.dispose();
    vehicleNumberController.dispose();
    vehicleNameController.dispose();
    super.onClose();
  }

  /// Fetch KYC verification status from the new API endpoint
 Future<void> fetchVerificationStatus() async {
    try {
      print('🔄 Fetching KYC verification status...');
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await KycApiService.getVerificationStatus();

      if (response['success'] == true && response['data'] != null) {
        verificationStatusResponse.value = response['data'] as KycVerificationStatusResponse;
        verificationData.value = verificationStatusResponse.value?.verification;

        final previousStatus = verificationStatus.value;
       overallStatus.value =
    verificationStatusResponse.value?.status.toLowerCase() ?? 'unknown';

// 🔥 MAIN STATUS ALWAYS FROM BACKEND TOP LEVEL
verificationStatus.value = overallStatus.value;


        if (verificationData.value != null) {
          if (verificationStatus.value.toLowerCase() == 'approved' ||
              verificationStatus.value.toLowerCase() == 'accepted' ||
              overallStatus.value.toLowerCase() == 'approved' ||
              overallStatus.value.toLowerCase() == 'accepted') {
            print('✅ Backend approved KYC - respecting approval status');
            _populateFormWithApiData(verificationData.value!);
          } else if (_isEmptySubmission(verificationData.value!)) {
            print('🔍 Detected empty submission with non-approved status - treating as not submitted');
            verificationData.value = null;
            verificationStatus.value = 'not_submitted';
            overallStatus.value = 'not_submitted';
          } else {
            _populateFormWithApiData(verificationData.value!);
          }
        }

        _handleStatusChangeNavigation(previousStatus, verificationStatus.value);

        print('✅ KYC verification status loaded successfully');
        print('📊 Status: ${verificationStatus.value}');
        debugPrintStatus();
      } else if (response['success'] == true && response['data'] == null) {
        print('📋 No KYC documents found - new user');
        verificationStatusResponse.value = null;
        verificationData.value = null;
        verificationStatus.value = 'not_submitted';
        overallStatus.value = 'not_submitted';
      } else {
        hasError.value = true;
        errorMessage.value = response['message'] ?? 'Failed to fetch verification status';
        print('❌ Failed to fetch KYC status: ${errorMessage.value}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error: $e';
      print('💥 Exception in fetchVerificationStatus: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle navigation when verification status changes
  void _handleStatusChangeNavigation(
    String previousStatus,
    String currentStatus,
  ) {
    final status = currentStatus.toLowerCase();
    
    // CASE 1: Status is pending - Redirect to verification pending screen
    if (status == 'pending') {
      print('⏰ KYC Status is pending - Redirecting to verification pending screen');
      Get.offAllNamed('/verification-pending');
      return;
    }

    // CASE 2: Status changed to approved/accepted - Redirect to subscription/dashboard
    if ((status == 'approved' || status == 'accepted') &&
        (previousStatus.toLowerCase() != 'approved' &&
            previousStatus.toLowerCase() != 'accepted')) {
      print(
        '🎉 KYC Status changed to approved/accepted - initiating navigation',
      );

      // Use a slight delay to ensure UI updates are complete
      Future.delayed(const Duration(milliseconds: 500), () {
        navigateToAcceptedDashboard();
      });
    }
  }

  /// Navigate to dashboard when KYC is approved - WITH SUBSCRIPTION CHECK
  Future<void> navigateToAcceptedDashboard() async {
    try {
      print('🏠 KYC accepted - checking subscription status...');

      // Get subscription controller
      final subscriptionController = Get.find<SubscriptionController>();

      // Check subscription status first
      await subscriptionController.loadSubscriptionStatus();

      // Check if user already has active subscription
      if (subscriptionController.hasSubscription.value &&
          subscriptionController.subscriptionActive.value) {
        print('✅ User already has active subscription - navigating to HOME');

        // Navigate directly to home/dashboard
        Get.offAllNamed(Routes.HOME); // or your main dashboard route

        // Show welcome back message
        Future.delayed(const Duration(milliseconds: 200), () {
          showSuccessSnackBar(
            'Your KYC is approved and subscription is active.',
            title: 'Welcome Back! 🎉',
          );
        });
      } else {
        print('📋 No active subscription - navigating to SUBSCRIPTION screen');

        // Navigate to subscription screen for first-time activation
        Get.offAllNamed(Routes.SUBSCRIPTION);

        // Show success message
        Future.delayed(const Duration(milliseconds: 200), () {
          showSuccessSnackBar(
            'Please choose a subscription plan to continue.',
            title: 'KYC Approved! 🎉',
          );
        });
      }
    } catch (e) {
      print('❌ Error navigating to dashboard: $e');
      
      // Fallback to subscription screen if error occurs
      Get.offAllNamed(Routes.SUBSCRIPTION);
    }
  }

  /// Check and navigate if approved - WITH SUBSCRIPTION CHECK
  Future<void> checkAndNavigateIfApproved() async {
    if (verificationStatus.value.toLowerCase() == 'approved' ||
        verificationStatus.value.toLowerCase() == 'accepted' ||
        overallStatus.value.toLowerCase() == 'approved' ||
        overallStatus.value.toLowerCase() == 'accepted') {
      print(
        '🔍 Manual check - KYC is approved/accepted, checking subscription...',
      );
      await navigateToAcceptedDashboard();
    }
  }

  /// Check if this is an empty submission (all required fields are empty/null)
  bool _isEmptySubmission(KycVerification data) {
    return (data.aadhaarNumber.isEmpty || data.aadhaarNumber.trim().isEmpty) &&
        (data.drivingLicenseNumber.isEmpty ||
            data.drivingLicenseNumber.trim().isEmpty) &&
        (data.vehicleNumber.isEmpty || data.vehicleNumber.trim().isEmpty) &&
        (data.vehicleName.isEmpty || data.vehicleName.trim().isEmpty) &&
        (data.vehicleType.isEmpty || data.vehicleType.trim().isEmpty) &&
        (data.aadhaarPic.isEmpty || data.aadhaarPic.trim().isEmpty) &&
        (data.drivingLicensePic.isEmpty ||
            data.drivingLicensePic.trim().isEmpty) &&
        (data.vehicleImage.isEmpty || data.vehicleImage.trim().isEmpty) &&
        (data.vehicleRC.isEmpty || data.vehicleRC.trim().isEmpty) &&
        (data.vehicleInsurance.isEmpty || data.vehicleInsurance.trim().isEmpty);
  }

  /// Populate form fields with data from API
  void _populateFormWithApiData(KycVerification data) {
    // Only populate if data is not empty
    if (data.aadhaarNumber.isNotEmpty) {
      aadhaarController.text = data.aadhaarNumber;
    }
    if (data.drivingLicenseNumber.isNotEmpty) {
      drivingLicenseController.text = data.drivingLicenseNumber;
    }
    if (data.vehicleNumber.isNotEmpty) {
      vehicleNumberController.text = data.vehicleNumber;
    }
    if (data.vehicleName.isNotEmpty) {
      vehicleNameController.text = data.vehicleName;
    }
    if (data.vehicleType.isNotEmpty) {
      selectedVehicleType.value = data.vehicleType;
    }

    // Set image URLs from API only if they exist
     if (data.fullAadhaarPicUrl.isNotEmpty == true) {
      aadhaarFrontImage.value = data.fullAadhaarPicUrl;
      // If backend has separate back image field, uncomment:
      // aadhaarBackImage.value = data.fullAadhaarBackPicUrl;
    }
    
    if (data.fullDrivingLicensePicUrl.isNotEmpty == true) {
      drivingLicenseImage.value = data.fullDrivingLicensePicUrl;
    }
    if (data.fullVehicleImageUrl.isNotEmpty == true) {
      vehicleImage.value = data.fullVehicleImageUrl;
    }
    if (data.fullVehicleRCUrl.isNotEmpty == true) {
      vehicleRC.value = data.fullVehicleRCUrl;
    }
    if (data.fullVehicleInsuranceUrl.isNotEmpty == true) {
      vehicleInsurance.value = data.fullVehicleInsuranceUrl;
    }
  }

  /// Get masked Aadhaar number (show only last 4 digits)
  String get maskedAadhaar {
    final text = aadhaarController.text;
    if (text.length <= 4 || showFullAadhaar.value) {
      return text;
    }
    return '*' * (text.length - 4) + text.substring(text.length - 4);
  }

  /// Toggle Aadhaar visibility
  void toggleAadhaarVisibility() {
    showFullAadhaar.value = !showFullAadhaar.value;
  }

  /// Refresh verification status
  Future<void> refreshVerificationStatus() async {
    await fetchVerificationStatus();
  }

  /// Refresh verification status (alias)
  Future<void> refreshStatus() async {
    await fetchVerificationStatus();
  }

  /// Get status color for UI display
  Color get statusColor {
    return verificationData.value?.statusColor ?? Colors.grey;
  }

  /// Get status color for UI display (method)
  Color getStatusColor() {
    return verificationData.value?.statusColor ?? Colors.grey;
  }

  /// Get status icon for UI display
  IconData getStatusIcon() {
    return verificationData.value?.statusIcon ?? Icons.help;
  }

  /// Get status display text
  String getStatusDisplayText() {
    return verificationData.value?.statusDisplayName ?? 'Unknown';
  }

  /// Check if documents are submitted
  bool get hasSubmittedDocuments {
    return verificationData.value != null &&
        verificationStatus.value != 'not_submitted';
  }

  /// Check if user can EDIT documents (more permissive)
 bool get canEditDocuments {
  final s = verificationStatus.value.toLowerCase();
  return s == 'unknown' || s == 'not_submitted' || s == 'rejected';
}

  /// Check if user can submit documents - IMPROVED LOGIC
  bool get canSubmitDocuments {
    print('🔍 canSubmitDocuments check:');
    print('  verificationData exists: ${verificationData.value != null}');
    print('  verificationStatus: ${verificationStatus.value}');

    // If no verification data exists (new user), check if form is filled
    if (verificationData.value == null ||
        verificationStatus.value == 'not_submitted') {
      print('  → New user or not submitted, checking form completion');
      final canSubmit = _areAllFieldsFilled();
      print('  → areAllFieldsFilled: $canSubmit');
      return canSubmit;
    }

    final status = verificationStatus.value.toLowerCase();
    print('  → Current status: $status');

    // Allow resubmission if rejected or failed
    if (status == 'rejected' || status == 'failed') {
      print('  → Rejected/failed status, allowing resubmission');
      return _areAllFieldsFilled();
    }

    // Allow re-submission even for pending (user might want to update docs)
    if (status == 'pending') {
      print('  → Status pending, allowing re-submission for updates');
      return _areAllFieldsFilled();
    }

    if (status == 'accepted' || status == 'approved') {
      print('  → Status accepted/approved, blocking submission');
      return false;
    }

    // For unknown status, allow submission if form is filled
    print('  → Unknown status, checking form');
    return _areAllFieldsFilled();
  }

  /// Check if all required fields are filled - IMPROVED VALIDATION
  bool _areAllFieldsFilled() {
    final hasAadhaar = aadhaarController.text.trim().length == 12;
    final hasLicense = drivingLicenseController.text.trim().isNotEmpty;
    final hasVehicleNumber = vehicleNumberController.text.trim().isNotEmpty;
    final hasVehicleName = vehicleNameController.text.trim().isNotEmpty;
    final hasVehicleType = selectedVehicleType.value.trim().isNotEmpty;
final hasAadhaarFront = _hasValidDocument(aadhaarFrontFile.value, aadhaarFrontImage.value);
    final hasAadhaarBack = _hasValidDocument(aadhaarBackFile.value, aadhaarBackImage.value);
    // Check for actual file uploads or valid image URLs
   
    final hasLicenseDoc = _hasValidDocument(
      drivingLicenseFile.value,
      drivingLicenseImage.value,
    );
    final hasVehicleDoc = _hasValidDocument(
      vehicleImageFile.value,
      vehicleImage.value,
    );
    final hasRCDoc = _hasValidDocument(vehicleRCFile.value, vehicleRC.value);
    final hasInsuranceDoc = _hasValidDocument(
      vehicleInsuranceFile.value,
      vehicleInsurance.value,
    );

    final areAllFieldsFilled =
        hasAadhaar &&
        hasLicense &&
        hasVehicleNumber &&
        hasVehicleName &&
        hasVehicleType &&
        hasAadhaarFront &&
        hasAadhaarBack &&
        hasLicenseDoc &&
        hasVehicleDoc &&
        hasRCDoc &&
        hasInsuranceDoc;

    print('📋 Field validation:');
    print(
      '  hasAadhaar: $hasAadhaar (${aadhaarController.text.trim().length} digits)',
    );
    print('  hasLicense: $hasLicense');
    print('  hasVehicleNumber: $hasVehicleNumber');
    print('  hasVehicleName: $hasVehicleName');
    print('  hasVehicleType: $hasVehicleType');
    print('  hasAadhaarFront: $hasAadhaarFront');
    print('  hasAadhaarBack: $hasAadhaarBack');
    print('  hasLicenseDoc: $hasLicenseDoc');
    print('  hasVehicleDoc: $hasVehicleDoc');
    print('  hasRCDoc: $hasRCDoc');
    print('  hasInsuranceDoc: $hasInsuranceDoc');
    print('  areAllFieldsFilled: $areAllFieldsFilled');

    return areAllFieldsFilled;
  }

  /// Helper method to check if document is valid (either file exists or valid URL)
  bool _hasValidDocument(File? file, String? imageUrl) {
    return file != null ||
        (imageUrl != null &&
            imageUrl.trim().isNotEmpty &&
            !imageUrl.startsWith('https://backend.ridealmobility.com/'));
  }

  /// Check if verification is approved
  bool get isVerificationAccepted {
    return verificationStatus.value.toLowerCase() == 'accepted' ||
        verificationStatus.value.toLowerCase() == 'approved' ||
        overallStatus.value.toLowerCase() == 'accepted' ||
        overallStatus.value.toLowerCase() == 'approved';
  }

  /// Check if verification is pending
  bool get isVerificationPending {
  return verificationStatus.value.toLowerCase() == 'pending'
      || overallStatus.value.toLowerCase() == 'pending';
}


  /// Check if verification is rejected
  bool get isVerificationRejected {
    return verificationStatus.value.toLowerCase() == 'rejected' ||
        verificationStatus.value.toLowerCase() == 'declined' ||
        overallStatus.value.toLowerCase() == 'rejected' ||
        overallStatus.value.toLowerCase() == 'declined';
  }

  /// Get current status for debugging
  String getCurrentStatus() {
    return 'verificationStatus: ${verificationStatus.value}, overallStatus: ${overallStatus.value}, isAccepted: $isVerificationAccepted, isPending: $isVerificationPending, isRejected: $isVerificationRejected';
  }

  /// Debug method to show all status information
  void debugPrintStatus() {
    print('🔍 DEBUG KYC Status:');
    print('  verificationStatus: ${verificationStatus.value}');
    print('  overallStatus: ${overallStatus.value}');
    print('  verificationData exists: ${verificationData.value != null}');
    print('  isVerificationAccepted: $isVerificationAccepted');
    print('  isVerificationPending: $isVerificationPending');
    print('  isVerificationRejected: $isVerificationRejected');
    if (verificationData.value != null) {
      print('  Backend status from data: ${verificationData.value!.status}');
    }
  }

  /// Force refresh status from backend (for testing after approval)
  Future<void> forceRefreshStatus() async {
    print('🔄 FORCE REFRESHING KYC Status...');
    print('🧹 Clearing all cached data...');

    // Clear all cached data first
    verificationStatusResponse.value = null;
    verificationData.value = null;
    verificationStatus.value = '';
    overallStatus.value = '';

    // Clear local storage cache
    try {
      await StorageHelper.clearKYCData();
      print('✅ Local KYC cache cleared');
    } catch (e) {
      print('⚠️ Error clearing local cache: $e');
    }

    // Force fresh API call
    await fetchVerificationStatus();

    // Double check after refresh
    if (isVerificationAccepted) {
      print('🎉 KYC NOW APPROVED! Navigating to dashboard...');
      navigateToAcceptedDashboard();
    } else {
      print('📋 Status after refresh: ${verificationStatus.value}');
      print('🔍 Overall status: ${overallStatus.value}');
    }
  }

  // ... rest of your methods remain the same (showImagePickerOptions, _pickImage, etc.)

  /// Show image picker options
 Future<void> showImagePickerOptions(String imageType) async {
    try {
      final ImageSource? source = await Get.bottomSheet<ImageSource>(
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Select Image Source',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.camera_alt, color: Colors.blue[700]),
                      title: const Text('Camera'),
                      onTap: () {
                        Navigator.of(Get.context!).pop(ImageSource.camera);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.photo_library, color: Colors.blue[700]),
                      title: const Text('Gallery'),
                      onTap: () {
                        Navigator.of(Get.context!).pop(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
      );

      if (source != null) {
        if (source == ImageSource.camera) {
          final bool hasCameraPermission = await _requestCameraPermission();
          if (!hasCameraPermission) {
            showErrorSnackBar('Camera permission is required to capture documents.', title: 'Permission Denied');
            return;
          }
        }
        await _pickImage(imageType, source);
      }
    } catch (e) {
      print('Error showing image picker: $e');
      showErrorSnackBar('Failed to open image picker: ${e.toString()}', title: 'Error');
    }
  }

  /// Request camera permission dynamically when choosing Camera source
  Future<bool> _requestCameraPermission() async {
    try {
      var cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        cameraStatus = await Permission.camera.request();
      }
      return cameraStatus.isGranted || cameraStatus.isLimited;
    } catch (e) {
      print('⚠️ Camera permission check error: $e');
      return false;
    }
  }

  /// Show error snackbar with better formatting
  void _showErrorSnackbar(String title, String message) {
    showErrorSnackBar(message, title: title);
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String title, String message) {
    showSuccessSnackBar(message, title: title);
  }

  /// Pick image from source
 Future<void> _pickImage(String imageType, ImageSource source) async {
    try {
      print('🖼️ Picking image for type: $imageType from source: $source');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        if (await imageFile.exists()) {
          final fileSize = await imageFile.length();
          print('✅ Image picked successfully: ${pickedFile.path} (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');

          switch (imageType) {
            case 'aadhaar_front':
              aadhaarFrontFile.value = imageFile;
              aadhaarFrontImage.value = pickedFile.path;
              break;
            case 'aadhaar_back':
              aadhaarBackFile.value = imageFile;
              aadhaarBackImage.value = pickedFile.path;
              break;
            case 'license':
              drivingLicenseFile.value = imageFile;
              drivingLicenseImage.value = pickedFile.path;
              break;
            case 'vehicle':
              vehicleImageFile.value = imageFile;
              vehicleImage.value = pickedFile.path;
              break;
            case 'rc':
              vehicleRCFile.value = imageFile;
              vehicleRC.value = pickedFile.path;
              break;
            case 'insurance':
              vehicleInsuranceFile.value = imageFile;
              vehicleInsurance.value = pickedFile.path;
              break;
            default:
              print('⚠️ Unknown image type: $imageType');
              return;
          }

          _showSuccessSnackbar('Success', 'Image selected successfully for ${imageType.toUpperCase()}');
        } else {
          throw Exception('Selected file does not exist');
        }
      } else {
        print('❌ No image was selected');
        showWarningSnackBar('No image was selected', title: 'No Image');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorSnackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  /// ⭐ UPDATED: Remove image with support for aadhaar_front and aadhaar_back
  void removeImage(String imageType) {
    switch (imageType) {
      case 'aadhaar_front':
        aadhaarFrontFile.value = null;
        aadhaarFrontImage.value = null;
        break;
      case 'aadhaar_back':
        aadhaarBackFile.value = null;
        aadhaarBackImage.value = null;
        break;
      case 'license':
        drivingLicenseFile.value = null;
        drivingLicenseImage.value = null;
        break;
      case 'vehicle':
        vehicleImageFile.value = null;
        vehicleImage.value = null;
        break;
      case 'rc':
        vehicleRCFile.value = null;
        vehicleRC.value = null;
        break;
      case 'insurance':
        vehicleInsuranceFile.value = null;
        vehicleInsurance.value = null;
        break;
    }
  }

  /// Submit verification documents
 /// Replace your existing submitVerification method with this
Future<void> submitVerification() async {
  print('🚀 Starting KYC document submission...');

  if (!canSubmitDocuments) {
    print('❌ Cannot submit documents - validation failed');
    showWarningSnackBar('Please fill all required fields', title: 'Error');
    return;
  }

  try {
    isSubmitting.value = true;
    print('📋 Checking all required files...');

    // Ensure we have File objects for submission
    final aadhaarFrontFileToSubmit = aadhaarFrontFile.value;
    final aadhaarBackFileToSubmit = aadhaarBackFile.value;
    final licenseFileToSubmit = drivingLicenseFile.value;
    final vehicleFileToSubmit = vehicleImageFile.value;
    final rcFileToSubmit = vehicleRCFile.value;
    final insuranceFileToSubmit = vehicleInsuranceFile.value;

      if (aadhaarFrontFileToSubmit == null ||
          aadhaarBackFileToSubmit == null ||
          licenseFileToSubmit == null ||
          vehicleFileToSubmit == null ||
          rcFileToSubmit == null ||
          insuranceFileToSubmit == null) {
        print('❌ Missing files - cannot submit');
        showErrorSnackBar('Please upload all required documents', title: 'Error');
        return;
      }

    print('✅ All files present, proceeding with API call...');

    final response = await KycApiService.submitKycDocuments(
      aadhaarNumber: aadhaarController.text.trim(),
      drivingLicenseNumber: drivingLicenseController.text.trim(),
      vehicleNumber: vehicleNumberController.text.trim(),
      vehicleType: selectedVehicleType.value.trim(),
      vehicleName: vehicleNameController.text.trim(),
      aadhaarBackImage: aadhaarBackFileToSubmit,
      aadhaarFrontImage: aadhaarFrontFileToSubmit,
      drivingLicenseImage: licenseFileToSubmit,
      vehicleImage: vehicleFileToSubmit,
      vehicleRCImage: rcFileToSubmit,
      vehicleInsuranceImage: insuranceFileToSubmit,
    );

    print('🔄 API Response received: $response');

    if (response['success'] == true) {
      print('✅ KYC submission successful!');
      
      // Show success message
      showSuccessSnackBar(
        'Documents submitted successfully',
        title: 'Success! 🎉',
      );

      // Save data locally
      await _saveDataLocally();

      // Update local state to reflect pending status
      verificationStatus.value = 'pending';
      overallStatus.value = 'pending';

      // Navigate immediately without relying on the backend to reflect the status instantly
      print('🚀 Navigating to verification pending screen...');
      Get.offAllNamed('/verification-pending');
      
      
    } else {
      print('❌ KYC submission failed: ${response['message']}');
      showErrorSnackBar(
        response['message'] ?? 'Failed to submit documents',
        title: 'Error',
      );
    }
  } catch (e) {
    print('💥 Error submitting verification: $e');
    showErrorSnackBar(
      'Network error: $e',
      title: 'Error',
    );
  } finally {
    isSubmitting.value = false;
  }
}
  /// Save data to local storage
  Future<void> _saveDataLocally() async {
    try {
      final data = {
        'aadhaarNumber': aadhaarController.text.trim(),
        'drivingLicenseNumber': drivingLicenseController.text.trim(),
        'vehicleNumber': vehicleNumberController.text.trim(),
        'vehicleName': vehicleNameController.text.trim(),
        'vehicleType': selectedVehicleType.value.trim(),
        'aadhaarFrontImage': aadhaarFrontFile.value,
        'aadhaarBackImage': aadhaarBackFile.value,
        'drivingLicenseImagePath': drivingLicenseImage.value,
        'vehicleImagePath': vehicleImage.value,
        'vehicleRCPath': vehicleRC.value,
        'vehicleInsurancePath': vehicleInsurance.value,
      };

      await StorageHelper.saveKYCData(data);
    } catch (e) {
      print('Error saving KYC data locally: $e');
    }
  }

  /// Load saved data from local storage
  Future<void> loadSavedData() async {
    try {
      final savedData = await StorageHelper.getKYCData();
      if (savedData != null) {
        aadhaarController.text = savedData['aadhaarNumber'] ?? '';
        drivingLicenseController.text = savedData['drivingLicenseNumber'] ?? '';
        vehicleNumberController.text = savedData['vehicleNumber'] ?? '';
        vehicleNameController.text = savedData['vehicleName'] ?? '';
        selectedVehicleType.value = savedData['vehicleType'] ?? 'sedan';

        // Load image paths
        aadhaarFrontFile.value = savedData['aadhaarFrontImage'] ?? savedData['aadhaarImage'];
        aadhaarBackFile.value = savedData['aadhaarBackImage'];
        drivingLicenseImage.value = savedData['drivingLicenseImagePath'];
        vehicleImage.value = savedData['vehicleImagePath'];
        vehicleRC.value = savedData['vehicleRCPath'];
        vehicleInsurance.value = savedData['vehicleInsurancePath'];
      }
    } catch (e) {
      print('Error loading saved KYC data: $e');
    }
  }
}
