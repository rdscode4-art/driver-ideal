import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/utils/app_snackbar.dart';
import '../controllers/ongoing_ride_controller.dart';

class PaymentIntegrationHelper {
  /// Complete ride with payment method - handles both cash and online payments
  static Future<void> completeRideWithPaymentMethod(
    OngoingRideController controller,
    String paymentMethod,
    RxBool isCompleting,
  ) async {
    try {
      isCompleting.value = true;

      log('💳 ===== PAYMENT FLOW STARTED =====');
      log('💳 Payment Method: $paymentMethod');
      log('💳 Ride ID: ${controller.currentRide.value?.id}');

      if (controller.currentRide.value == null) {
        log('❌ No active ride found');
        showErrorSnackBar('No active ride found', title: '❌ Error');
        isCompleting.value = false;
        return;
      }

      // Call the API service method
      log('📡 Calling API: completeRideWithPayment');
      final response = await controller.completeRideWithPayment(paymentMethod);

      log('📡 API Response: $response');

      if (response['success'] == true) {
        log('✅ API call successful');

        // Check if online payment requires QR code
        if (paymentMethod == 'online' && response['requiresPayment'] == true) {
          log('💳 Online payment - showing QR code');

          // Validate required fields
          if (response['orderId'] == null ||
              response['amount'] == null ||
              response['qrCode'] == null) {
            log('❌ Missing required payment data');
            log('❌ orderId: ${response['orderId']}');
            log('❌ amount: ${response['amount']}');
            log(
              '❌ qrCode: ${response['qrCode'] != null ? 'present' : 'missing'}',
            );

            isCompleting.value = false;

            showErrorSnackBar(
              'Payment data incomplete. Please try again.',
              title: '❌ Error',
            );
            return;
          }

          // CRITICAL FIX: Close payment method selection with proper delay
          log('🚪 Closing payment method bottom sheet');

          // Close the bottom sheet first
          if (Get.isBottomSheetOpen == true) {
            Get.back();
          }

          // Wait for animation to complete before showing QR sheet
          await Future.delayed(const Duration(milliseconds: 300));

          log('🔄 Opening QR code bottom sheet');

          // Show QR code bottom sheet for online payment
          await _showQRCodePaymentBottomSheet(
            controller,
            response['orderId'],
            response['amount'],
            response['currency'] ?? 'INR',
            response['qrCode'],
            response['paymentLink'],
          );
        } else {
          // Cash payment completed successfully
          log('💰 Cash payment - completing ride');

          // Close payment method selection
          if (Get.isBottomSheetOpen == true) {
            Get.back();
          }

          controller.ridePhase.value = RidePhase.COMPLETED;

          showSuccessSnackBar(
            'Cash payment recorded successfully',
            title: '✅ Ride Completed',
          );

          // Navigate to home after delay
          await Future.delayed(const Duration(seconds: 2));
          Get.offAllNamed('/');
        }
      } else {
        log('❌ API call failed: ${response['message']}');

        showErrorSnackBar(
          response['message'] ?? 'Failed to complete ride',
          title: '❌ Error',
        );
      }
    } catch (e, stackTrace) {
      log('❌ Exception in completeRideWithPaymentMethod: $e');
      log('❌ Stack trace: $stackTrace');

      showErrorSnackBar(
        'Network error occurred: ${e.toString()}',
        title: '❌ Error',
      );
    } finally {
      isCompleting.value = false;
      log('💳 ===== PAYMENT FLOW ENDED =====');
    }
  }

