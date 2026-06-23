import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/earnings_controller.dart';
import 'widgets/app_logo.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _payoutFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EarningsController controller = Get.find();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: controller.refreshWallet,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with wallet info
            SliverAppBar(
              expandedHeight: 360,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF065F46), // Emerald 800
                        Color(0xFF10B981), // Emerald 500
                        Color(0xFF34D399), // Emerald 400
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Logo
                          const AppLogo(
                            width: 120,
                            height: 120,
                            margin: EdgeInsets.only(bottom: 15),
                          ),

                          // Wallet Balance Card
                          Flexible(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Wallet Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Obx(
                                    () => Text(
                                      '₹${controller.walletBalance.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Available',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Obx(
                                              () => Text(
                                                '₹${controller.availableForPayout.value.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.green[200],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 25,
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Pending',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Obx(
                                              () => Text(
                                                '₹${controller.pendingPayouts.value.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.green[200],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.payment, size: 20), text: 'Payout'),
                  Tab(icon: Icon(Icons.history, size: 20), text: 'History'),
                ],
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPayoutTab(controller),
                  _buildHistoryTab(controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutTab(EarningsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _payoutFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payout Info Card
            // Card(
            //   elevation: 2,
            //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            //   child: Padding(
            //     padding: EdgeInsets.all(20),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
            //             SizedBox(width: 12),
            //             Text(
            //               'Payout Information',
            //               style: TextStyle(
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.grey[800],
            //               ),
            //             ),
            //           ],
            //         ),
            //         SizedBox(height: 16),
            //         _buildInfoRow('Minimum Amount', '₹${controller.minimumPayoutAmount.toStringAsFixed(0)}'),
            //         _buildInfoRow('Processing Time', '2-3 Business Days'),
            //         _buildInfoRow('Transfer Fee', 'Free'),
            //         Obx(() => _buildInfoRow('Available Balance', '₹${controller.availableForPayout.value.toStringAsFixed(2)}')),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 24),

            // Payout Form
            Text(
              'Request Payout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Payout Amount',
                hintText: 'Enter amount to withdraw',
                prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF10B981)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter valid amount';
                }
                if (amount < controller.minimumPayoutAmount) {
                  return 'Minimum amount is ₹${controller.minimumPayoutAmount.toStringAsFixed(0)}';
                }
                if (amount > controller.availableForPayout.value) {
                  return 'Amount exceeds available balance';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Account Holder Name
            TextFormField(
              controller: _accountHolderController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Account Holder Name',
                hintText: 'Enter account holder name',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF10B981)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account holder name';
                }
                if (value.length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Account Number
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Account Number',
                hintText: 'Enter bank account number',
                prefixIcon: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF10B981),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account number';
                }
                if (value.length < 9 || value.length > 18) {
                  return 'Please enter valid account number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // IFSC Code
            TextFormField(
              controller: _ifscController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                labelText: 'IFSC Code',
                hintText: 'Enter IFSC code',
                prefixIcon: const Icon(Icons.code, color: Color(0xFF10B981)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter IFSC code';
                }
                if (value.length != 11) {
                  return 'IFSC code must be 11 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isProcessingPayout.value
                      ? null
                      : () => _submitPayoutRequest(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: controller.isProcessingPayout.value
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing...'),
                          ],
                        )
                      : const Text(
                          'Request Payout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Security Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your banking details are encrypted and secure. We never store your account information.',
                      style: TextStyle(color: Colors.green[700], fontSize: 13),
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

  Widget _buildHistoryTab(EarningsController controller) {
    return Obx(() {
      if (controller.payoutHistory.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Payout History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payout requests will appear here',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.payoutHistory.length,
        itemBuilder: (context, index) {
          final transaction = controller.payoutHistory[index];
          return _buildTransactionCard(transaction);
        },
      );
    });
  }

  Widget _buildTransactionCard(PayoutTransaction transaction) {
    Color statusColor;
    IconData statusIcon;

    switch (transaction.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.green[400]!;
        statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        transaction.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.account_balance, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  transaction.maskedAccountNumber,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.code, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  transaction.ifscCode,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Requested: ${_formatDate(transaction.requestedAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (transaction.completedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Completed: ${_formatDate(transaction.completedAt!)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _submitPayoutRequest(EarningsController controller) async {
    if (_payoutFormKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final accountNumber = _accountNumberController.text;
      final ifscCode = _ifscController.text.toUpperCase();
      final accountHolderName = _accountHolderController.text;

      final success = await controller.requestPayout(
        amount,
        accountNumber,
        ifscCode,
        accountHolderName,
      );

      if (success) {
        // Clear form
        _amountController.clear();
        _accountNumberController.clear();
        _ifscController.clear();
        _accountHolderController.clear();

        // Switch to history tab
        _tabController.animateTo(1);
      }
    }
  }
}
