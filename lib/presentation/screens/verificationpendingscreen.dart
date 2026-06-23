import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/token_manager.dart';
import '../../routes/app_pages.dart';
import '../../controllers/verification_pending_controller.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerificationPendingController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.checkStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.status.value == 'pending') {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final isRejected =
                    controller.status.value == 'rejected' ||
                    controller.status.value == 'declined';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Animated Icon
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: isRejected ? Colors.red[50] : Colors.green[50],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isRejected ? Colors.red : Colors.green)
                                .withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        isRejected
                            ? Icons.error_outline_rounded
                            : Icons.hourglass_top_rounded,
                        size: 80,
                        color: isRejected
                            ? Colors.red[600]
                            : Colors.green[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      isRejected
                          ? 'Verification Rejected'
                          : 'Verification Pending',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Description / Reason
                    Text(
                      isRejected
                          ? 'We could not verify your documents. Please review the reason below and try again.'
                          : 'Your documents are currently under review by our team.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (isRejected &&
                        controller.rejectionReason.value.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Reason for Rejection',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              controller.rejectionReason.value,
                              style: TextStyle(
                                color: Colors.red[900],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (!isRejected) ...[
                      const SizedBox(height: 12),
                      Text(
                        'This usually takes 24-48 hours. You will be notified once your account is approved.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Status Card (Only if pending)
                    if (!isRejected)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green[200]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'What happens next?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStatusItem(
                              Icons.check_circle_outline,
                              'Documents submitted',
                              true,
                            ),
                            _buildStatusItem(
                              Icons.pending_outlined,
                              'Under review',
                              false,
                            ),
                            _buildStatusItem(
                              Icons.notifications_outlined,
                              'You\'ll get notified',
                              false,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Action Button (Refresh or Re-upload)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (isRejected) {
                            controller.goToReupload();
                          } else {
                            controller.checkStatus();
                          }
                        },
                        icon: Icon(
                          isRejected ? Icons.upload_file : Icons.refresh,
                        ),
                        label: Text(
                          isRejected
                              ? 'Re-upload Documents'
                              : 'Check Status Again',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRejected
                              ? Colors.red[600]
                              : Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await TokenManager.instance.clearToken();
                          Get.offAllNamed(Routes.LOGIN);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Logout & Exit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Contact Support
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Need help? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: () => _showContactSupportDialog(context),
                          child: Text(
                            'Contact Support',
                            style: TextStyle(
                              color: isRejected
                                  ? Colors.red[700]
                                  : Colors.green[700],
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String text, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isCompleted ? Colors.green[600] : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isCompleted ? Colors.green[700] : Colors.grey[600],
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our support team is available to help you with the verification process.',
            ),
            const SizedBox(height: 20),
            _buildContactItem(
              Icons.email_outlined,
              'Email Support',
              'support@ridealmobility.com',
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              Icons.phone_outlined,
              'Call Support',
              '+911204357047',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.green[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.green[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
