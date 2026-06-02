import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/storage_helper.dart';
import '../services/api_service.dart';

/// Dynamic Token Manager - Handles token lifecycle and automatic updates
/// Ensures current token is always used for API calls
class TokenManager extends GetxController {
  static TokenManager? _instance;

  // Add GetStorage instance
  final _storage = GetStorage();
  final phone = ''.obs;
  final email = ''.obs;
  final name = ''.obs;
  final Rx<String?> userRole = Rx<String?>(null);
  final Rx<String?> userId = Rx<String?>(null); // ⭐ ADDED: User/Driver ID

  // Reactive token state - Make it public for ApiService access
  final Rx<String?> authToken = Rx<String?>(null);
  var isTokenValid = false.obs;
  var tokenExpiry = Rxn<DateTime>();
  var lastTokenUpdate = Rxn<DateTime>();

  // Singleton pattern to ensure one instance across app
  static TokenManager get instance {
    _instance ??= Get.put(TokenManager(), permanent: true);
    return _instance!;
  }

  // Public getter for easy access (used by ApiService)
  String? get token => authToken.value;

  // ⭐ ADDED: Getter for user ID
  String? get userIdValue => userId.value;
  String? get driverId => userId.value;

  // Check if logged in with expiry validation
  bool get isLoggedIn =>
      authToken.value != null &&
      authToken.value!.isNotEmpty &&
      _isTokenNotExpired();

  bool get isDriver => userRole.value == 'driver';
  bool get isNonVehicleDriver => userRole.value == 'non-vehicle-driver';

  @override
  void onInit() {
    super.onInit();
    print('🔐 TokenManager initialized');
    _loadStoredToken();
  }

  /// Load token from storage on app start
  /// Load token from storage on app start
  Future<void> _loadStoredToken() async {
    try {
      // Try GetStorage first
      String? token = _storage.read('auth_token');
      String? role = _storage.read('user_role');
      String? id = _storage.read('user_id'); // ⭐ LOAD USER ID

      // Fallback to SharedPreferences
      if (token == null || token.isEmpty) {
        token = await StorageHelper.getAuthToken();
        role = await StorageHelper.getUserRole();
        id = await StorageHelper.getDriverId(); // ⭐ LOAD FROM STORAGE HELPER
      }

      if (token != null && token.isNotEmpty) {
        // ✅ Validate token expiry before using
        final expiry = _extractTokenExpiry(token);

        if (expiry != null && DateTime.now().isAfter(expiry)) {
          print('⚠️ Token expired at $expiry - Clearing...');
          await clearToken();
          return;
        }

        authToken.value = token;
        userRole.value = role;
        userId.value = id; // ⭐ SET USER ID
        tokenExpiry.value = expiry;
        isTokenValid.value = true;

        // Sync both storages
        _storage.write('auth_token', token);
        _storage.write('user_role', role);
        if (id != null) {
          _storage.write('user_id', id); // ⭐ SAVE TO GET_STORAGE
        }

        await StorageHelper.saveAuthToken(token);
        await StorageHelper.saveUserRole(role ?? 'driver');
        if (id != null) {
          await StorageHelper.saveDriverId(id); // ⭐ SAVE TO SHARED_PREFS
        }

        print('✅ Token loaded: ${_maskToken(token)}');
        print('✅ User role: $role');
        print('✅ User ID: $id'); // ⭐ LOG USER ID

        // ⭐⭐⭐ CRITICAL FIX: Auto-extract user ID if missing ⭐⭐⭐
        if (id == null && token.isNotEmpty) {
          print('⚠️ User ID not found in storage - Extracting from token...');
          await extractAndSaveUserId();
          print('✅ User ID after extraction: ${userId.value}');
        }

        if (expiry != null) {
          final remaining = expiry.difference(DateTime.now());
          print(
            '🕒 Token valid for: ${remaining.inHours}h ${remaining.inMinutes % 60}m',
          );
        }
      } else {
        print('⚠️ No token found in storage');
        _clearTokenState();
      }
    } catch (e) {
      print('❌ Error loading token: $e');
      _clearTokenState();
    }
  }


