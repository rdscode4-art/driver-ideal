import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/payout_controller.dart';

class WithdrawalRequestScreen extends StatelessWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PayoutController controller = Get.put(PayoutController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.otpSent.value ? 'Verify OTP' : 'Request Withdrawal',
            )),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        // Debug print
        print('🔍 UI BUILD - otpSent: ${controller.otpSent.value}, isSubmitting: ${controller.isSubmitting.value}');
        
        if (controller.isSubmitting.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  controller.otpSent.value
                      ? 'Verifying OTP...'
                      : 'Processing your withdrawal request...',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Show OTP verification screen if OTP is sent
        if (controller.otpSent.value) {
          return _buildOTPVerificationScreen(controller);
        }

        // Show withdrawal request form
        return _buildWithdrawalForm(controller);
      }),
    );
  }

  Widget _buildWithdrawalForm(PayoutController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 60,
                    color: Colors.green[700],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Withdraw Your Earnings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to withdraw money',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Amount Field
          _buildSectionTitle('Withdrawal Amount'),
          const SizedBox(height: 10),
          TextField(
            controller: controller.amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter amount',
              prefixText: '₹ ',
              prefixIcon: Icon(
                Icons.currency_rupee,
                color: Colors.green[700],
              ),
              suffixIcon: Icon(Icons.money, color: Colors.green[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum withdrawal: ₹${controller.minWithdrawalAmount.value.toInt()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),

          const SizedBox(height: 25),

          // Payout Method
          _buildSectionTitle('Payout Method'),
          const SizedBox(height: 10),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[100],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: DropdownButton<String>(
                value: controller.selectedPayoutMethod.value,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: controller.payoutMethods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Row(
                      children: [
                        Icon(
                          method == 'BANK'
                              ? Icons.account_balance
                              : Icons.payment,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 10),
                        Text(method),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    controller.selectedPayoutMethod.value = value;
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Conditional Fields based on Payout Method
          Obx(() {
            if (controller.selectedPayoutMethod.value == 'UPI') {
              // UPI ID Field
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('UPI ID'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.upiIdController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'e.g., 9876543210@paytm',
                      prefixIcon: Icon(
                        Icons.payment,
                        color: Colors.green[700],
                      ),
                      suffixIcon: Icon(
                        Icons.verified_user,
                        color: Colors.green[700],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your UPI ID (username@provider)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              );
            } else {
              // Bank Account Fields
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Account Number
                  _buildSectionTitle('Bank Account Number'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.accountNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(18),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter account number',
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: Colors.green[700],
                      ),
                      suffixIcon: Icon(
                        Icons.verified_user,
                        color: Colors.green[700],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // IFSC Code
                  _buildSectionTitle('IFSC Code'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.ifscCodeController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(11),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'e.g., SBIN0000123',
                      prefixIcon: Icon(Icons.code, color: Colors.green[700]),
                      suffixIcon: Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ],
              );
            }
          }),

          const SizedBox(height: 35),

          // Submit Button
          ElevatedButton(
            onPressed: () {
              controller.requestWithdrawal();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 22),
                SizedBox(width: 10),
                Text(
                  'Send OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info Card
          Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              controller.selectedPayoutMethod.value == 'UPI'
                                  ? '• An OTP will be sent to your registered mobile number\n'
                                      '• Withdrawal requests are processed within 24-48 hours\n'
                                      '• Minimum withdrawal amount is ₹${controller.minWithdrawalAmount.value.toInt()}\n'
                                      '• Ensure your UPI ID is correct\n'
                                      '• Admin approval is required'
                                  : '• An OTP will be sent to your registered mobile number\n'
                                      '• Withdrawal requests are processed within 24-48 hours\n'
                                      '• Minimum withdrawal amount is ₹${controller.minWithdrawalAmount.value.toInt()}\n'
                                      '• Ensure bank details are correct\n'
                                      '• Admin approval is required',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildOTPVerificationScreen(PayoutController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 60,
                    color: Colors.green[700],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit OTP sent to your registered mobile number',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // OTP Field
          _buildSectionTitle('Enter OTP'),
          const SizedBox(height: 10),
          TextField(
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '000000',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.green[700],
              ),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),

          const SizedBox(height: 35),

          // Verify Button
          ElevatedButton(
            onPressed: () {
              controller.verifyOTPAndCompleteWithdrawal();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: 22),
                SizedBox(width: 10),
                Text(
                  'Verify & Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Back Button
          TextButton(
            onPressed: () {
              controller.resetOTPFlow();
            },
            child: const Text(
              'Go Back & Edit Details',
              style: TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),

          // Warning Card
          Card(
            color: Colors.amber[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.amber[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '• Never share your OTP with anyone\n'
                          '• OTP is valid for 10 minutes\n'
                          '• You can request a new OTP if needed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}