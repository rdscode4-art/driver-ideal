import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payout_controller.dart';

class PayoutHistoryScreen extends StatelessWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PayoutController controller = Get.put(PayoutController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal History'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.fetchPayoutHistory();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Loading withdrawal history...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (controller.payoutHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No Withdrawal History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your withdrawal requests will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchPayoutHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
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

  Widget _buildPayoutCard(
    Map<String, dynamic> payout,
    PayoutController controller,
  ) {
    final amount = payout['amount'] ?? 0;
    final status = (payout['status'] ?? 'PENDING').toString().toUpperCase();
    final createdAt = payout['requestedAt'] ?? payout['createdAt'] ?? '';
    final payoutMethod = payout['payoutMethod'] ?? 'BANK';

    // Extract from nested bankDetails object
    final bankDetails = payout['bankDetails'] ?? {};
    final accountNumber =
        bankDetails['accountNumber'] ?? payout['accountNumber'] ?? '';
    final ifscCode = bankDetails['ifscCode'] ?? payout['ifscCode'] ?? '';

    final adminRemarks = payout['adminRemarks'] ?? payout['remarks'] ?? '';

    // Format date using built-in DateTime formatting
    String formattedDate = 'N/A';
    try {
      if (createdAt.isNotEmpty) {
        final date = DateTime.parse(createdAt);
        // Format: 18 Dec 2025, 02:30 PM
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final day = date.day.toString().padLeft(2, '0');
        final month = months[date.month - 1];
        final year = date.year;
        final hour = date.hour > 12
            ? date.hour - 12
            : (date.hour == 0 ? 12 : date.hour);
        final minute = date.minute.toString().padLeft(2, '0');
        final period = date.hour >= 12 ? 'PM' : 'AM';
        formattedDate =
            '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $period';
      }
    } catch (e) {
      formattedDate = createdAt.toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Icon(
                      Icons.currency_rupee,
                      color: Colors.green[700],
                      size: 28,
                    ),
                    Text(
                      amount.toString(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
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
                    color: controller.getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: controller.getStatusColor(status),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.getStatusIcon(status),
                        size: 16,
                        color: controller.getStatusColor(status),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: controller.getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            // Details
            _buildDetailRow(
              icon: Icons.payment,
              label: 'Method',
              value: payoutMethod,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.account_balance,
              label: 'Account',
              value: _maskAccountNumber(accountNumber),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(icon: Icons.code, label: 'IFSC', value: ifscCode),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Requested On',
              value: formattedDate,
            ),

            // Admin Remarks (if any)
            if (adminRemarks.isNotEmpty) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment, size: 18, color: Colors.amber[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Remarks:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            adminRemarks,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.isEmpty) return 'N/A';
    if (accountNumber.length <= 4) return accountNumber;

    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return 'XXXX$lastFour';
  }
}