  /// Update token when user registers or logs in
  Future<void> updateToken(
    String newToken, {
    Map<String, dynamic>? userData,
  }) async {
    try {
      print('🔄 Updating token: ${_maskToken(newToken)}');

      // ✅ Extract and validate expiry immediately
      final expiry = _extractTokenExpiry(newToken);
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        print('❌ New token is already expired!');
        throw Exception('Received expired token from backend');
      }

      // Extract role and ID from token or userData
      String? role;
      String? id; // ⭐ EXTRACT USER ID

      if (userData != null) {
        role = userData['role']?.toString();

        // ⭐ EXTRACT USER ID FROM MULTIPLE POSSIBLE FIELDS
        id =
            userData['_id']?.toString() ??
            userData['id']?.toString() ??
            userData['driverId']?.toString() ??
            userData['userId']?.toString();

        print('🆔 Extracted User ID from userData: $id');
      }

      // If role/id not in userData, try to decode from JWT
      try {
        final parts = newToken.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );

          role ??= payload['role']?.toString();

          // ⭐ EXTRACT ID FROM JWT TOKEN
          if (id == null) {
            id =
                payload['id']?.toString() ??
                payload['_id']?.toString() ??
                payload['userId']?.toString() ??
                payload['driverId']?.toString();

            print('🆔 Extracted User ID from JWT: $id');
          }
        }
      } catch (e) {
        print('⚠️ Could not decode role/id from token: $e');
      }

      role ??= 'driver'; // Default role

      print('✅ Detected role: $role');
      print('✅ Detected user ID: $id'); // ⭐ LOG USER ID

      if (expiry != null) {
        print('🕒 Token expires at: $expiry');
        final remaining = expiry.difference(DateTime.now());
        print(
          '🕒 Valid for: ${remaining.inDays} days, ${remaining.inHours % 24}h',
        );
      }

      // Save to both storages
      _storage.write('auth_token', newToken);
      _storage.write('user_role', role);
      if (id != null) {
        _storage.write('user_id', id); // ⭐ SAVE USER ID TO GET_STORAGE
      }

      await StorageHelper.saveAuthToken(newToken);
      await StorageHelper.saveUserRole(role);
      await StorageHelper.setLoggedIn(true);

      if (id != null) {
        await StorageHelper.saveDriverId(id); // ⭐ SAVE USER ID TO SHARED_PREFS
        print('✅ User ID saved to both storages: $id');
      }

      // Save user data if provided
      if (userData != null) {
        _storage.write('user_data', userData);
        await StorageHelper.saveUserData(jsonEncode(userData));
      }

      // Update reactive state
      authToken.value = newToken;
      userRole.value = role;
      userId.value = id; // ⭐ SET USER ID IN REACTIVE STATE
      tokenExpiry.value = expiry;
      isTokenValid.value = true;
      lastTokenUpdate.value = DateTime.now();

      print('✅ Token updated successfully');
      print('   Role: $role');
      print('   User ID: $id'); // ⭐ LOG USER ID

      _notifyTokenUpdate();
    } catch (e) {
      print('❌ Error updating token: $e');
      throw Exception('Failed to update token: $e');
    }
  }

  /// Save token (simple wrapper for compatibility)
  Future<void> saveToken(String token) async {
    await updateToken(token);
  }

  /// Get current valid token for API calls
  Future<String?> getCurrentToken() async {
    try {
      // ✅ Check expiry before returning token
      if (authToken.value != null && isTokenValid.value) {
        if (!_isTokenNotExpired()) {
          print('⚠️ Token expired - Clearing');
          await clearToken();
          return null;
        }
        return authToken.value;
      }

      // Fallback to storage
      final token = await StorageHelper.getAuthToken();
      if (token != null && token.isNotEmpty) {
        final expiry = _extractTokenExpiry(token);

        if (expiry != null && DateTime.now().isAfter(expiry)) {
          print('⚠️ Stored token expired - Clearing');
          await clearToken();
          return null;
        }

        authToken.value = token;
        tokenExpiry.value = expiry;
        isTokenValid.value = true;
        return token;
      }

      print('⚠️ No valid token available');
      return null;
    } catch (e) {
      print('❌ Error getting current token: $e');
      return null;
    }
  }

  /// Check if token is available and valid (with expiry check)
  bool hasValidToken() {
    return authToken.value != null &&
        authToken.value!.isNotEmpty &&
        isTokenValid.value &&
        _isTokenNotExpired();
  }

  /// ✅ Check if token is not expired
  bool _isTokenNotExpired() {
    if (tokenExpiry.value == null) {
      // Try to extract expiry if not set
      if (authToken.value != null) {
        tokenExpiry.value = _extractTokenExpiry(authToken.value!);
      }
    }

    if (tokenExpiry.value == null) {
      return true; // Assume valid if can't determine expiry
    }

    final now = DateTime.now();
    const buffer = Duration(minutes: 5); // 5 min buffer

    return tokenExpiry.value!.isAfter(now.add(buffer));
  }

  /// ✅ Extract expiry from JWT token
  DateTime? _extractTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode payload
      String payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(payload));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;

      final exp = payloadMap['exp'];
      if (exp == null) return null;

      // Convert Unix timestamp (seconds) to DateTime
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      return expiryDate;
    } catch (e) {
      print('❌ Error extracting token expiry: $e');
      return null;
    }
  }

  /// Clear token when user logs out or token becomes invalid
  Future<void> clearToken() async {
    try {
      print('🗑️ Clearing token for role: ${userRole.value}');

      // Clear from both storages
      _storage.remove('auth_token');
      _storage.remove('user_role');
      _storage.remove('user_id'); // ⭐ CLEAR USER ID
      _storage.remove('user_data');
      _storage.remove('driver_data');
      _storage.remove('is_non_vehicle_driver');

      await StorageHelper.clearAuthToken();
      await StorageHelper.clearUserRole();
      await StorageHelper.setLoggedIn(false);
      await StorageHelper.clearUserData();
      await StorageHelper.clearDriverId(); // ⭐ CLEAR USER ID
      await StorageHelper.clearDriverProfile();
      await StorageHelper.clearDriverStatus();
      
      _storage.remove('driver_status');

      // Clear reactive state
      _clearTokenState();

      print('✅ Token and role cleared successfully');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }

  /// Handle token expiry or invalid token
  Future<void> handleInvalidToken() async {
    print('🚫 Handling invalid token');
    isTokenValid.value = false;

    // Clear all auth data
    await clearToken();

    // Navigate to login
    Get.offAllNamed('/login');

    // Show message to user
    // Get.snackbar(
    //   'Session Expired',
    //   'Please login again to continue',
    //   snackPosition: SnackPosition.TOP,
    //   backgroundColor: Get.theme.colorScheme.error,
    //   colorText: Get.theme.colorScheme.onError,
    //   duration: const Duration(seconds: 3),
    // );
  }

  /// Refresh token from storage (useful after external updates)
  Future<void> refreshTokenFromStorage() async {
    await _loadStoredToken();
  }

  /// Public method to load token (for compatibility with main.dart)
  Future<void> loadToken() async {
    await _loadStoredToken();
  }

  /// Get token info for debugging
  Map<String, dynamic> getTokenInfo() {
    return {
      'hasToken': authToken.value != null,
      'isValid': isTokenValid.value,
      'isNotExpired': _isTokenNotExpired(),
      'tokenLength': authToken.value?.length ?? 0,
      'maskedToken': authToken.value != null
          ? _maskToken(authToken.value!)
          : null,
      'lastUpdate': lastTokenUpdate.value?.toIso8601String(),
      'expiryTime': tokenExpiry.value?.toIso8601String(),
      'timeUntilExpiry': tokenExpiry.value
          ?.difference(DateTime.now())
          .inMinutes,
      'userRole': userRole.value,
      'userId': userId.value, // ⭐ ADDED USER ID TO DEBUG INFO
    };
  }

  /// Private helper methods
  void _clearTokenState() {
    authToken.value = null;
    isTokenValid.value = false;
    tokenExpiry.value = null;
    userRole.value = null;
    userId.value = null; // ⭐ CLEAR USER ID
    lastTokenUpdate.value = null;
  }

  String _maskToken(String token) {
    if (token.length <= 8) return '***';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  /// ⭐ ADDED: Method to update user ID separately
  Future<void> updateUserId(String id) async {
    try {
      print('🆔 Updating user ID: $id');

      // Save to both storages
      _storage.write('user_id', id);
      await StorageHelper.saveDriverId(id);

      // Update reactive state
      userId.value = id;

      print('✅ User ID saved successfully: $id');
    } catch (e) {
      print('❌ Error updating user ID: $e');
    }
  }

  /// ⭐ ADDED: Extract and save user ID from current token
  Future<void> extractAndSaveUserId() async {
    try {
      if (authToken.value == null) {
        print('⚠️ No token available to extract user ID');
        return;
      }

      final parts = authToken.value!.split('.');
      if (parts.length == 3) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );

        // Extract ID from multiple possible fields
        final id =
            payload['id']?.toString() ??
            payload['_id']?.toString() ??
            payload['userId']?.toString() ??
            payload['driverId']?.toString();

        if (id != null) {
          await updateUserId(id);
          print('✅ User ID extracted and saved: $id');
        } else {
          print('⚠️ No user ID found in token payload');
        }
      }
    } catch (e) {
      print('❌ Error extracting user ID from token: $e');
    }
  }

  void _notifyTokenUpdate() {
    // Notify other controllers about token update
    try {
      // Refresh API service instance
      if (Get.isRegistered<ApiService>()) {
        final apiService = Get.find<ApiService>();
        apiService.refreshAuthToken();
      }
    } catch (e) {
      print('⚠️ Could not notify API service: $e');
    }
  }
}
