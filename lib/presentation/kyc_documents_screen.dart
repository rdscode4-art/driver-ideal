import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/subscriptionscreen.dart';
import '../controllers/kyc_controller.dart';
import '../data/models/kyc_verification_model.dart';

class KYCDocumentsScreen extends StatelessWidget {
  const KYCDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KYCController controller = Get.put(KYCController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: controller.refreshVerificationStatus,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              title: const Text(
                'KYC Document Upload',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.blue[700],
              elevation: 0,
              pinned: true,
              floating: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => controller.forceRefreshStatus(),
                  tooltip: 'Refresh Status',
                ),
              ],
            ),

            // Verification Status Card
            SliverToBoxAdapter(
              child: Obx(() => _buildVerificationStatusCard(controller)),
            ),

            // Progress indicator
            SliverToBoxAdapter(
              child: Obx(() => _buildProgressCard(controller)),
            ),

            // Form content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Aadhaar Section
           _buildSectionCard(
  title: 'Aadhaar Details',
  icon: Icons.credit_card,
  children: [
    Obx(
      () => _buildMaskedTextInput(
        controller: controller.aadhaarController,
        label: 'Aadhaar Number',
        hint: 'Enter 12-digit Aadhaar number',
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
        ],
        onToggleVisibility: controller.toggleAadhaarVisibility,
        showFull: controller.showFullAadhaar.value,
        maskedValue: controller.maskedAadhaar,
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    
    // ⭐ NEW: Aadhaar Front Image Upload
    Obx(
      () => _buildImageUpload(
        label: 'Upload Aadhaar Card (Front Side)',
        subtitle: 'Clear photo of front side - JPG, PNG accepted',
        image: controller.aadhaarFrontImage.value,
        onTap: controller.canEditDocuments
            ? () => controller.showImagePickerOptions('aadhaar_front')
            : null,
        onRemove: controller.canEditDocuments
            ? () => controller.removeImage('aadhaar_front')
            : null,
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    
    // ⭐ NEW: Aadhaar Back Image Upload
    Obx(
      () => _buildImageUpload(
        label: 'Upload Aadhaar Card (Back Side)',
        subtitle: 'Clear photo of back side - JPG, PNG accepted',
        image: controller.aadhaarBackImage.value,
        onTap: controller.canEditDocuments
            ? () => controller.showImagePickerOptions('aadhaar_back')
            : null,
        onRemove: controller.canEditDocuments
            ? () => controller.removeImage('aadhaar_back')
            : null,
        enabled: controller.canEditDocuments,
      ),
    ),
  ],
),
                  const SizedBox(height: 16),

                  // Driving License Section
                 _buildSectionCard(
  title: 'Driving License Details',
  icon: Icons.drive_eta,
  children: [
    Obx(
      () => _buildValidatedDLInput(
        controller: controller.drivingLicenseController,
        label: 'Driving License Number',
        hint: 'e.g., DL01 20220012345',
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    Obx(
      () => _buildImageUpload(
        label: 'Upload Driving License',
        subtitle: 'JPG, PNG, PDF accepted',
        image: controller.drivingLicenseImage.value,
        onTap: controller.canEditDocuments
            ? () => controller.showImagePickerOptions('license')
            : null,
        onRemove: controller.canEditDocuments
            ? () => controller.removeImage('license')
            : null,
        enabled: controller.canEditDocuments,
      ),
    ),
  ],
),
                  const SizedBox(height: 16),

                  // Vehicle Section
                 _buildSectionCard(
  title: 'Vehicle Details',
  icon: Icons.directions_car,
  children: [
    Obx(
      () => _buildValidatedVehicleInput(
        controller: controller.vehicleNumberController,
        label: 'Vehicle Registration Number',
        hint: 'e.g., KA01AB1234',
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    Obx(
      () => _buildDropdown(
        label: 'Vehicle Type',
        value: controller.selectedVehicleType,
        items: controller.vehicleTypes,
        onChanged: controller.canEditDocuments
            ? (value) => controller.selectedVehicleType.value = value!
            : null,
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    Obx(
      () => _buildTextInput(
        controller: controller.vehicleNameController,
        label: 'Vehicle Name',
        hint: 'e.g., Honda City, Maruti Swift',
        textCapitalization: TextCapitalization.words,
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    Obx(
      () => _buildImageUpload(
        label: 'Upload Vehicle Photo',
        subtitle: 'JPG, PNG accepted',
        image: controller.vehicleImage.value,
        onTap: controller.canEditDocuments
            ? () => controller.showImagePickerOptions('vehicle')
            : null,
        onRemove: controller.canEditDocuments
            ? () => controller.removeImage('vehicle')
            : null,
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    Obx(
      () => _buildImageUpload(
        label: 'Upload Vehicle RC',
        subtitle: 'Registration Certificate',
        image: controller.vehicleRC.value,
        onTap: controller.canEditDocuments
            ? () => controller.showImagePickerOptions('rc')
            : null,
        onRemove: controller.canEditDocuments
            ? () => controller.removeImage('rc')
            : null,
        enabled: controller.canEditDocuments,
      ),
    ),
    const SizedBox(height: 16),
    Obx(
      () => _buildImageUpload(
        label: 'Upload Vehicle Insurance',
        subtitle: 'Valid insurance document',
        image: controller.vehicleInsurance.value,
        onTap: controller.canEditDocuments
            ? () => controller.showImagePickerOptions('insurance')
            : null,
        onRemove: controller.canEditDocuments
            ? () => controller.removeImage('insurance')
            : null,
        enabled: controller.canEditDocuments,
      ),
    ),
  ],
),

                  const SizedBox(height: 24),

                  // Submit Button - MODIFIED SECTION
                  Obx(() {
                    final status = controller.verificationStatus.value
                        .toLowerCase();

                    // ⭐ CRITICAL: When KYC is PENDING - Show info message and BLOCK form
                    if (status == 'pending') {
                      return Column(
                        children: [
                          // Pending Status Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange[300]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.orange[600],
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'KYC Under Review',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your documents are being verified by our team.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You cannot make changes while verification is in progress.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Refresh Button
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.refreshVerificationStatus(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Check Status Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Disabled Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: null, // Disabled
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Waiting for Verification',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // When KYC is approved, navigate to subscription screen
                    if (status == 'approved' || status == 'accepted') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Navigate to subscription screen

                        //UNCOMMENT WHEN PAYMENTINTEGRATION COME
                        Get.offAll(() => const SubscriptionPlansScreen());
                      });

                      return Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'KYC Approved - Opening Subscriptions...',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Regular submit button for not_submitted or rejected status
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (controller.isSubmitting.value ||
                                !controller.canSubmitDocuments)
                            ? null
                            : controller.submitVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.canSubmitDocuments
                              ? Colors.blue[700]
                              : Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Submitting...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _getSubmitButtonText(controller),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rest of the widget methods remain the same...
  Widget _buildVerificationStatusCard(KYCController controller) {
    final status = controller.verificationStatus.value.toLowerCase();
    if (controller.isLoading.value) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(width: 16),
            Text(
              'Loading verification status...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (controller.hasError.value) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error Loading Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                ),
                // Add debug refresh button
                IconButton(
                  onPressed: () => controller.forceRefreshStatus(),
                  icon: Icon(Icons.refresh, color: Colors.red[600]),
                  tooltip: 'Force Refresh Status',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
            ),
          ],
        ),
      );
    }

    if (status == 'not_submitted' || status == 'unknown') {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[300]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ready for Document Submission',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.refreshStatus(),
                  icon: Icon(Icons.refresh, color: Colors.blue[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload all required documents to complete your verification process.',
              style: TextStyle(fontSize: 14, color: Colors.blue[700]),
            ),
          ],
        ),
      );
    }

   final verification = controller.verificationData.value;
if (verification == null) {
  return const SizedBox.shrink(); // safety fallback
}

    final statusColor = controller.getStatusColor();
    final statusIcon = controller.getStatusIcon();
    final statusText = controller.getStatusDisplayText();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Status',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.forceRefreshStatus(),
                icon: Icon(Icons.refresh, color: Colors.grey[600]),
                tooltip: 'Force Refresh Status',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentDetailsGrid(verification),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Submitted on ${_formatDate(verification.submittedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusMessage(controller),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(KYCController controller) {
    if (controller.isVerificationPending) {
  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange[300]!, width: 1),
    ),
    child: Row(
      children: [
        Icon(Icons.schedule, color: Colors.orange[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your KYC is under review. Please wait.',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

    if (controller.isVerificationPending) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[300]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your documents are under review. We\'ll notify you once verification is complete.',
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.isVerificationAccepted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[300]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Congratulations! Your verification is complete. Please subscribe to start driving.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.isVerificationRejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[300]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your verification was not accepted. Please contact support for more details.',
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProgressCard(KYCController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _getCompletionPercentage(controller),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_getCompletionPercentage(controller) * 100).toInt()}% Complete',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentDetailsGrid(KycVerification verification) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDocumentDetailItem(
                'Aadhaar',
                verification.maskedAadhaarNumber,
                Icons.credit_card,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDocumentDetailItem(
                'Vehicle Type',
                verification.vehicleType.toUpperCase(),
                Icons.directions_car,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDocumentDetailItem(
                'Vehicle Number',
                verification.vehicleNumber,
                Icons.confirmation_number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDocumentDetailItem(
                'Vehicle Name',
                verification.vehicleName,
                Icons.car_rental,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _getCompletionPercentage(KYCController controller) {
    int completedFields = 0;
    int totalFields = 10;

    if (controller.aadhaarController.text.isNotEmpty) completedFields++;
    if (controller.aadhaarFrontImage.value != null) completedFields++;
    if (controller.aadhaarBackImage.value != null) completedFields++;
    if (controller.drivingLicenseController.text.isNotEmpty) completedFields++;
    if (controller.drivingLicenseImage.value != null) completedFields++;
    if (controller.vehicleNumberController.text.isNotEmpty) completedFields++;
    if (controller.selectedVehicleType.value.isNotEmpty) completedFields++;
    if (controller.vehicleNameController.text.isNotEmpty) completedFields++;
    if (controller.vehicleImage.value != null) completedFields++;
    if (controller.vehicleRC.value != null) completedFields++;
    if (controller.vehicleInsurance.value != null) completedFields++;

    return completedFields / totalFields;
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: enabled ? Colors.grey[500] : Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaskedTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    required VoidCallback onToggleVisibility,
    required bool showFull,
    required String maskedValue,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            obscureText: !showFull,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: enabled ? Colors.grey[500] : Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  showFull ? Icons.visibility : Icons.visibility_off,
                  color: enabled ? Colors.grey[600] : Colors.grey[400],
                ),
                onPressed: enabled ? onToggleVisibility : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required RxString value,
    required List<String> items,
    Function(String?)? onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          child: Obx(
            () => DropdownButtonFormField<String>(
              initialValue: value.value.isNotEmpty ? value.value : null,
              hint: Text(
                'Select vehicle type',
                style: TextStyle(
                  color: enabled ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: enabled
                  ? items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item.toUpperCase()),
                      );
                    }).toList()
                  : null,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUpload({
    required String label,
    required String subtitle,
    required String? image,
    VoidCallback? onTap,
    VoidCallback? onRemove,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: enabled ? Colors.grey[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: image != null
                    ? (enabled ? Colors.green : Colors.grey[300]!)
                    : (enabled ? Colors.grey[300]! : Colors.grey[200]!),
                width: image != null ? 2 : 1,
              ),
            ),
            child: image != null && image.isNotEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Document Uploaded',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (image.isNotEmpty)
                              Text(
                                image.split('/').last,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (enabled)
                            IconButton(
                              onPressed: onTap,
                              icon: Icon(Icons.edit, color: Colors.blue[700]),
                              tooltip: 'Replace',
                            ),
                          if (enabled)
                            IconButton(
                              onPressed: onRemove,
                              icon: Icon(Icons.delete, color: Colors.red[700]),
                              tooltip: 'Remove',
                            ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String _getSubmitButtonText(KYCController controller) {
    if (controller.verificationData.value == null) {
      return 'Submit for Verification';
    }

    final status = controller.verificationStatus.value.toLowerCase();
    if (status == 'not_submitted' || status.isEmpty || status == 'unknown') {
      return 'Submit for Verification';
    } else if (status == 'rejected' || status == 'failed') {
      return 'Resubmit Documents';
    } else if (status == 'pending') {
      return 'Documents Under Review';
    } else if (status == 'approved') {
      return 'Verification Complete';
    } else {
      return 'Submit for Verification';
    }
  }
 Widget _buildValidatedVehicleInput({
  required TextEditingController controller,
  required String label,
  required String hint,
  bool enabled = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
          ),
        ),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          textCapitalization: TextCapitalization.characters,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(10),
            _VehicleNumberFormatter(),
          ],
          decoration: InputDecoration(
            hintText: hint,
            helperText: 'Format: AA00AA0000',
            helperStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
            hintStyle: TextStyle(
              color: enabled ? Colors.grey[500] : Colors.grey[400],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '', // Hide the default counter
          ),
          validator: (value) => _validateVehicleNumber(value),
        ),
      ),
    ],
  );
}

String? _validateVehicleNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter vehicle registration number';
  }

  // Remove spaces and dashes for validation
  String cleaned = value.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();

  // Minimum length check
  if (cleaned.length < 9) {
    return 'Vehicle number is too short';
  }

  // Maximum length check
  if (cleaned.length > 10) {
    return 'Vehicle number is too long';
  }

  // Indian vehicle registration format validation
  // Format: AA00AA0000 or AA00A0000
  // State code (2 letters) + District code (2 digits) + Series (1-2 letters) + Number (4 digits)

  // Check if first 2 characters are letters (State code)
  if (!RegExp(r'^[A-Z]{2}').hasMatch(cleaned)) {
    return 'Vehicle number must start with 2 letters (State code)';
  }

  // Check if next 2 characters are digits (District code)
  if (!RegExp(r'^[A-Z]{2}[0-9]{2}').hasMatch(cleaned)) {
    return 'District code must be 2 digits after state code';
  }

  // Check if followed by 1-2 letters (Series)
  if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}').hasMatch(cleaned)) {
    return 'Invalid series code (should be 1-2 letters)';
  }

  // Check if ends with 4 digits (Registration number)
  if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$').hasMatch(cleaned)) {
    return 'Vehicle number must end with 4 digits';
  }

  return null;
}

Widget _buildValidatedDLInput({
  required TextEditingController controller,
  required String label,
  required String hint,
  bool enabled = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
          ),
        ),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          textCapitalization: TextCapitalization.characters,
          maxLength: 15,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: InputDecoration(
            hintText: hint,
            helperText: '15 characters (AA00 00000000000)',
            helperStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
            hintStyle: TextStyle(
              color: enabled ? Colors.grey[500] : Colors.grey[400],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '', // Hide the default counter
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter driving license number';
            }
            
            // Remove spaces and dashes for validation
            String cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
            
            // Check length
            if (cleaned.length != 15) {
              return 'Driving license must be exactly 15 characters';
            }
            
            // Validate Indian DL format: AA00 00000000000
            // First 2 characters should be letters (State code)
            if (!RegExp(r'^[A-Z]{2}').hasMatch(cleaned.toUpperCase())) {
              return 'DL must start with 2 letters (State code)';
            }
            
            // Next 2 characters should be digits (RTO code)
            if (!RegExp(r'^[A-Z]{2}[0-9]{2}').hasMatch(cleaned.toUpperCase())) {
              return 'Invalid DL format (RTO code must be 2 digits)';
            }
            
            // Remaining 11 characters should be digits
            if (!RegExp(r'^[A-Z]{2}[0-9]{13}$').hasMatch(cleaned.toUpperCase())) {
              return 'Invalid DL format (must be AA00 00000000000)';
            }
            
            return null;
          },
        ),
      ),
    ],
  );
}

}
class _VehicleNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert to uppercase
    String text = newValue.text.toUpperCase();
    
    // Return formatted value
    return TextEditingValue(
      text: text,
      selection: newValue.selection,
    );
  }
}