import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/token_manager.dart';
import '../../routes/app_pages.dart';

class VerificationPendingController extends GetxController {
  var isLoading = false.obs;
  var status = 'pending'.obs;
  var rejectionReason = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkStatus();
  }

  Future<void> checkStatus() async {
    try {
      isLoading.value = true;
      
      final tokenManager = Get.find<TokenManager>();
      final driverId = tokenManager.userId.value;
      final token = tokenManager.authToken.value;
      final role = tokenManager.userRole.value;

      if (driverId == null || driverId.isEmpty || token == null || token.isEmpty) {
        status.value = 'pending';
        isLoading.value = false;
        return;
      }

      if (role == 'non-vehicle-driver') {
        // --- NON-VEHICLE DRIVER ---
        final url = 'https://backend.ridealmobility.com/api/non-vehicle-driver/profile/$driverId';
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['driver'] != null) {
            final driver = data['driver'];
            status.value = (driver['status'] ?? 'pending').toString().toLowerCase();
            rejectionReason.value = (driver['kycRejectReason'] ?? '').toString();
            
            print('📊 Non-Vehicle Verification Status Updated: ${status.value}');
          }
        }
      } else {
        // --- REGULAR DRIVER ---
        final url = 'https://backend.ridealmobility.com/auth/driver-profile';
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['success'] == true && data['driver'] != null) {
            final driver = data['driver'];
            
            // Check verification status from the profile
            if (driver['verification'] != null) {
              final backendStatus = (driver['verification']['status'] ?? 'pending').toString().toLowerCase();
              status.value = backendStatus;
              rejectionReason.value = (driver['verification']['rejectReason'] ?? '').toString();
            } else {
              // If no verification object, it might be pending or not_submitted
              status.value = 'pending'; 
            }
            
            print('📊 Regular Driver Verification Status Updated from Profile: ${status.value}');
          }
        }
      }

      // If approved, navigate to splash screen to handle routing
      if (status.value == 'approved' || status.value == 'accepted' || status.value == 'active' || status.value == 'verified') {
         print('✅ KYC Approved! Redirecting to Splash Screen...');
         Get.offAllNamed(Routes.SPLASH);
      } else if (status.value == 'rejected' || status.value == 'declined') {
         print('❌ KYC Rejected: ${rejectionReason.value}');
      }

    } catch (e) {
      print('❌ Error checking status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void goToReupload() {
    // Navigate back to registration flow but specifically to documents screen for reupload
    Get.offAllNamed(Routes.NON_VEHICLE_DOCUMENTS, arguments: {
      'isReupload': true,
    });
  }
}
