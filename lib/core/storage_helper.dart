import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const String isLoggedInKey = 'is_logged_in';
  static const String authTokenKey = 'auth_token';
  static const String userRoleKey = 'user_role'; // ✅ Add this
  static const String userDataKey = 'user_data';
  static const String driverStatusKey = 'driver_status';
  static const String driverProfileKey = 'driver_profile';
  static const String driverIdKey = 'driver_id';
  static const String kycDataKey = 'kyc_data';
  static const String vehicleInfoKey = 'vehicle_info';

  // Login status
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, value);
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userRoleKey, role);
    print('✅ User role saved: $role');
  }

  // Get user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userRoleKey);
  }

  // Clear user role
  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userRoleKey);
  }

  static Future<bool> getLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isLoggedInKey) ?? false;
  }

  // Auth token
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(authTokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(authTokenKey);
  }

  static Future<bool> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(authTokenKey, token);
  }

  static Future<bool> removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(authTokenKey);
  }

  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokenKey);
  }

  // User data
  static Future<void> saveUserData(String userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userDataKey, userData);
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userDataKey);
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userDataKey);
  }

  // Driver status
  static Future<void> saveDriverStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(driverStatusKey, status);
  }

  static Future<String?> getDriverStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(driverStatusKey);
  }

  static Future<void> clearDriverStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(driverStatusKey);
  }
  static Future<void> saveDriverProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(driverProfileKey, json.encode(profile));
  }

  static Future<Map<String, dynamic>?> getDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(driverProfileKey);
    if (profileStr != null) {
      try {
        return json.decode(profileStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(driverProfileKey);
  }

  // Driver ID
  static Future<void> saveDriverId(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(driverIdKey, driverId);
  }

  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(driverIdKey);
  }

  static Future<void> clearDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(driverIdKey);
  }

  // KYC Data methods
  static Future<void> saveKYCData(Map<String, dynamic> kycData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kycDataKey, json.encode(kycData));
  }

  static Future<Map<String, dynamic>?> getKYCData() async {
    final prefs = await SharedPreferences.getInstance();
    final kycDataStr = prefs.getString(kycDataKey);
    if (kycDataStr != null) {
      try {
        return json.decode(kycDataStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearKYCData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kycDataKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Generic string methods
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Generic bool methods
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  // Check if key exists
  static Future<bool> hasKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  // Driver details methods
  static Future<String?> getDriverPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_phone');
  }

  static Future<void> saveDriverPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_phone', phone);
  }

  static Future<String?> getDriverEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_email');
  }

  static Future<void> saveDriverEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_email', email);
  }

  static Future<String?> getDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_name');
  }

  static Future<void> saveDriverName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_name', name);
  }
}
