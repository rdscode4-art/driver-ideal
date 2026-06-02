import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rideal_driver/presentation/kycdocumentsviewcontroller.dart';

class KYCDocumentsViewerScreen extends StatelessWidget {
  const KYCDocumentsViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KYCDocumentsViewerController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: Colors.orange[500],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchDocuments(),
            tooltip: 'Refresh',
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
                SizedBox(height: 16),
                Text('Loading documents...'),
              ],
            ),
          );
        }

        if (controller.hasError.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: controller.fetchDocuments,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchDocuments,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verification Status Card
                _buildStatusCard(controller),

                const SizedBox(height: 20),

                // Personal Documents Section
                Text(
                  'Personal Documents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Aadhaar Card with multiple images support
                _buildDocumentCard(
                  icon: Icons.badge_outlined,
                  title: 'Aadhaar Card',
                  number: controller.maskedAadhaar,
                  imageUrl: controller.aadhaarImages.isNotEmpty
                      ? controller.aadhaarImages.first
                      : '',
                  color: Colors.orange,
                  onTap: controller.aadhaarImages.isNotEmpty
                      ? () => _showAadhaarGallery(
                            context,
                            controller.aadhaarImages,
                          )
                      : null,
                  hasMultipleImages: controller.aadhaarImages.length > 1,
                  imageCount: controller.aadhaarImages.length,
                ),

                const SizedBox(height: 12),

                // Driving License
                _buildDocumentCard(
                  icon: Icons.credit_card,
                  title: 'Driving License',
                  number: controller.maskedDL,
                  imageUrl: controller.dlImage.value,
                  color: Colors.blue,
                  onTap: controller.dlImage.value.isNotEmpty
                      ? () => _showImageDialog(
                            context,
                            controller.dlImage.value,
                            'Driving License',
                          )
                      : null,
                ),

                const SizedBox(height: 20),

                // Vehicle Documents Section
                Text(
                  'Vehicle Documents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Vehicle Details Card
                _buildVehicleDetailsCard(controller),

                const SizedBox(height: 12),

                // Vehicle Photo
                _buildDocumentCard(
                  icon: Icons.directions_car,
                  title: 'Vehicle Photo',
                  number: controller.vehicleName.value.isNotEmpty
                      ? controller.vehicleName.value
                      : 'Not Available',
                  imageUrl: controller.vehicleImage.value,
                  color: Colors.purple,
                  onTap: controller.vehicleImage.value.isNotEmpty
                      ? () => _showImageDialog(
                            context,
                            controller.vehicleImage.value,
                            'Vehicle Photo',
                          )
                      : null,
                ),

                const SizedBox(height: 12),

                // Vehicle RC
                _buildDocumentCard(
                  icon: Icons.description,
                  title: 'Registration Certificate (RC)',
                  number: controller.vehicleNumber.value.isNotEmpty
                      ? controller.vehicleNumber.value
                      : 'Not Available',
                  imageUrl: controller.vehicleRC.value,
                  color: Colors.green,
                  onTap: controller.vehicleRC.value.isNotEmpty
                      ? () => _showImageDialog(
                            context,
                            controller.vehicleRC.value,
                            'Registration Certificate',
                          )
                      : null,
                ),

                const SizedBox(height: 12),

                // Vehicle Insurance
                _buildDocumentCard(
                  icon: Icons.shield,
                  title: 'Vehicle Insurance',
                  number: 'Insurance Document',
                  imageUrl: controller.vehicleInsurance.value,
                  color: Colors.teal,
                  onTap: controller.vehicleInsurance.value.isNotEmpty
                      ? () => _showImageDialog(
                            context,
                            controller.vehicleInsurance.value,
                            'Vehicle Insurance',
                          )
                      : null,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Show Aadhaar gallery with multiple images (front & back)
  void _showAadhaarGallery(BuildContext context, List<String> images) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 500,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aadhaar Card',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Image gallery
              Expanded(
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Image ${index + 1} of ${images.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.contain,
                              loadingBuilder: (c, w, p) => p == null
                                  ? w
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              errorBuilder: (c, e, s) {
                                print('❌ Image load error: $e');
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      size: 50,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Footer hint
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe to view front & back',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(KYCDocumentsViewerController controller) {
    final statusColor = controller.getStatusColor();
    final statusIcon = controller.getStatusIcon();
    final statusText = controller.getStatusText();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC Verification Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (controller.submittedAt.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Submitted: ${controller.submittedAt.value}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
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

  Widget _buildVehicleDetailsCard(KYCDocumentsViewerController controller) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.indigo,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Vehicle Number',
              controller.vehicleNumber.value,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Vehicle Type',
              controller.vehicleType.value.toUpperCase(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Vehicle Name',
              controller.vehicleName.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'Not Available',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required IconData icon,
    required String title,
    required String number,
    required String imageUrl,
    required Color color,
    VoidCallback? onTap,
    bool hasMultipleImages = false,
    int imageCount = 0,
  }) {
    bool hasImage = imageUrl.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: hasImage ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (hasImage)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasMultipleImages
                                  ? 'Tap to view $imageCount images'
                                  : 'Tap to view document',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (hasImage)
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Image load error: $error');
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}