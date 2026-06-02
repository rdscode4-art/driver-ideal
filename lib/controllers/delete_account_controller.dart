import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/token_manager.dart';
import '../core/utils/app_snackbar.dart';

class DeleteAccountController extends GetxController {
  var isLoading = false.obs;
  var deleteStatus = ''.obs; // To hold the status, e.g., 'pending'
  var reasonController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    checkDeleteStatus();
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }

  Future<void> checkDeleteStatus() async {
    try {
      isLoading.value = true;
      final tokenManager = Get.find<TokenManager>();
      final token = tokenManager.authToken.value;
      final role = tokenManager.userRole.value;

      if (token == null || token.isEmpty) {
        isLoading.value = false;
        return;
      }

      String url = '';
      if (role == 'non-vehicle-driver') {
        url = 'https://backend.ridealmobility.com/api/non-vehicle-driver/delete-account-status';
      } else {
        url = 'https://backend.ridealmobility.com/auth/driver/delete-account-status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assuming data has 'status' or similar if a request exists
        if (data['success'] == true) {
          // You can parse status if the API returns a specific pending flag
          // e.g., deleteStatus.value = data['data']['status'] ?? '';
          if (data['data'] != null && data['data']['status'] != null) {
            deleteStatus.value = data['data']['status'].toString().toLowerCase();
          }
        }
      }
    } catch (e) {
      print('❌ Error checking delete account status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitDeleteRequest() async {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      showWarningSnackBar('Please provide a reason for deleting your account.', title: 'Reason Required');
      return;
    }

    try {
      isLoading.value = true;
      final tokenManager = Get.find<TokenManager>();
      final token = tokenManager.authToken.value;
      final role = tokenManager.userRole.value;

      if (token == null || token.isEmpty) {
        showErrorSnackBar('Authentication token missing. Please log in again.');
        return;
      }

      String url = '';
      if (role == 'non-vehicle-driver') {
        url = 'https://backend.ridealmobility.com/api/non-vehicle-driver/delete-account-request';
      } else {
        url = 'https://backend.ridealmobility.com/auth/driver/delete-account-request';
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          showSuccessSnackBar(data['message'] ?? 'Delete account request submitted successfully.', title: 'Success');
          Get.back(); // Go back to profile screen
        } else {
          showErrorSnackBar(data['message'] ?? 'Failed to submit request.');
        }
      } else {
        showErrorSnackBar(data['message'] ?? 'An error occurred. Please try again.');
      }
    } catch (e) {
      print('❌ Error submitting delete request: $e');
      showErrorSnackBar('Network error. Please try again later.');
    } finally {
      isLoading.value = false;
    }
  }
}
