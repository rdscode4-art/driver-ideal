import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/non_vehicle_payout_controller.dart';

class NonVehiclePayoutHistoryScreen extends StatelessWidget {
  const NonVehiclePayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NonVehiclePayoutController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Withdrawal History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange[600],
        elevation: 0,
        automaticallyImplyLeading: false,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Get.back(),
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.fetchPayoutHistory(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading history...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (controller.payoutHistory.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchPayoutHistory(),
          color: Colors.orange[600],
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.payoutHistory.length,
            itemBuilder: (context, index) {
              final payout = controller.payoutHistory[index];
              return _buildPayoutCard(payout, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'No Withdrawal History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any withdrawals yet',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(
    Map<String, dynamic> payout,
    NonVehiclePayoutController controller,
  ) {
    final amount = payout['amount']?.toDouble() ?? 0.0;
    final status = (payout['status'] ?? 'pending').toString().toLowerCase();
    final requestedAt = payout['requestedAt'] ?? payout['createdAt'];

    final statusColor = controller.getStatusColor(status);
    final statusIcon = controller.getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPayoutDetails(payout, controller),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount and Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Amount
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.currency_rupee,
                            color: Colors.orange[600],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            Text(
                              _formatDate(requestedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Payment Method Info (if available)
                if (payout['bankDetails'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPaymentIcon(payout['bankDetails']),
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getPaymentMethodText(payout['bankDetails']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Transaction ID (if available)
                if (payout['_id'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'ID: ${payout['_id'].toString().substring(0, 10)}...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(Map<String, dynamic> bankDetails) {
    if (bankDetails['upiId'] != null && bankDetails['upiId'].isNotEmpty) {
      return Icons.account_balance_wallet;
    }
    return Icons.account_balance;
  }

  String _getPaymentMethodText(Map<String, dynamic> bankDetails) {
    if (bankDetails['upiId'] != null && bankDetails['upiId'].isNotEmpty) {
      return 'UPI: ${bankDetails['upiId']}';
    }
    if (bankDetails['accountNumber'] != null) {
      final accNum = bankDetails['accountNumber'].toString();
      final masked = accNum.length > 4
          ? 'xxxx${accNum.substring(accNum.length - 4)}'
          : accNum;
      return 'Account: $masked';
    }
    return 'Bank Transfer';
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'N/A';

      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  void _showPayoutDetails(
    Map<String, dynamic> payout,
    NonVehiclePayoutController controller,
  ) {
    final amount = payout['amount']?.toDouble() ?? 0.0;
    final status = (payout['status'] ?? 'pending').toString().toLowerCase();
    final requestedAt = payout['requestedAt'] ?? payout['createdAt'];

    final statusColor = controller.getStatusColor(status);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(requestedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Details
              _buildDetailRow('Amount', '₹${amount.toStringAsFixed(2)}'),
              _buildDetailRow('Status', status.toUpperCase()),

              if (payout['_id'] != null)
                _buildDetailRow('Transaction ID', payout['_id']),

              if (payout['bankDetails'] != null) ...[
                if (payout['bankDetails']['upiId'] != null)
                  _buildDetailRow('UPI ID', payout['bankDetails']['upiId']),
                if (payout['bankDetails']['accountNumber'] != null)
                  _buildDetailRow(
                    'Account Number',
                    payout['bankDetails']['accountNumber'],
                  ),
                if (payout['bankDetails']['ifscCode'] != null)
                  _buildDetailRow(
                    'IFSC Code',
                    payout['bankDetails']['ifscCode'],
                  ),
              ],

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
