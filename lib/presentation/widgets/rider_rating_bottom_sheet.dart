import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/rider_rating_controller.dart';

class RiderRatingBottomSheet extends StatelessWidget {
  final String rideId;
  final String? riderName;
  final VoidCallback? onComplete;

  const RiderRatingBottomSheet({
    super.key,
    required this.rideId,
    this.riderName,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RiderRatingController());
    controller.initializeForRide(rideId, passengerName: riderName);

    return WillPopScope(
      onWillPop: () async => false, // Non-dismissible
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          if (controller.isRatingComplete) {
            return _buildCompletionWidget(controller);
          }
          return _buildRatingWidget(controller);
        }),
      ),
    );
  }

  Widget _buildRatingWidget(RiderRatingController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        _buildHeader(controller),
        const SizedBox(height: 24),

        // Star Rating
        _buildStarRating(controller),
        const SizedBox(height: 16),

        // Rating Description
        _buildRatingDescription(controller),
        const SizedBox(height: 24),

        // Comment Section
        _buildCommentSection(controller),
        const SizedBox(height: 24),

        // Error Message
        Obx(() {
          if (controller.hasError.value) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Action Buttons
        _buildActionButtons(controller),

        // Safe area for bottom
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeader(RiderRatingController controller) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Icon(Icons.star_rounded, size: 48, color: Colors.amber),
        const SizedBox(height: 12),
        const Text(
          'Rate Your Rider',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            'How was your experience with ${controller.riderName.value}?',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(RiderRatingController controller) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starValue = index + 1;
          final isSelected = starValue <= controller.selectedRating.value;
          final isHovered = starValue <= controller.selectedRating.value;

          return GestureDetector(
            onTap: () => controller.setRating(starValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: isSelected
                    ? controller.getRatingColor(starValue)
                    : Colors.grey[300],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRatingDescription(RiderRatingController controller) {
    return Obx(() {
      final rating = controller.selectedRating.value;
      if (rating == 0) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Text(
          controller.getRatingDescription(rating),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: controller.getRatingColor(rating),
          ),
        ),
      );
    });
  }

  Widget _buildCommentSection(RiderRatingController controller) {
    return Obx(() {
      if (controller.selectedRating.value == 0) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Comments (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              maxLength: 200,
              onChanged: controller.updateComment,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[400]!),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButtons(RiderRatingController controller) {
    return Obx(
      () => Row(
        children: [
          // Skip Button
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () {
                      controller.skipRating();
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Submit Button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: controller.canSubmitRating
                  ? () async {
                      final success = await controller.submitRating();
                      if (success) {
                        // Keep the bottom sheet open to show completion state
                        await Future.delayed(const Duration(seconds: 2));
                        onComplete?.call();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.canSubmitRating
                    ? Colors.blue[600]
                    : Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: controller.canSubmitRating ? 2 : 0,
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
                        SizedBox(width: 8),
                        Text(
                          'Submitting...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: controller.canSubmitRating
                            ? Colors.white
                            : Colors.grey[500],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionWidget(RiderRatingController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Thank You!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your rating has been submitted successfully',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              onComplete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Show the non-dismissible rider rating bottom sheet
void showRiderRatingBottomSheet({
  required String rideId,
  String? riderName,
  VoidCallback? onComplete,
}) {
  Get.bottomSheet(
    RiderRatingBottomSheet(
      rideId: rideId,
      riderName: riderName,
      onComplete: onComplete,
    ),
    isDismissible: false, // Non-dismissible
    enableDrag: false, // Disable drag to dismiss
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}
