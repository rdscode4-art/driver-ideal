import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/driver_api_service.dart';
import '../data/models/driver_profile.dart';
import '../core/storage_helper.dart';
import 'package:http/http.dart'as http;
import 'package:http/http.dart'as http_parser;
import 'package:rideal_driver/nonvehichle/non_vehichle_auth_service.dart';
import '../core/utils/app_snackbar.dart';

class ProfileController extends GetxController {
  var walletBalance = 0.0.obs;
  // Profile data using the new model
  var driverProfile = Rx<DriverProfile?>(null);
  var isLoading = false.obs;
  var isUpdating = false.obs;
  var rndId = ''.obs; // 🆕 Added for non-vehicle drivers

  // Convenience getters for UI
  String get ridealid => rndId.value.isNotEmpty ? rndId.value : (driverProfile.value?.ridealid ?? '');
  String get name => driverProfile.value?.displayName ?? 'Driver';
  String get phone => driverProfile.value?.formattedPhone ?? '';
  String get email => ''; // Can be added to model later if needed
  bool get isVerified => driverProfile.value?.isVerified ?? false;
  bool get isAvailable => driverProfile.value?.isAvailable ?? false;
  String get memberSince => driverProfile.value?.memberSince ?? '';
  String get verificationStatus => driverProfile.value?.verificationStatus ?? 'Pending';

