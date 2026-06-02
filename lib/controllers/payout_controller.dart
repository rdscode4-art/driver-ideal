import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/driver_payout_service.dart';
import '../services/driver_api_service.dart';
import '../core/utils/app_snackbar.dart';

class PayoutController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var payoutHistory = <Map<String, dynamic>>[].obs;
  var otpSent = false.obs;
  var minWithdrawalAmount = 100.0.obs; // Default fallback
  var minWithdrawalDescription = "".obs;

  // Form controllers
  final amountController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscCodeController = TextEditingController();
  final upiIdController = TextEditingController(); // NEW: UPI ID controller
  final otpController = TextEditingController();

  // Selected payout method
  var selectedPayoutMethod = 'BANK'.obs;

  // Payout methods
  final List<String> payoutMethods = ['BANK', 'UPI'];

  // Store withdrawal details for OTP verification
  double? _pendingAmount;
  String? _pendingPayoutMethod;
  String? _pendingAccountNumber;
  String? _pendingIfscCode;

  @override
  void onInit() {
    super.onInit();
    fetchPayoutHistory();
    fetchMinWithdrawalAmount();
  }

  /// Fetch minimum withdrawal amount from settings
  Future<void> fetchMinWithdrawalAmount() async {
    try {
      final response = await DriverApiService.getMinimumWithdrawalAmount();
      if (response.isSuccess && response.data != null) {
        minWithdrawalAmount.value = (response.data!['minimumAmount'] ?? 100.0).toDouble();
        minWithdrawalDescription.value = response.data!['description'] ?? "";
        print('✅ Min withdrawal amount fetched: ₹${minWithdrawalAmount.value}');
      }
    } catch (e) {
      print('❌ Error fetching min withdrawal amount: $e');
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    accountNumberController.dispose();
    ifscCodeController.dispose();
    upiIdController.dispose(); // NEW: Dispose UPI controller
    otpController.dispose();
    super.onClose();
  }

  /// Fetch payout history
  Future<void> fetchPayoutHistory() async {
    try {
      isLoading.value = true;
      print('📋 Fetching payout history...');

      final response = await DriverPayoutService.getMyPayouts();

      if (response['success'] == true) {
        final data = response['data'];

        // Handle different response structures
        if (data is List) {
          payoutHistory.value = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['payouts'] != null) {
          payoutHistory.value = List<Map<String, dynamic>>.from(
            data['payouts'],
          );
        } else if (data is Map && data['data'] != null) {
          payoutHistory.value = List<Map<String, dynamic>>.from(data['data']);
        } else {
          payoutHistory.value = [];
        }

        print('✅ Fetched ${payoutHistory.length} payout records');
      } else {
        print('❌ Failed to fetch payouts: ${response['message']}');
        showErrorSnackBar(
          response['message'] ?? 'Failed to fetch withdrawal history',
          title: 'Error',
        );
      }
    } catch (e) {
      print('💥 Exception in fetchPayoutHistory: $e');
      showErrorSnackBar(
        'Failed to load withdrawal history',
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Request withdrawal (Step 1 - Send OTP)
  Future<void> requestWithdrawal() async {
    print('\n🚀 ========== REQUEST WITHDRAWAL STARTED ==========');
    print('📊 Current form values:');
    print('   Amount field: "${amountController.text}"');
    print('   Method: ${selectedPayoutMethod.value}');

    if (selectedPayoutMethod.value == 'UPI') {
      print('   UPI ID: "${upiIdController.text}"');
    } else {
      print('   Account field: "${accountNumberController.text}"');
      print('   IFSC field: "${ifscCodeController.text}"');
    }

    try {
      // Validate form
      print('📝 Step 1: Validating form...');
      final isValid = _validateForm();
      print('📝 Validation result: $isValid');

      if (!isValid) {
        print('❌ Form validation failed');
        return;
      }
      print('✅ Form validation passed');

      isSubmitting.value = true;
      print('💰 Step 2: Requesting OTP for withdrawal...');

      final amount = double.parse(amountController.text.trim());

      // Prepare account details based on method
      String? accountNumber;
      String? ifscCode;
      String? upiId;

      if (selectedPayoutMethod.value == 'UPI') {
        upiId = upiIdController.text.trim();
        print('📊 UPI Withdrawal Details:');
        print('   Amount: ₹$amount');
        print('   Method: UPI');
        print('   UPI ID: $upiId');
      } else {
        accountNumber = accountNumberController.text.trim();
        ifscCode = ifscCodeController.text.trim().toUpperCase();
        print('📊 Bank Withdrawal Details:');
        print('   Amount: ₹$amount');
        print('   Method: BANK');
        print('   Account: $accountNumber');
        print('   IFSC: $ifscCode');
      }

      // Store details for OTP verification
      _pendingAmount = amount;
      _pendingPayoutMethod = selectedPayoutMethod.value;
      _pendingAccountNumber =
          upiId ?? accountNumber; // Store UPI ID or account number
      _pendingIfscCode = ifscCode;
      print('✅ Stored pending withdrawal details');

      print('📡 Step 3: Calling API to send OTP...');
      final response = await DriverPayoutService.requestPayout(
        amount: amount,
        payoutMethod: selectedPayoutMethod.value,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        upiId: upiId, // NEW: Pass UPI ID separately
      );

      print('📨 Step 4: API Response received');
      print('   Success: ${response['success']}');
      print('   Message: ${response['message']}');

      if (response['success'] == true) {
        print('✅✅ OTP sent successfully! Switching to OTP screen...');

        // Set OTP sent flag FIRST
        otpSent.value = true;
        print('✅ otpSent flag set to: ${otpSent.value}');

        // Then show snackbar
        showSuccessSnackBar(
          'OTP sent successfully!',
          title: 'OTP Sent! 📱',
        );

        print('🎉 SUCCESS: OTP screen should now be visible');
      } else {
        print('❌❌ Failed to send OTP');
        print('   Error message: ${response['message']}');

        // Clear pending data on failure
        _clearPendingData();

        showErrorSnackBar(
          response['message'] ?? 'Failed to send OTP. Please try again.',
          title: 'Error ❌',
        );
      }
    } catch (e, stackTrace) {
      print('💥💥 EXCEPTION in requestWithdrawal');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');

      // Clear pending data on exception
      _clearPendingData();

      showErrorSnackBar(
        'An error occurred: ${e.toString()}',
        title: 'Error ❌',
      );
    } finally {
      isSubmitting.value = false;
      print('🏁 ========== REQUEST WITHDRAWAL ENDED ==========\n');
    }
  }

  /// Verify OTP and complete withdrawal (Step 2)
  Future<void> verifyOTPAndCompleteWithdrawal() async {
    print('\n🔐 ========== OTP VERIFICATION STARTED ==========');

    try {
      // Validate OTP
      print('📝 Step 1: Validating OTP...');
      if (otpController.text.trim().isEmpty) {
        print('❌ OTP is empty');
        showWarningSnackBar(
          'Please enter the OTP',
          title: 'Validation Error',
        );
        return;
      }

      if (otpController.text.trim().length != 6) {
        print('❌ OTP length is not 6 digits');
        showWarningSnackBar(
          'OTP must be 6 digits',
          title: 'Validation Error',
        );
        return;
      }
      print('✅ OTP validation passed');

      // Check if pending data exists
      print('📝 Step 2: Checking pending withdrawal data...');
      print('   _pendingAmount: $_pendingAmount');
      print('   _pendingPayoutMethod: $_pendingPayoutMethod');
      print('   _pendingAccountNumber: $_pendingAccountNumber');
      print('   _pendingIfscCode: $_pendingIfscCode');

      if (_pendingAmount == null ||
          _pendingPayoutMethod == null ||
          _pendingAccountNumber == null) {
        print('❌ Pending data is missing - session expired');
        // Get.snackbar(
        //   'Session Expired',
        //   'Please request withdrawal again.',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.red[600],
        //   colorText: Colors.white,
        // );
        resetOTPFlow();
        return;
      }
      print('✅ Pending data exists');

      isSubmitting.value = true;
      print('🔐 Step 3: Verifying OTP and completing withdrawal...');
      print('   OTP: ${otpController.text.trim()}');

      // Prepare data based on payout method
      String? accountNumber;
      String? ifscCode;
      String? upiId;

      if (_pendingPayoutMethod == 'UPI') {
        upiId = _pendingAccountNumber;
      } else {
        accountNumber = _pendingAccountNumber;
        ifscCode = _pendingIfscCode;
      }

      final response = await DriverPayoutService.verifyPayoutOTP(
        otp: otpController.text.trim(),
        amount: _pendingAmount!,
        payoutMethod: _pendingPayoutMethod!,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        upiId: upiId, // NEW: Pass UPI ID separately
      );

      print('📨 Step 4: API Response received');
      print('   Success: ${response['success']}');
      print('   Message: ${response['message']}');

      if (response['success'] == true) {
        print('✅✅ Withdrawal completed successfully!');

        // Clear form and reset state
        resetOTPFlow();

        // Show success message
        showSuccessSnackBar(
          response['message'] ?? 'Withdrawal request submitted successfully',
          title: 'Success! 🎉',
        );

        // Refresh history
        print('📋 Refreshing payout history...');
        await fetchPayoutHistory();

        // Navigate back
        print('🔙 Navigating back...');
        Get.back();
      } else {
        print('❌❌ OTP verification failed');
        print('   Error message: ${response['message']}');

        showErrorSnackBar(
          response['message'] ?? 'Invalid OTP. Please try again.',
          title: 'Error ❌',
        );
      }
    } catch (e, stackTrace) {
      print('💥💥 EXCEPTION in verifyOTPAndCompleteWithdrawal');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');

      showErrorSnackBar(
        'An error occurred: ${e.toString()}',
        title: 'Error ❌',
      );
    } finally {
      isSubmitting.value = false;
      print('🏁 ========== OTP VERIFICATION ENDED ==========\n');
    }
  }

  /// Clear pending withdrawal data
  void _clearPendingData() {
    print('🧹 Clearing pending withdrawal data...');
    _pendingAmount = null;
    _pendingPayoutMethod = null;
    _pendingAccountNumber = null;
    _pendingIfscCode = null;
    print('✅ Pending data cleared');
  }

  /// Reset OTP flow
  void resetOTPFlow() {
    print('🔄 Resetting OTP flow...');
    otpSent.value = false;
    otpController.clear();
    amountController.clear();
    accountNumberController.clear();
    ifscCodeController.clear();
    upiIdController.clear(); // NEW: Clear UPI field
    _clearPendingData();
    print('✅ OTP flow reset complete');
  }

  /// Validate withdrawal form
  bool _validateForm() {
    print('🔍 Validating form fields...');

    // Validate amount
    print('   Checking amount: "${amountController.text.trim()}"');
    if (amountController.text.trim().isEmpty) {
      print('   ❌ Amount is empty');
      showWarningSnackBar(
        'Please enter withdrawal amount',
        title: 'Validation Error',
      );
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      print('   ❌ Amount is invalid: $amount');
      showWarningSnackBar(
        'Please enter a valid amount',
        title: 'Validation Error',
      );
      return false;
    }

    if (amount < minWithdrawalAmount.value) {
      print('   ❌ Amount is less than minimum: $amount < ${minWithdrawalAmount.value}');
      showWarningSnackBar(
        'Minimum withdrawal amount is ₹${minWithdrawalAmount.value.toInt()}',
        title: 'Validation Error',
      );
      return false;
    }
    print('   ✅ Amount is valid: ₹$amount');

    // Validate based on payout method
    if (selectedPayoutMethod.value == 'UPI') {
      return _validateUPI();
    } else {
      return _validateBankAccount();
    }
  }

  /// Validate UPI ID
  bool _validateUPI() {
    print(' 🔍 Validating UPI ID...');
    final upiId = upiIdController.text.trim();

    if (upiId.isEmpty) {
      print('   ❌ UPI ID is empty');
      showWarningSnackBar(
        'Please enter UPI ID',
        title: 'Validation Error',
      );
      return false;
    }

    // Validate UPI ID format (username@provider)
    if (!RegExp(r'^[\w.-]+@[\w]+$').hasMatch(upiId)) {
      print('   ❌ UPI ID format is invalid: $upiId');
      showWarningSnackBar(
        'Please enter valid UPI ID (e.g., username@paytm)',
        title: 'Validation Error',
      );
      return false;
    }

    print('   ✅ UPI ID is valid: $upiId');
    return true;
  }

  /// Validate Bank Account details
  bool _validateBankAccount() {
    print('   🔍 Validating Bank Account...');

    // Validate account number
    print(
      '   Checking account number: "${accountNumberController.text.trim()}"',
    );
    if (accountNumberController.text.trim().isEmpty) {
      print('   ❌ Account number is empty');
      showWarningSnackBar(
        'Please enter account number',
        title: 'Validation Error',
      );
      return false;
    }

    if (accountNumberController.text.trim().length < 8) {
      print(
        '   ❌ Account number is too short: ${accountNumberController.text.trim().length} chars',
      );
      showWarningSnackBar(
        'Please enter a valid account number (minimum 8 digits)',
        title: 'Validation Error',
      );
      return false;
    }
    print('   ✅ Account number is valid');

    // Validate IFSC code
    final ifscCode = ifscCodeController.text.trim().toUpperCase();
    print('   Checking IFSC code: "$ifscCode" (length: ${ifscCode.length})');

    if (ifscCode.isEmpty) {
      print('   ❌ IFSC code is empty');
      showWarningSnackBar(
        'Please enter IFSC code',
        title: 'Validation Error',
      );
      return false;
    }

    if (ifscCode.length != 11) {
      print('   ❌ IFSC code length is not 11: ${ifscCode.length}');
      showWarningSnackBar(
        'IFSC code must be exactly 11 characters (e.g., SBIN0000123)',
        title: 'Validation Error',
      );
      return false;
    }

    if (!RegExp(r'^[A-Z]{4}').hasMatch(ifscCode)) {
      print('   ❌ IFSC code first 4 chars are not letters');
      showWarningSnackBar(
        'IFSC code should start with 4 letters (e.g., SBIN0000123)',
        title: 'Validation Error',
      );
      return false;
    }

    if (ifscCode[4] != '0') {
      print('   ❌ IFSC code 5th char is not 0');
      showWarningSnackBar(
        'IFSC code 5th character should be 0 (e.g., SBIN0000123)',
        title: 'Validation Error',
      );
      return false;
    }

    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(ifscCode.substring(5))) {
      print('   ❌ IFSC code last 6 chars are not alphanumeric');
      showWarningSnackBar(
        'IFSC code last 6 characters should be letters/numbers (e.g., SBIN0000123)',
        title: 'Validation Error',
      );
      return false;
    }

    print('   ✅ IFSC code is valid: $ifscCode');
    print('✅ All validations passed!');
    return true;
  }

  /// Get status color based on payout status
  Color getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon based on payout status
  IconData getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Icons.pending;
      case 'APPROVED':
      case 'COMPLETED':
        return Icons.check_circle;
      case 'REJECTED':
      case 'FAILED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
