import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rideal_driver/core/storage_helper.dart';
import '../core/utils/app_snackbar.dart';

class NonVehichleProfileController extends GetxController {
  final storage = GetStorage();
  
  // API endpoint
  final String baseUrl = 'https://backend.ridealmobility.com/api/non-vehicle-driver';
  
  // Observable variables from API
  var rndId = ''.obs;
  var name = ''.obs;
  var phone = ''.obs;
  var age = ''.obs;
  var gender = ''.obs;
  var dl = ''.obs;
  var aadhaar = ''.obs;
  var dlImage = ''.obs;
  var aadhaarImage = ''.obs;
  var status = ''.obs;
  var wallet = 0.0.obs;
  var profilePicUrl = ''.obs;
  var driverId = ''.obs;
  var referralCode = ''.obs; // 🆕 Added referral code
  
  var isLoading = false.obs;
  var isVerified = false.obs;
  var verificationStatus = 'Pending'.obs;

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
    fetchProfile().then((_) {
      fetchRndId();
    });
  }

  void _updateVerificationStatus(String statusValue) {
    final lowerStatus = statusValue.toLowerCase();
    
    if (lowerStatus == 'approved' || lowerStatus == 'verified' || lowerStatus == 'active') {
      isVerified.value = true;
      verificationStatus.value = 'Verified';
      print('✅ Status set to: Verified (from: $statusValue)');
    } 
    else if (lowerStatus == 'pending' || lowerStatus == 'under_review') {
      isVerified.value = false;
      verificationStatus.value = 'Pending';
      print('⏳ Status set to: Pending (from: $statusValue)');
    } 
    else if (lowerStatus == 'rejected' || lowerStatus == 'declined') {
      isVerified.value = false;
      verificationStatus.value = 'Rejected';
      print('❌ Status set to: Rejected (from: $statusValue)');
    } 
    else {
      isVerified.value = false;
      verificationStatus.value = 'Pending';
      print('⚠️ Unknown status: $statusValue, treating as Pending');
    }
  }

  // ⭐ FIXED: Better image URL handling
  void _updateProfileImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      profilePicUrl.value = '';
      print('📷 No profile image available');
      return;
    }
    
    // Remove any leading/trailing whitespace
    imageUrl = imageUrl.trim();
    
    // If already complete URL, use as-is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      profilePicUrl.value = imageUrl;
      print('📷 Using complete URL: ${profilePicUrl.value}');
      return;
    }
    
    // If starts with uploads/, add base URL
    if (imageUrl.startsWith('uploads/')) {
      profilePicUrl.value = 'https://backend.ridealmobility.com/$imageUrl';
      print('📷 Added base URL to uploads path: ${profilePicUrl.value}');
      return;
    }
    
    // Otherwise, it's just a filename - add uploads/ prefix and base URL
    profilePicUrl.value = 'https://backend.ridealmobility.com/uploads/$imageUrl';
    print('📷 Built complete URL from filename: ${profilePicUrl.value}');
  }

  void loadFromStorage() {
    try {
      final storedDriverData = storage.read('driver_data');
      final userData = storage.read('user_data');
      
      Map<String, dynamic>? data = storedDriverData ?? userData;
      
      if (data != null) {
        print('📦 Loading profile from storage');
        
        driverId.value = data['_id']?.toString() ?? 
                        data['id']?.toString() ?? 
                        data['driverId']?.toString() ?? '';
        name.value = data['name']?.toString() ?? '';
        phone.value = data['phone']?.toString() ?? '';
        age.value = data['age']?.toString() ?? '';
        gender.value = data['gender']?.toString() ?? '';
        dl.value = data['dl']?.toString() ?? '';
        aadhaar.value = data['aadhaar']?.toString() ?? '';
        dlImage.value = data['dlImage']?.toString() ?? '';
        aadhaarImage.value = data['aadhaarImage']?.toString() ?? '';
        status.value = data['status']?.toString() ?? 'pending';
        referralCode.value = data['referralCode']?.toString() ?? '';
        
        _updateProfileImageUrl(data['profileImage']?.toString());
        
        if (data['wallet'] != null) {
          if (data['wallet'] is int) {
            wallet.value = (data['wallet'] as int).toDouble();
          } else if (data['wallet'] is double) {
            wallet.value = data['wallet'];
          } else {
            wallet.value = double.tryParse(data['wallet'].toString()) ?? 0.0;
          }
        }
        
        _updateVerificationStatus(status.value);
        
        print('✅ Profile loaded from storage');
        print('👤 Name: ${name.value}');
        print('📞 Phone: ${phone.value}');
        print('🆔 Driver ID: ${driverId.value}');
        print('📷 Profile Image: ${profilePicUrl.value}');
      } else {
        print('⚠️ No profile data in storage');
      }
    } catch (e) {
      print('❌ Error loading from storage: $e');
    }
  }

  String? getToken() {
    final token = storage.read('auth_token');
    print("🔑 Retrieved token: $token");
    return token;
  }

  Map<String, String> getAuthHeaders() {
    final token = getToken();
    if (token == null) {
      throw Exception("⚠️ No auth token available");
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      
      String? id;
      
      final storedDriverData = storage.read('driver_data');
      if (storedDriverData != null) {
        id = storedDriverData['_id']?.toString() ?? 
             storedDriverData['id']?.toString() ?? 
             storedDriverData['driverId']?.toString();
      }
      
      if (id == null || id.isEmpty) {
        final userData = storage.read('user_data');
        if (userData != null) {
          id = userData['_id']?.toString() ?? 
               userData['id']?.toString() ?? 
               userData['driverId']?.toString();
        }
      }
      
      if (id == null || id.isEmpty) {
        id = storage.read('driver_id')?.toString() ?? 
             storage.read('_id')?.toString();
      }
      
      if (id == null || id.isEmpty) {
        id = await StorageHelper.getDriverId();
      }
      
      print('📦 Storage keys: ${storage.getKeys()}');
      print('📦 driver_data: $storedDriverData');
      print('🔍 Looking for driver ID...');
      
      if (id == null || id.isEmpty) {
        print('❌ No driver ID found in any storage location');
        
        final allData = storage.read('driver_data') ?? storage.read('user_data');
        if (allData != null) {
          print('📝 All stored data: $allData');
        }
        
        showErrorSnackBar(
          'Driver ID not found. Please login again.',
          title: 'Error',
        );
        isLoading.value = false;
        return;
      }

      print('🚀 Fetching profile for driver: $id');

      final response = await http.get(
        Uri.parse('$baseUrl/profile/$id'),
        headers: getAuthHeaders(),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          var driver = jsonResponse['driver'];
          
          driverId.value = driver['_id'] ?? '';
          name.value = (driver['name'] ?? '').toString().trim(); // ⭐ Clean name
          phone.value = driver['phone'] ?? '';
          age.value = driver['age']?.toString() ?? '';
          gender.value = driver['gender'] ?? '';
          dl.value = driver['dl'] ?? '';
          aadhaar.value = (driver['aadhaar'] ?? '').toString();
          
          // Safe handling for image fields that might be lists
          dynamic dlImg = driver['dlImage'];
          dlImage.value = (dlImg is List && dlImg.isNotEmpty) ? dlImg.first.toString() : (dlImg?.toString() ?? '');
          
          dynamic aadhaarImg = driver['aadhaarImage'];
          aadhaarImage.value = (aadhaarImg is List && aadhaarImg.isNotEmpty) ? aadhaarImg.first.toString() : (aadhaarImg?.toString() ?? '');
          status.value = driver['status'] ?? 'pending';
          referralCode.value = driver['referralCode'] ?? '';
          wallet.value = (driver['wallet'] ?? 0).toDouble();
          
          // ⭐ Update profile image with fixed method
          _updateProfileImageUrl(driver['profileImage']?.toString());
          
          if (driver['rndId'] != null) {
            rndId.value = driver['rndId'];
            print('✅ RND ID from profile: ${rndId.value}');
          }
          
          _updateVerificationStatus(status.value);
          
          print('✅ Profile loaded successfully from API');
          print('📊 API Status: ${status.value}');
          print('📊 Verification Status: ${verificationStatus.value}');
          print('📊 Is Verified: ${isVerified.value}');
          print('📷 Profile Image: ${profilePicUrl.value}');
          
          storage.write('driver_data', driver);
          storage.write('user_data', driver);
          
          final freshId = driver['_id']?.toString();
          if (freshId != null && freshId.isNotEmpty) {
            storage.write('driver_id', freshId);
            storage.write('_id', freshId);
            await StorageHelper.saveDriverId(freshId);
          }
        }
        
        if (rndId.value.isEmpty) {
          await fetchRndId();
        }
      } else {
        print('❌ Failed to fetch profile: ${response.statusCode}');
        // Get.snackbar(
        //   'Error',
        //   'Failed to load profile from server',
        //   snackPosition: SnackPosition.TOP,
        // );
      }
    } catch (e) {
      print('❌ Exception: $e');
      // Get.snackbar(
      //   'Error',
      //   'Failed to load profile: $e',
      //   snackPosition: SnackPosition.TOP,
      // );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProfileFromAPI() async {
    return fetchProfile();
  }

  Future<void> updateProfile({
    required String name,
    File? profileImage,
  }) async {
    try {
      print('🚀 Updating profile...');
      
      final token = getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      print('🔑 Retrieved token: $token');

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      
      print('📝 Fields: name=$name');

      if (profileImage != null) {
        final path = profileImage.path.toLowerCase();
        String mimeType;
        
        if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (path.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (path.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else if (path.endsWith('.heic')) {
          mimeType = 'image/heic';
        } else if (path.endsWith('.avif')) {
          mimeType = 'image/avif';
        } else {
          mimeType = 'image/jpeg';
        }

        print('📷 Image path: $path');
        print('📷 MIME type: $mimeType');

        final imageFile = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: MediaType.parse(mimeType),
        );
        
        request.files.add(imageFile);
        print('📷 Profile image added to request');
        print('📷 File size: ${await profileImage.length()} bytes');
      }

      print('📤 Sending update request to: ${request.url}');
      print('📤 Headers: ${request.headers}');
      print('📤 Fields: ${request.fields}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['driver'] != null) {
          final driver = jsonResponse['driver'];
          
          // ⭐ Clean name - remove any newlines or extra spaces
          String cleanName = (driver['name'] ?? name).toString().replaceAll('\n', '').trim();
          this.name.value = cleanName;
          
          // ⭐ Use the fixed image URL method
          _updateProfileImageUrl(driver['profileImage']?.toString());
          
          storage.write('driver_data', driver);
        }
        
        print('✅ Profile updated successfully');
        
        // ⭐ Refresh profile after update
        await fetchProfile();
      } else {
        print('❌ Update failed with status: ${response.statusCode}');
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  String get formattedWallet {
    return '₹${wallet.value.toStringAsFixed(2)}';
  }

  String get maskedDL {
    if (dl.value.isEmpty) return 'Not Set';
    if (dl.value.length <= 4) return dl.value;
    return '${dl.value.substring(0, 4)}${'*' * (dl.value.length - 4)}';
  }

  String get maskedAadhaar {
    if (aadhaar.value.isEmpty) return 'Not Set';
    if (aadhaar.value.length <= 8) return aadhaar.value;
    return 'XXXX-XXXX-${aadhaar.value.substring(aadhaar.value.length - 4)}';
  }
  
  String get formattedGender {
    if (gender.value.isEmpty) return 'Not Set';
    return gender.value[0].toUpperCase() + gender.value.substring(1);
  }
  
  bool get hasProfileImage => profilePicUrl.value.isNotEmpty;
  
  Future<void> fetchRndId() async {
    try {
      if (driverId.value.isEmpty) {
        print('❌ Cannot fetch RND ID: Driver ID is empty');
        return;
      }
      
      print('🚀 Fetching RND ID for driver: ${driverId.value}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/${driverId.value}/rnd-id'),
        headers: getAuthHeaders(),
      );
      
      print('📥 RND ID Status: ${response.statusCode}');
      print('📥 RND ID Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          rndId.value = data['data']['rndId'] ?? '';
          print('✅ RND ID fetched: ${rndId.value}');
          
          final storedDriverData = storage.read('driver_data');
          if (storedDriverData != null) {
            storedDriverData['rndId'] = rndId.value;
            storage.write('driver_data', storedDriverData);
          }
        } else {
          print('⚠️ RND ID not found in response');
        }
      } else {
        print('❌ Failed to fetch RND ID: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching RND ID: $e');
    }
  }
}