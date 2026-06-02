import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../core/utils/app_snackbar.dart';
import '../controllers/non_vehicle_payout_controller.dart';

class NonVehicleWithdrawalScreen extends StatefulWidget {
  final double walletBalance;

  const NonVehicleWithdrawalScreen({
    super.key,
    required this.walletBalance,
  });

  @override
  State<NonVehicleWithdrawalScreen> createState() => _NonVehicleWithdrawalScreenState();
}

class _NonVehicleWithdrawalScreenState extends State<NonVehicleWithdrawalScreen> {
  
  @override
  void dispose() {
    super.dispose();
  }
  
  // Validation method - shows snackbar only
  bool _validateBeforeSubmit(NonVehiclePayoutController controller) {
    // Validate amount
    if (controller.amountController.text.isEmpty) {
      _showErrorSnackbar('Please enter withdrawal amount');
      return false;
    }
    
    double? amount = double.tryParse(controller.amountController.text);
    if (amount == null || amount < 270) {
      _showErrorSnackbar('Minimum withdrawal amount is ₹270');
      return false;
    }
    
    if (amount > widget.walletBalance) {
      _showErrorSnackbar('Insufficient balance');
      return false;
    }
    
    // Validate payment method fields
    if (controller.selectedPayoutMethod.value == 'UPI') {
      String upiId = controller.upiIdController.text.trim();
      if (upiId.isEmpty) {
        _showErrorSnackbar('Please enter UPI ID');
        return false;
      }
      if (!RegExp(r'^[\w.+-]+@[\w.-]+$').hasMatch(upiId)) {
        _showErrorSnackbar('Invalid UPI ID format (e.g., username@paytm)');
        return false;
      }
    } else {
      // Validate Bank Account
      String accountNumber = controller.accountNumberController.text.trim();
      String ifscCode = controller.ifscCodeController.text.trim();
      
      if (accountNumber.isEmpty) {
        _showErrorSnackbar('Please enter account number');
        return false;
      }
      if (accountNumber.length < 9 || accountNumber.length > 18) {
        _showErrorSnackbar('Account number must be 9-18 digits');
        return false;
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(accountNumber)) {
        _showErrorSnackbar('Account number must contain only digits');
        return false;
      }
      
      if (ifscCode.isEmpty) {
        _showErrorSnackbar('Please enter IFSC code');
        return false;
      }
      if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifscCode.toUpperCase())) {
        _showErrorSnackbar('Invalid IFSC code format (e.g., SBIN0001234)');
        return false;
      }
    }
    
    return true;
  }
  
  void _showErrorSnackbar(String message) {
    print('📢 Showing error snackbar: $message');
    showErrorSnackBar(message, title: 'Validation Error');
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NonVehiclePayoutController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Withdraw Money',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[600],
        elevation: 0,
         automaticallyImplyLeading: false,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () {
        //     controller.resetOTPFlow();
        //     Get.back();
        //   },
        // ),
      ),
      body: Obx(() {
        // Show OTP verification screen if OTP is sent
        if (controller.otpSent.value) {
          return _buildOTPVerificationScreen(controller);
        }
        
        // Otherwise show withdrawal form
        return _buildWithdrawalForm(controller);
      }),
    );
  }

  Widget _buildValidatedAccountField({required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter your account number',
            prefixIcon: Icon(Icons.account_balance, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(18),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Account number must be 9-18 digits',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildValidatedIFSCField({required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IFSC Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter IFSC code (e.g., SBIN0001234)',
            prefixIcon: Icon(Icons.code, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(11),
            UpperCaseTextFormatter(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Format: 4 letters + 0 + 6 characters (e.g., SBIN0001234)',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildValidatedUPIField({required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UPI ID',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter UPI ID (e.g., username@upi)',
            prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 4),
        Text(
          'e.g., yourname@paytm, 9876543210@ybl',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalForm(NonVehiclePayoutController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.walletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Wallet Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Withdrawal Form Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Withdrawal Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount Field
                  _buildInputField(
                    controller: controller.amountController,
                    label: 'Withdrawal Amount',
                    hint: 'Enter amount to withdraw',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Minimum withdrawal: ₹270',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Method Selection
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Obx(() => Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'UPI',
                          Icons.account_balance_wallet,
                          controller.selectedPayoutMethod.value == 'UPI',
                          () => controller.selectedPayoutMethod.value = 'UPI',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'Bank',
                          Icons.account_balance,
                          controller.selectedPayoutMethod.value == 'BANK',
                          () => controller.selectedPayoutMethod.value = 'BANK',
                        ),
                      ),
                    ],
                  )),

                  const SizedBox(height: 24),

                  // Conditional fields based on payment method
                  Obx(() {
                    if (controller.selectedPayoutMethod.value == 'UPI') {
                      return _buildValidatedUPIField(
                        controller: controller.upiIdController,
                      );
                    } else {
                      return Column(
                        children: [
                          _buildValidatedAccountField(
                            controller: controller.accountNumberController,
                          ),
                          const SizedBox(height: 16),
                          _buildValidatedIFSCField(
                            controller: controller.ifscCodeController,
                          ),
                        ],
                      );
                    }
                  }),

                  const SizedBox(height: 32),

                  // Submit Button
                  Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () {
                              // Validate before submitting
                              if (_validateBeforeSubmit(controller)) {
                                controller.requestWithdrawal();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isSubmitting.value
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Request Withdrawal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'An OTP will be sent to your registered mobile number for verification.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPVerificationScreen(NonVehiclePayoutController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // OTP Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sms_outlined,
                size: 64,
                color: Colors.orange[600],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'We have sent a 6-digit verification code\nto your registered mobile number',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // OTP Input Field
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: controller.otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 16,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        letterSpacing: 16,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Verify Button
                  Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () => controller.verifyOTPAndCompleteWithdrawal(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isSubmitting.value
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Verifying...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Verify & Complete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  )),

                  const SizedBox(height: 16),

                  // Change Details Button
                  TextButton(
                    onPressed: () {
                      controller.resetOTPFlow();
                    },
                    child: Text(
                      'Change Details',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange[600] : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.orange[600] : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom text formatter for uppercase IFSC codes
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}