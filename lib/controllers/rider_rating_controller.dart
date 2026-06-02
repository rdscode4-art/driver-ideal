import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/rides_api_service.dart';
import '../core/utils/app_snackbar.dart';

class RiderRatingController extends GetxController {
  final RidesApiService _ridesApiService = RidesApiService();

  // Observable variables
  var isLoading = false.obs;
  var selectedRating = 0.obs;
  var comment = ''.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Rating submission state
  var isSubmitting = false.obs;
  var hasSubmitted = false.obs;

  // Current ride information
  var currentRideId = ''.obs;
  var riderName = 'Rider'.obs;

  @override
  void onInit() {
    super.onInit();
    _resetRating();
  }

  /// Initialize rating for a specific ride
  void initializeForRide(String rideId, {String? passengerName}) {
    currentRideId.value = rideId;
    riderName.value = passengerName ?? 'Rider';
    _resetRating();
    log('🌟 Initialized rating controller for ride: $rideId');
  }

  /// Reset rating state
  void _resetRating() {
    selectedRating.value = 0;
    comment.value = '';
    hasError.value = false;
    errorMessage.value = '';
    isSubmitting.value = false;
    hasSubmitted.value = false;
  }

  /// Set the selected rating (1-5 stars)
  void setRating(int rating) {
    if (rating >= 1 && rating <= 5) {
      selectedRating.value = rating;
      hasError.value = false;
      errorMessage.value = '';
      log('⭐ Rating selected: $rating stars');
    }
  }

  /// Update comment text
  void updateComment(String newComment) {
    comment.value = newComment.trim();
  }

  /// Validate rating input
  bool _validateRating() {
    if (selectedRating.value < 1 || selectedRating.value > 5) {
      hasError.value = true;
      errorMessage.value = 'Please select a rating from 1 to 5 stars';
      return false;
    }

    if (currentRideId.value.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'Invalid ride information';
      return false;
    }

    return true;
  }

  /// Submit rating to the API
  Future<bool> submitRating() async {
  try {
    if (!_validateRating()) {
      return false;
    }

    isSubmitting.value = true;
    hasError.value = false;
    errorMessage.value = '';

    // DETAILED LOGGING
    log('📤 ===== SUBMITTING RIDER RATING =====');
    log('🆔 Ride ID: ${currentRideId.value}');
    log('⭐ Rating: ${selectedRating.value}');
    log('💬 Comment: "${comment.value}"');
    log('📝 Comment empty: ${comment.value.isEmpty}');
    
    final response = await _ridesApiService.rateRider(
      rideId: currentRideId.value,
      rating: selectedRating.value,
      comment: comment.value.isNotEmpty ? comment.value : null,
    );

    // LOG FULL API RESPONSE
    log('📥 ===== API RESPONSE =====');
    log('📥 Full response: $response');
    log('📥 Success value: ${response['success']}');
    log('📥 Message: ${response['message']}');
    log('📥 Response type: ${response.runtimeType}');
    log('📥 Keys in response: ${response.keys.toList()}');

    if (response['success'] == true) {
      hasSubmitted.value = true;
      
      showSuccessSnackBar(
        response['message'] ?? 'Thank you for rating the rider!',
        title: 'Rating Submitted',
      );
      
      log('✅ Rating submitted successfully');
      return true;
    } else {
      // DETAILED ERROR LOGGING
      hasError.value = true;
      errorMessage.value = response['message'] ?? 'Failed to submit rating';
      
      log('❌ ===== RATING FAILED =====');
      log('❌ Error message: ${errorMessage.value}');
      log('❌ Success field is: ${response['success']}');
      log('❌ Full response data: $response');
      
      showErrorSnackBar(
        errorMessage.value,
        title: 'Rating Failed',
      );
      
      return false;
    }
  } catch (e, stackTrace) {
    hasError.value = true;
    errorMessage.value = 'Network error occurred';
    
    log('❌ ===== EXCEPTION OCCURRED =====');
    log('❌ Exception: $e');
    log('❌ Stack trace: $stackTrace');
    
    showErrorSnackBar(
      'Unable to submit rating. Please check your connection.',
      title: 'Network Error',
    );
    
    return false;
  } finally {
    isSubmitting.value = false;
  }
}


  /// Skip rating (optional action)
  void skipRating() {
    log('⏭️ Rating skipped for ride: ${currentRideId.value}');
    hasSubmitted.value = true;

    showInfoSnackBar(
      'You can rate riders later from ride history',
      title: 'Rating Skipped',
    );
  }

  /// Get rating description based on stars
  String getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Select Rating';
    }
  }

  /// Get rating color based on stars
  Color getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Check if current rating is valid for submission
  bool get canSubmitRating => selectedRating.value > 0 && !isSubmitting.value;

  /// Check if rating process is complete
  bool get isRatingComplete => hasSubmitted.value;
}
