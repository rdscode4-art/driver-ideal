// lib/controllers/vehicle_type_controller.dart
import 'package:get/get.dart';
import 'package:rideal_driver/core/services/fare_api_service.dart';

class VehicleTypeController extends GetxController {
  // Observable list of vehicle types
  var vehicleTypes = <String>[].obs;
  var fareRates = <String, dynamic>{}.obs;
  var vehicleImages = <String, dynamic>{}.obs;
  
  // Loading states
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Default fallback vehicle types
  final List<String> defaultVehicleTypes = [
    'sedan',
    'suv',
    'auto',
    'bike',
    'ev',
    'hatchback',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchVehicleTypes();
  }

  /// Fetch vehicle types from API
  Future<void> fetchVehicleTypes() async {
    try {
      print('🔄 Fetching vehicle types...');
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await FareApiService.getFareRates();

      if (response['success'] == true) {
        fareRates.value = response['fareRates'] as Map<String, dynamic>;
        vehicleImages.value = response['vehicleImages'] as Map<String, dynamic>;
        
        // Extract vehicle type keys
        final types = fareRates.keys.toList();
        
        if (types.isNotEmpty) {
          vehicleTypes.value = types;
          print('✅ Loaded ${types.length} vehicle types: $types');
        } else {
          // Use defaults if API returns empty
          vehicleTypes.value = defaultVehicleTypes;
          print('⚠️ API returned no types, using defaults');
        }
      } else {
        hasError.value = true;
        errorMessage.value = response['message'] ?? 'Failed to load vehicle types';
        vehicleTypes.value = defaultVehicleTypes;
        print('❌ Failed to fetch vehicle types, using defaults');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error: $e';
      vehicleTypes.value = defaultVehicleTypes;
      print('💥 Exception in fetchVehicleTypes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh vehicle types
  Future<void> refreshVehicleTypes() async {
    await fetchVehicleTypes();
  }

  /// Get display name for vehicle type
  String getDisplayName(String type) {
    return FareApiService.getVehicleTypeDisplayName(type);
  }

  /// Get fare rate for vehicle type
  Map<String, dynamic>? getFareRate(String type) {
    return fareRates[type.toLowerCase()] as Map<String, dynamic>?;
  }

  /// Get vehicle image URL
  String? getVehicleImage(String type) {
    final imagePath = vehicleImages[type.toLowerCase()];
    if (imagePath != null && imagePath.toString().isNotEmpty) {
      return 'https://backend.ridealmobility.com$imagePath';
    }
    return null;
  }

  /// Check if vehicle type exists
  bool hasVehicleType(String type) {
    return vehicleTypes.contains(type.toLowerCase());
  }

  /// Get all vehicle types with display names
  Map<String, String> getVehicleTypesWithDisplayNames() {
    final Map<String, String> result = {};
    for (final type in vehicleTypes) {
      result[type] = getDisplayName(type);
    }
    return result;
  }
}