  /// Show QR code bottom sheet for online payment
  static Future<void> _showQRCodePaymentBottomSheet(
    OngoingRideController controller,
    String orderId,
    dynamic amount,
    String currency,
    String? qrCode,
    String? paymentLink,
  ) async {
    log('🎨 ===== RENDERING QR CODE UI =====');
    log('🎨 Order ID: $orderId');
    log('🎨 Amount: $amount (${amount.runtimeType})');
    log('🎨 Currency: $currency');
    log('🎨 QR Code present: ${qrCode != null && qrCode.isNotEmpty}');
    log('🎨 Payment Link: $paymentLink');

    final RxBool isVerifying = false.obs;
    final RxString paymentStatus = 'pending'.obs;
    Timer? verificationTimer;

    // Convert amount to display format
    int amountInPaise = 0;
    String displayAmount = '0.00';

    try {
      if (amount is int) {
        amountInPaise = amount;
        displayAmount = (amount / 100).toStringAsFixed(2);
      } else if (amount is double) {
        amountInPaise = (amount * 100).toInt();
        displayAmount = amount.toStringAsFixed(2);
      } else if (amount is String) {
        final parsedAmount = double.parse(amount);
        amountInPaise = (parsedAmount * 100).toInt();
        displayAmount = parsedAmount.toStringAsFixed(2);
      }

      log('💰 Amount in paise: $amountInPaise');
      log('💰 Display amount: $displayAmount');
    } catch (e) {
      log('❌ Error parsing amount: $e');
      displayAmount = '0.00';
    }

    // Start automatic payment verification polling
    log('⏱️ Starting payment verification timer (3 second intervals)');
    verificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (paymentStatus.value == 'pending') {
        log('🔄 Auto-checking payment status...');
        await _checkPaymentStatus(
          controller,
          orderId,
          paymentStatus,
          isVerifying,
        );
      } else {
        log('⏹️ Stopping verification timer - status: ${paymentStatus.value}');
        timer.cancel();
      }
    });

    // CRITICAL FIX: Use Get.bottomSheet with explicit context
    await Get.bottomSheet(
      WillPopScope(
        onWillPop: () async {
          log('🚪 User attempting to close QR bottom sheet');
          verificationTimer?.cancel();

          if (paymentStatus.value == 'pending') {
            // Show confirmation dialog before closing
            final shouldClose = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                  'Payment is still pending. Are you sure you want to cancel?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('No, Continue'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text('Yes, Cancel'),
                  ),
                ],
              ),
            );

            if (shouldClose == true) {
              showWarningSnackBar(
                'Please complete the payment manually or use cash',
                title: 'Payment Cancelled',
              );
              return true;
            }
            return false;
          }

          return true;
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status indicator
                    if (paymentStatus.value == 'pending')
                      _buildPendingPaymentHeader(displayAmount, currency)
                    else if (paymentStatus.value == 'success')
                      _buildSuccessPaymentHeader()
                    else if (paymentStatus.value == 'failed')
                      _buildFailedPaymentHeader(),

                    const SizedBox(height: 24),

                    // QR Code or Status Display
                    if (paymentStatus.value == 'pending') ...[
                      // QR Code Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (qrCode != null && qrCode.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _base64ToImage(qrCode),
                                  width: 250,
                                  height: 250,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    log('❌ Error displaying QR image: $error');
                                    log('❌ Stack trace: $stackTrace');
                                    return Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.red[300],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'QR Code Error',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text(
                                              error.toString(),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'QR Code Unavailable',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Order ID: $orderId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Scan this QR code using any UPI app (PhonePe, GPay, Paytm, etc.) to complete payment',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Verification status
                      if (isVerifying.value)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange[700]!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Verifying payment...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Manual verify button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: !isVerifying.value
                              ? () {
                                  log(
                                    '👆 User manually checking payment status',
                                  );
                                  _checkPaymentStatus(
                                    controller,
                                    orderId,
                                    paymentStatus,
                                    isVerifying,
                                  );
                                }
                              : null,
                          icon: isVerifying.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 20),
                          label: Text(
                            isVerifying.value
                                ? 'Checking...'
                                : 'Check Payment Status',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isVerifying.value
                                ? Colors.blue[600]
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: !isVerifying.value ? 3 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Cancel button
                      TextButton.icon(
                        onPressed: () async {
                          log('❌ User clicked cancel payment');

                          final shouldClose = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Cancel Payment?'),
                              content: const Text(
                                'Payment is still pending. If you cancel, you can complete it later with cash.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Continue Paying'),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Cancel Payment'),
                                ),
                              ],
                            ),
                          );

                          if (shouldClose == true) {
                            verificationTimer?.cancel();
                            Get.back();

                            showWarningSnackBar(
                              'Please complete the payment manually or use cash',
                              title: 'Payment Cancelled',
                            );
                          }
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text(
                          'Cancel Payment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ] else if (paymentStatus.value == 'success') ...[
                      // Success animation
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 100,
                                color: Colors.green[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Payment Successful!',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ride completed successfully',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (paymentStatus.value == 'failed') ...[
                      // Failed payment UI
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 100,
                                color: Colors.red[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Payment Failed',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please try again or use cash payment',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  verificationTimer?.cancel();
                                  Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: false, // Prevent accidental dismissal
      enableDrag: true,
    ).then((_) {
      log('🚪 QR bottom sheet closed');
      verificationTimer?.cancel();
    });
  }

  /// Check payment status from backend
  static Future<void> _checkPaymentStatus(
    OngoingRideController controller,
    String orderId,
    RxString paymentStatus,
    RxBool isVerifying,
  ) async {
    if (isVerifying.value) {
      log('⏭️ Payment verification already in progress, skipping...');
      return;
    }

    try {
      isVerifying.value = true;

      log('🔍 ===== CHECKING PAYMENT STATUS =====');
      log('🔍 Order ID: $orderId');

      final response = await controller.verifyPaymentStatus(orderId);

      log('📡 Verification API Response: $response');

      if (response['success'] == true) {
        final status = response['paymentStatus'] ?? 'pending';
        log('✅ Payment status from API: $status');

        if (status == 'success' || status == 'paid' || status == 'completed') {
          log('✅ Payment VERIFIED - Completing ride');
          paymentStatus.value = 'success';

          // Update ride status to completed
          controller.ridePhase.value = RidePhase.COMPLETED;

          showSuccessSnackBar(
            'Ride completed successfully!',
            title: '✅ Payment Verified',
          );

          // Close QR bottom sheet after short delay
          await Future.delayed(const Duration(seconds: 2));
          if (Get.isBottomSheetOpen == true) {
            Get.back();
          }

          // Navigate to home
          await Future.delayed(const Duration(seconds: 1));
          Get.offAllNamed('/');
        } else if (status == 'failed' || status == 'cancelled') {
          log('❌ Payment FAILED');
          paymentStatus.value = 'failed';
        } else {
          log('⏳ Payment still pending: $status');
        }
      } else {
        log('❌ Payment verification API failed: ${response['message']}');
      }
    } catch (e, stackTrace) {
      log('❌ Exception checking payment status: $e');
      log('❌ Stack trace: $stackTrace');

      showWarningSnackBar(
        'Could not check payment status. Please try again.',
        title: 'Verification Error',
      );
    } finally {
      isVerifying.value = false;
      log('🔍 ===== PAYMENT STATUS CHECK ENDED =====');
    }
  }

  /// Build pending payment header
  static Widget _buildPendingPaymentHeader(
    String displayAmount,
    String currency,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[100]!, Colors.orange[200]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            size: 56,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Scan QR Code to Pay',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[700]!],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '${currency == 'INR' ? '₹' : currency} $displayAmount',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  /// Build success payment header
  static Widget _buildSuccessPaymentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[100]!, Colors.green[200]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.check_circle, size: 56, color: Colors.green[700]),
    );
  }

  /// Build failed payment header
  static Widget _buildFailedPaymentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red[100]!, Colors.red[200]!]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.error, size: 56, color: Colors.red[700]),
    );
  }

  /// Convert base64 string to image bytes
  static Uint8List _base64ToImage(String base64String) {
    try {
      log('🖼️ Converting base64 to image');
      log('🖼️ Base64 length: ${base64String.length}');
      log(
        '🖼️ First 50 chars: ${base64String.substring(0, base64String.length > 50 ? 50 : base64String.length)}',
      );

      // Remove data URL prefix if present (e.g., "data:image/png;base64,")
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        final parts = base64String.split(',');
        cleanBase64 = parts.length > 1 ? parts[1] : parts[0];
        log('🖼️ Removed data URL prefix - new length: ${cleanBase64.length}');
      }

      // Remove any whitespace or newlines
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');

      final bytes = base64Decode(cleanBase64);
      log('✅ Successfully decoded base64 - ${bytes.length} bytes');
      return bytes;
    } catch (e, stackTrace) {
      log('❌ Error decoding base64 image: $e');
      log('❌ Stack trace: $stackTrace');

      // Return empty bytes instead of throwing
      return Uint8List(0);
    }
  }
}
