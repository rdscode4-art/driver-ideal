import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class DocumentsController extends GetxController {
  final storage = GetStorage();
  
  final String baseUrl = 'https://backend.ridealmobility.com/api/non-vehicle-driver';
  
  // Observable variables
  var name = ''.obs;
  var phone = ''.obs;
  var age = ''.obs;
  var gender = ''.obs;
  var dl = ''.obs;
  var aadhaar = ''.obs;
  var dlImage = ''.obs;
  
  // ⭐ CHANGED: Now storing list of Aadhaar images
  var aadhaarImages = <String>[].obs;
  
  var status = ''.obs;
  var rndId = ''.obs;
  
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var isVerified = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDocuments();
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

  Future<void> fetchDocuments() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      print('🚀 Fetching documents...');

      final response = await http.get(
        Uri.parse('$baseUrl/my-documents'),
        headers: getAuthHeaders(),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        
        print('📋 Full API Response: $jsonResponse');
        
        if (jsonResponse['success'] == true) {
          var data = jsonResponse['data'] ?? jsonResponse['driver'] ?? jsonResponse;
          
          print('📋 Data object: $data');
          
          // Update basic info
          name.value = data['name']?.toString() ?? '';
          phone.value = data['phone']?.toString() ?? '';
          age.value = data['age']?.toString() ?? '';
          gender.value = data['gender']?.toString() ?? '';
          rndId.value = data['rndId']?.toString() ?? '';
          status.value = data['status']?.toString() ?? 'pending';
          
          // ⭐ Handle DL Image
          if (data['documents'] != null && data['documents']['dlImage'] != null) {
            dlImage.value = _formatImageUrl(data['documents']['dlImage'].toString());
          } else if (data['dlImage'] != null) {
            dlImage.value = _formatImageUrl(data['dlImage'].toString());
          }
          
          // ⭐ Handle Aadhaar Images (Array)
          aadhaarImages.clear();
          
          if (data['documents'] != null && data['documents']['aadhaarImage'] != null) {
            _processAadhaarImages(data['documents']['aadhaarImage']);
          } else if (data['aadhaarImage'] != null) {
            _processAadhaarImages(data['aadhaarImage']);
          }
          
          // Get DL and Aadhaar numbers
          dl.value = data['dl']?.toString() ?? data['drivingLicense']?.toString() ?? '';
          aadhaar.value = data['aadhaar']?.toString() ?? data['aadhar']?.toString() ?? '';
          
          _updateVerificationStatus(status.value);
          
          print('✅ Documents loaded successfully');
          print('📊 DL: ${dl.value}');
          print('📊 Aadhaar: ${aadhaar.value}');
          print('📊 DL Image: ${dlImage.value}');
          print('📊 Aadhaar Images: ${aadhaarImages.length} images');
          for (int i = 0; i < aadhaarImages.length; i++) {
            print('   📸 Image ${i + 1}: ${aadhaarImages[i]}');
          }
          print('📊 Status: ${status.value}');
          print('📊 Is Verified: ${isVerified.value}');
        } else {
          hasError.value = true;
          errorMessage.value = jsonResponse['message'] ?? 'Failed to load documents';
        }
      } else if (response.statusCode == 401) {
        hasError.value = true;
        errorMessage.value = 'Session expired. Please login again.';
      } else {
        hasError.value = true;
        errorMessage.value = 'Failed to load documents. Please try again.';
        
        print('❌ Failed to fetch documents: ${response.statusCode}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error. Please check your connection.';
      
      print('❌ Exception: $e');
      
      Get.snackbar(
        'Error',
        'Failed to load documents: $e',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ⭐ NEW: Process Aadhaar images (handles both single image and array)
  void _processAadhaarImages(dynamic aadhaarData) {
    if (aadhaarData is List) {
      // Array of images
      print('📦 Aadhaar is array with ${aadhaarData.length} images');
      for (var img in aadhaarData) {
        if (img != null) {
          String formattedUrl = _formatImageUrl(img.toString());
          aadhaarImages.add(formattedUrl);
          print('   ✅ Added: $formattedUrl');
        }
      }
    } else if (aadhaarData is String) {
      // Single image (backward compatibility)
      print('📦 Aadhaar is single image');
      String formattedUrl = _formatImageUrl(aadhaarData);
      aadhaarImages.add(formattedUrl);
      print('   ✅ Added: $formattedUrl');
    }
  }

  void _updateVerificationStatus(String statusValue) {
    final lowerStatus = statusValue.toLowerCase();
    
    if (lowerStatus == 'approved' || lowerStatus == 'verified' || lowerStatus == 'active') {
      isVerified.value = true;
      print('✅ Status set to: Verified (from: $statusValue)');
    } 
    else if (lowerStatus == 'pending' || lowerStatus == 'under_review') {
      isVerified.value = false;
      print('⏳ Status set to: Pending (from: $statusValue)');
    } 
    else if (lowerStatus == 'rejected' || lowerStatus == 'declined') {
      isVerified.value = false;
      print('❌ Status set to: Rejected (from: $statusValue)');
    } 
    else {
      isVerified.value = false;
      print('⚠️ Unknown status: $statusValue, treating as Pending');
    }
  }

  String get maskedDL {
    if (dl.value.isNotEmpty) {
      if (dl.value.length <= 4) return dl.value;
      return '${dl.value.substring(0, 4)}${'*' * (dl.value.length - 4)}';
    } else if (dlImage.value.isNotEmpty) {
      return 'Document Uploaded';
    } else {
      return 'Not Uploaded';
    }
  }

  String get maskedAadhaar {
    if (aadhaar.value.isNotEmpty) {
      if (aadhaar.value.length <= 8) return aadhaar.value;
      return 'XXXX-XXXX-${aadhaar.value.substring(aadhaar.value.length - 4)}';
    } else if (aadhaarImages.isNotEmpty) {
      return '${aadhaarImages.length} Document(s) Uploaded';
    } else {
      return 'Not Uploaded';
    }
  }

  String _formatImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    
    print('🔄 Formatting URL: $imageUrl');
    
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('✅ Already full URL: $imageUrl');
      return imageUrl;
    }
    
    String cleanUrl = imageUrl;
    if (cleanUrl.contains('/www/wwwroot/Backendrid')) {
      cleanUrl = cleanUrl.replaceAll('/www/wwwroot/Backendrid', '');
      print('🧹 After removing server path: $cleanUrl');
    }
    
    if (!cleanUrl.startsWith('/')) {
      cleanUrl = '/$cleanUrl';
    }
    
    final formattedUrl = 'https://backend.ridealmobility.com$cleanUrl';
    print('✅ Final formatted URL: $formattedUrl');
    return formattedUrl;
  }
}