  // Legacy properties for backward compatibility
  var profilePicUrl = ''.obs;
  var carNumber = ''.obs;
  var carModel = ''.obs;
  var licenseNumber = ''.obs;
  var emergencyContact = ''.obs;
  var carColor = ''.obs;
  var carType = ''.obs;
  var address = 'New Delhi, India'.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    fetchWalletBalance();
  }

  Future<void> refreshWalletBalance() async {
    await fetchWalletBalance();
  }

  // 🚗 Update Vehicle Details
  Future<bool> updateVehicleDetails({
    String? vehicleName,
    String? vehicleNumber,
    String? vehicleType,
  }) async {
    try {
      isUpdating.value = true;

      final Map<String, dynamic> updateData = {};

      if (vehicleName != null && vehicleName.isNotEmpty) {
        updateData['vehicleName'] = vehicleName;
      }
      if (vehicleNumber != null && vehicleNumber.isNotEmpty) {
        updateData['vehicleNumber'] = vehicleNumber;
      }
      if (vehicleType != null && vehicleType.isNotEmpty) {
        updateData['vehicleType'] = vehicleType;
      }

      if (updateData.isEmpty) {
        showWarningSnackBar(
          'Please enter at least one vehicle detail to update.',
          title: 'Validation Error',
        );
        return false;
      }

      print('🔄 Updating vehicle details: $updateData');

      final response = await DriverApiService.updateDriverProfile(updateData);

      if (response.isSuccess && response.data != null) {
        if (response.data!['success'] == true && response.data!['driver'] != null) {
          final updatedDriverData = response.data!['driver'];
          driverProfile.value = DriverProfile.fromJson(updatedDriverData);

          // 🔁 Update reactive fields for UI
          _updateVehicleFields();
          _updateProfileImageUrl();

          // 🔁 Save to local storage
          await saveProfileToStorage(driverProfile.value!);

          showSuccessSnackBar(
            'Vehicle details updated successfully',
            title: 'Success',
          );

          print('✅ Vehicle details updated successfully');
          return true;
        } else {
          print('❌ Unexpected API format');
          return false;
        }
      } else {
        print('❌ Failed to update vehicle details: ${response.message}');
        showErrorSnackBar(
          response.message ?? 'Failed to update vehicle details',
          title: 'Error',
        );
        return false;
      }
    } catch (e) {
      print('💥 Exception updating vehicle details: $e');
      showErrorSnackBar(
        'Something went wrong while updating vehicle details.',
        title: 'Error',
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateVehicleName(String newVehicleName) async {
    return await updateVehicleDetails(vehicleName: newVehicleName);
  }

  Future<bool> updateVehicleNumber(String newVehicleNumber) async {
    return await updateVehicleDetails(vehicleNumber: newVehicleNumber);
  }

  Future<bool> updateVehicleColor(String newVehicleColor) async {
    return await updateVehicleDetails(vehicleType: newVehicleColor);
  }

  // 🆕 Helper method to update profile image URL - FIXED FOR HTTP + UPLOADS PATH
  void _updateProfileImageUrl() {
    final imageUrl = driverProfile.value?.profileImage ?? '';
    
    print('📷 ========== IMAGE URL CONSTRUCTION ==========');
    print('   Raw URL from profile: $imageUrl');
    
    if (imageUrl.isNotEmpty) {
      String fullImageUrl;
      
      // Check if it's already a full URL
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        fullImageUrl = imageUrl;
        print('   Already full URL: $fullImageUrl');
      } 
      // Check if it already has /uploads/ prefix
      else if (imageUrl.startsWith('/uploads/') || imageUrl.startsWith('uploads/')) {
        fullImageUrl = 'https://backend.ridealmobility.com/$imageUrl';
        print('   Has uploads prefix: $fullImageUrl');
      }
      // Otherwise prepend base URL + /uploads/
      else {
        fullImageUrl = 'https://backend.ridealmobility.com/uploads/$imageUrl';
        print('   Added uploads path: $fullImageUrl');
      }
      
      profilePicUrl.value = fullImageUrl;
      print('📷 Final profile image URL: ${profilePicUrl.value}');
    } else {
      profilePicUrl.value = '';
      print('📷 No profile image available');
    }
    
    print('========================================\n');
  }

  // Helper method to update vehicle fields from profile
  void _updateVehicleFields() {
    carModel.value = driverProfile.value?.verification?.vehicleName ?? '';
    carNumber.value = driverProfile.value?.verification?.vehicleNumber ?? '';
    carColor.value = driverProfile.value?.verification?.vehicleType ?? '';
    
    print('🚗 Vehicle fields updated:');
    print('   Model: ${carModel.value}');
    print('   Number: ${carNumber.value}');
    print('   Color/Type: ${carColor.value}');
  }

  // Load profile data from API and local storage
  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      
      // First try to load from local storage for immediate display
      await loadProfileFromStorage();

      // Check if non-vehicle driver (skip regular driver API)
      final role = await StorageHelper.getUserRole();
      if (role == 'non-vehicle-driver') {
        print('ℹ️ ProfileController: Non-vehicle driver detected, fetching specific profile');
        await fetchNonVehicleProfile();
        return;
      }

      // Then fetch fresh data from API (for regular drivers)
      await fetchProfileFromAPI();

    } catch (e) {
      print('Failed to load profile: $e');
      showErrorSnackBar(
        'Failed to load profile data',
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      // 🛡️ SECURITY: Check if non-vehicle driver
      final role = await StorageHelper.getUserRole();
      if (role == 'non-vehicle-driver') {
        print('ℹ️ ProfileController: Non-vehicle driver detected, skipping wallet API');
        return;
      }

      print('\n💰 ========== FETCHING WALLET BALANCE ==========');
      
      final response = await DriverApiService.getDriverWallet();
      
      print('📊 API Response Details:');
      print('   isSuccess: ${response.isSuccess}');
      print('   message: ${response.message}');
      print('   data: ${response.data}');
      print('   statusCode: ${response.statusCode}');
      
      if (response.isSuccess && response.data != null) {
        print('✅ API call successful!');
        print('📦 Full Response Data: ${response.data}');
        
        // Try to parse balance from different structures
        double balance = 0.0;
        bool balanceFound = false;
        
        // Check Option 1: Direct balance
        if (response.data!.containsKey('wallet')) {
          print('🔍 Found direct balance key');
          balance = (response.data!['wallet'] ?? 0.0).toDouble();
          balanceFound = true;
          print('   Balance value: $balance');
        }
        
        // Check Option 2: wallet.balance
        if (!balanceFound && response.data!.containsKey('wallet')) {
          print('🔍 Found wallet object');
          final wallet = response.data!['wallet'];
          print('   Wallet data: $wallet');
          
          if (wallet is Map && wallet.containsKey('balance')) {
            balance = (wallet['balance'] ?? 0.0).toDouble();
            balanceFound = true;
            print('   Balance in wallet: $balance');
          }
        }
        
        // Check Option 3: data.balance
        if (!balanceFound && response.data!.containsKey('data')) {
          print('🔍 Found data object');
          final data = response.data!['data'];
          print('   Data content: $data');
          
          if (data is Map && data.containsKey('wallet')) {
            balance = (response.data!['wallet'] ?? 0.0).toDouble();
            balanceFound = true;
            print('   Balance in data: $balance');
          }
        }
        
        // Check Option 4: amount/total/currentBalance
        if (!balanceFound) {
          print('🔍 Checking alternative keys...');
          final keys = ['amount', 'total', 'currentBalance', 'walletBalance'];
          for (final key in keys) {
            if (response.data!.containsKey(key)) {
              print('   Found key: $key');
              balance = (response.data![key] ?? 0.0).toDouble();
              balanceFound = true;
              break;
            }
          }
        }
        
        if (balanceFound) {
          walletBalance.value = balance;
          print('✅✅ Wallet balance set to: ₹${walletBalance.value}');
        } else {
          print('❌ No balance found in response!');
          print('   Available keys: ${response.data!.keys.toList()}');
          walletBalance.value = 0.0;
        }
        
      } else {
        print('❌ API call failed!');
        print('   Error message: ${response.message}');
        print('   Status code: ${response.statusCode}');
        walletBalance.value = 0.0;
      }
      
      print('🏁 ========== WALLET FETCH COMPLETE ==========\n');
      
    } catch (e, stackTrace) {
      print('💥 Exception fetching wallet balance!');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      walletBalance.value = 0.0;
    }
  }

  // Load profile from local storage
  Future<void> loadProfileFromStorage() async {
    try {
      final profileData = await StorageHelper.getDriverProfile();
      if (profileData != null && profileData.isNotEmpty) {
        driverProfile.value = DriverProfile.fromJson(profileData);
        
        // Update vehicle fields and profile image from loaded profile
        _updateVehicleFields();
        _updateProfileImageUrl();
        
        print('✅ Profile loaded from local storage: ${driverProfile.value?.name}');
      }
    } catch (e) {
      print('❌ Failed to load profile from storage: $e');
    }
  }

  // Fetch profile from API
  Future<void> fetchProfileFromAPI() async {
    try {
      print('🔄 Fetching driver profile from API...');

      final response = await DriverApiService.getDriverProfile();

      if (response.isSuccess && response.data != null) {
        print('📦 Raw API Response: ${response.data}');
        
        // ✅ FIX: Extract the 'driver' object from the response
        final driverData = response.data!['driver'] ?? response.data!;
        
        // Parse the profile data from the driver object
        final profileData = DriverProfile.fromJson(driverData);
        driverProfile.value = profileData;
        
        // Update vehicle fields and profile image
        _updateVehicleFields();
        _updateProfileImageUrl();

        // Save to local storage
        await saveProfileToStorage(profileData);

        print('✅ Driver profile loaded successfully: ${profileData.name}');
      } else {
        print('❌ Failed to load driver profile: ${response.message}');

        // Only show error if we don't have cached data and it's not an auth error
        if (driverProfile.value == null && 
            response.message != 'Authentication required. Please login again.') {
          showErrorSnackBar(
            response.message ?? 'Failed to load profile',
            title: 'Error',
          );
        }
      }
    } catch (e) {
      print('❌ Exception loading driver profile: $e');

      // Only show error if we don't have cached data
      if (driverProfile.value == null) {
        showErrorSnackBar(
          'Please check your internet connection',
          title: 'Network Error',
        );
      }
    }
  }

  // Save profile to local storage
  Future<void> saveProfileToStorage(DriverProfile profile) async {
    try {
      await StorageHelper.saveDriverProfile(profile.toJson());
      print('✅ Profile saved to local storage');
    } catch (e) {
      print('❌ Failed to save profile to storage: $e');
    }
  }

  // Fetch non-vehicle profile from API
  Future<void> fetchNonVehicleProfile() async {
    try {
      final token = await StorageHelper.getAuthToken();
      final driverId = await StorageHelper.getDriverId();
      
      if (token == null || driverId == null) return;

      final url = 'https://backend.ridealmobility.com/api/non-vehicle-driver/profile/$driverId';
      print('🔄 Fetching non-vehicle profile from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final driverData = data['driver'] ?? data;
        
        driverProfile.value = DriverProfile.fromJson(driverData);
        _updateProfileImageUrl();
        
        // 🆕 Fetch RND ID for non-vehicle drivers
        if (driverData['rndId'] != null) {
          rndId.value = driverData['rndId'].toString();
        } else {
          await fetchRndId(driverId);
        }
        
        await saveProfileToStorage(driverProfile.value!);
        print('✅ Non-vehicle profile loaded successfully');
      }
    } catch (e) {
      print('❌ Error fetching non-vehicle profile: $e');
    }
  }

  // 🆕 Fetch RND ID for non-vehicle drivers
  Future<void> fetchRndId(String driverId) async {
    try {
      final token = await StorageHelper.getAuthToken();
      if (token == null) return;

      final url = 'https://backend.ridealmobility.com/api/non-vehicle-driver/$driverId/rnd-id';
      print('🔄 Fetching RND ID from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          rndId.value = data['data']['rndId'] ?? '';
          print('✅ RND ID fetched: ${rndId.value}');
        }
      }
    } catch (e) {
      print('❌ Error fetching RND ID: $e');
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    final role = await StorageHelper.getUserRole();
    if (role == 'non-vehicle-driver') {
      await fetchNonVehicleProfile();
    } else {
      await fetchProfileFromAPI();
    }
  }

  // Clear profile data (for logout)
  Future<void> clearProfile() async {
    try {
      driverProfile.value = null;
      carModel.value = '';
      carNumber.value = '';
      carColor.value = '';
      profilePicUrl.value = '';
      await StorageHelper.clearDriverProfile();
      print('✅ Profile data cleared');
    } catch (e) {
      print('❌ Failed to clear profile: $e');
    }
  }

  // Update profile method for the /auth/driver-profile PUT API
  Future<bool> updateDriverProfile({
    String? name,
    String? phone,
  }) async {
    try {
      isUpdating.value = true;

      Map<String, dynamic> updateData = {};
      
      if (name != null && name.isNotEmpty) updateData['name'] = name;
      if (phone != null && phone.isNotEmpty) updateData['phone'] = phone;

      if (updateData.isEmpty) {
        showWarningSnackBar(
          'Please provide name or phone to update',
          title: 'Validation Error',
        );
        return false;
      }

      print('🔄 Updating profile with data: $updateData');

      final response = await DriverApiService.updateDriverProfile(updateData);

      if (response.isSuccess && response.data != null) {
        if (response.data!['success'] == true && response.data!['driver'] != null) {
          final updatedDriverData = response.data!['driver'];
          driverProfile.value = DriverProfile.fromJson(updatedDriverData);

          // Update vehicle fields and profile image
          _updateVehicleFields();
          _updateProfileImageUrl();

          // Save updated profile to local storage
          await saveProfileToStorage(driverProfile.value!);

          // ✅ Refresh profile to ensure all state is perfectly in sync
          final role = await StorageHelper.getUserRole();
          if (role == 'non-vehicle-driver') {
            await fetchNonVehicleProfile();
          } else {
            await fetchProfileFromAPI();
          }

          print('✅ Profile updated successfully: ${driverProfile.value?.name}');
          return true;
        } else {
          print('❌ API returned success but with unexpected format');
          return false;
        }
      } else {
        print('❌ Failed to update profile: ${response.message}');
        return false;
      }
    } catch (e) {
      print('💥 Exception updating profile: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Wrapper method for backward compatibility - FIXED FOR HTTP
Future<bool> updateProfile({
  required String name,
  File? profileImage,
}) async {
  try {
    isUpdating.value = true;
    
    print('🔄 ========== UPDATING PROFILE ==========');
    print('📝 Name: $name');
    print('📷 Has Image: ${profileImage != null}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      print('🚨 No auth token found. Skipping profile load.');
      return false;
    }

    // Determine correct endpoint based on role
    final role = await StorageHelper.getUserRole();
    final bool isNonVehicle = role == 'non-vehicle-driver';
    
    final String endpoint = isNonVehicle 
        ? 'https://backend.ridealmobility.com/api/non-vehicle-driver/profile'
        : 'https://backend.ridealmobility.com/auth/driver-profile';
    
    print('🚀 Using endpoint: $endpoint (Role: $role)');

    // Create multipart request for image upload
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse(endpoint),
    );

    // Add authorization header
    request.headers['Authorization'] = 'Bearer $token';
    print('🔑 Token added to request');

    // Add name field
    request.fields['name'] = name;
    print('✅ Name field added: $name');

    // Add profile image if selected
    if (profileImage != null) {
      try {
        // Determine MIME type based on file extension
        String mimeType = 'image/jpeg'; // default
        String filePath = profileImage.path.toLowerCase();
        
        if (filePath.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (filePath.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else if (filePath.endsWith('.heic')) {
          mimeType = 'image/heic';
        }
        
        print('📸 Image MIME type: $mimeType');
        
        var imageFile = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: http_parser.MediaType.parse(mimeType),
        );
        request.files.add(imageFile);
        print('✅ Profile image added: ${profileImage.path}');
      } catch (e) {
        print('❌ Failed to add image: $e');
      }
    }

    print('📤 Sending request...');
    
    // Send request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('📥 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      print('✅ Profile update successful!');
      print('📊 Response data: $data');

      // Update profile based on API response structure
      if (data['success'] == true) {
        // Extract driver data
        final driverData = data['driver'] ?? data['data'] ?? {};
        
        // 🎯 CRITICAL FIX: Preserve existing data and merge with new data
        if (driverData.isNotEmpty) {
          // Store the COMPLETE previous profile to preserve verification data
          final previousProfile = driverProfile.value;
          
          print('🔍 ========== BEFORE UPDATE ==========');
          print('   Previous Verified: ${previousProfile?.isVerified}');
          print('   Previous Status: ${previousProfile?.verificationStatus}');
          print('   Previous Verification Data: ${previousProfile?.verification}');
          
          // Create a merged data object that preserves verification status
          final mergedData = Map<String, dynamic>.from(driverData);
          
          // ✅ FORCE PRESERVE verification status from previous profile
          if (previousProfile != null) {
            // If server doesn't send verification data, use previous data
            if (!mergedData.containsKey('verification') && previousProfile.verification != null) {
              mergedData['verification'] = previousProfile.toJson()['verification'];
              print('✅ Preserved verification data from previous profile');
            }
            
            // If server doesn't send isVerified, use previous value
            if (!mergedData.containsKey('isVerified')) {
              mergedData['isVerified'] = previousProfile.isVerified;
              print('✅ Preserved isVerified from previous profile');
            }
          }
          
          // Update with merged data
          driverProfile.value = DriverProfile.fromJson(mergedData);
          
          print('🔍 ========== AFTER UPDATE ==========');
          print('   Updated Name: ${driverProfile.value?.name}');
          print('   Updated Phone: ${driverProfile.value?.phone}');
          print('   Updated Verified: ${driverProfile.value?.isVerified}');
          print('   Updated Status: ${driverProfile.value?.verificationStatus}');
          print('   Updated Verification Data: ${driverProfile.value?.verification}');
          
          // 📷 Update profile image URL with the NEW image from server response
          // ✅ FIXED FOR HTTP + UPLOADS PATH
          final newImageUrl = driverData['profileImage'] ?? '';
          
          print('📷 ========== IMAGE URL CONSTRUCTION ==========');
          print('   Raw URL from API: $newImageUrl');
          
          if (newImageUrl.isNotEmpty) {
            String fullImageUrl;
            
            // Check if it's already a full URL
            if (newImageUrl.startsWith('http://') || newImageUrl.startsWith('https://')) {
              fullImageUrl = newImageUrl;
            } else if (newImageUrl.startsWith('uploads/') || newImageUrl.startsWith('/uploads/')) {
              fullImageUrl = 'https://backend.ridealmobility.com/$newImageUrl';
            } else {
              fullImageUrl = 'https://backend.ridealmobility.com/uploads/$newImageUrl';
            }
            profilePicUrl.value = fullImageUrl;
            profilePicUrl.refresh();
          } else {
            print('⚠️ No profile image in response');
          }
        }
        
        // Update vehicle fields
        _updateVehicleFields();
        
        // 💾 Save COMPLETE profile to local storage
        if (driverProfile.value != null) {
          await saveProfileToStorage(driverProfile.value!);
          print('💾 Profile saved to local storage with verification data');
        }

        print('🎉 Profile update completed successfully!');
        print('   Final Verification Status: ${driverProfile.value?.verificationStatus}');
        print('   Final Image URL: ${profilePicUrl.value}');
        
        // ✅ Force refresh of all observables
        driverProfile.refresh();
        profilePicUrl.refresh();
        
        return true;
      } else {
        print('⚠️ API returned success: false');
        showErrorSnackBar(
          data['message'] ?? 'Failed to update profile',
          title: 'Error',
        );
        return false;
      }
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
      
      try {
        final data = json.decode(response.body);
        showErrorSnackBar(
          data['message'] ?? 'Failed to update profile',
          title: 'Error',
        );
      } catch (e) {
        showErrorSnackBar(
          'Server error: ${response.statusCode}',
          title: 'Error',
        );
      }
      return false;
    }
  } catch (e, stackTrace) {
    print('💥 Exception updating profile: $e');
    print('📍 Stack trace: $stackTrace');
    
    showErrorSnackBar(
      'Failed to update profile: ${e.toString()}',
      title: 'Error',
    );
    return false;
  } finally {
    isUpdating.value = false;
    print('🏁 ========== PROFILE UPDATE COMPLETE ==========\n');
  }
}

  // Update profile picture method
  Future<bool> updateProfilePicture(dynamic imageSource) async {
    try {
      isLoading.value = true;

      if (imageSource is String) {
        profilePicUrl.value = imageSource;
        return true;
      } else if (imageSource is File) {
        final response = await DriverApiService.uploadDocument(
          'profile_picture',
          imageSource,
        );

        if (response.isSuccess && response.data != null) {
          profilePicUrl.value = response.data!['url'] ?? '';

          showSuccessSnackBar(
            'Profile picture updated successfully',
            title: 'Success',
          );

          return true;
        } else {
          showErrorSnackBar(
            response.message ?? 'Failed to upload profile picture',
            title: 'Error',
          );
          return false;
        }
      }
      return false;
    } catch (e) {
      showErrorSnackBar(
        'Failed to update profile picture: ${e.toString()}',
        title: 'Error',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Convenience methods for individual field updates
  Future<bool> updateName(String newName) async {
    return await updateProfile(name: newName);
  }

  void updateProfilePicUrl(String url) {
    profilePicUrl.value = url;
  }
}