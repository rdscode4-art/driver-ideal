import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/driver_rating_model.dart';
import '../data/models/recent_feedback_model.dart';
import '../services/rating_api_service.dart';
import '../services/recent_feedback_api_service.dart';
import '../services/driver_api_service.dart';
import '../core/utils/app_snackbar.dart';

class RatingFeedbackController extends GetxController {
  // Text controllers
  final feedbackController = TextEditingController();
  final contactController = TextEditingController();

  // Reactive variables
  var rating = 0.obs;
  var selectedCategories = <String>[].obs;
  var isSubmitting = false.obs;
  var previousFeedback = <Map<String, dynamic>>[].obs;

  // Driver rating state
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final driverRating = Rx<DriverRating?>(null);

  // Recent feedback state
  final isLoadingRecentFeedback = false.obs;
  final hasRecentFeedbackError = false.obs;
  final recentFeedbackErrorMessage = ''.obs;
  final recentFeedbacks = <RecentFeedback>[].obs;
  final totalFeedbacks = 0.obs;

  // Feedback categories
  final List<String> feedbackCategories = [
    'App Performance',
    'Ride Experience',
    'Payment Issues',
    'Customer Support',
    'Navigation',
    'Vehicle Quality',
    'Safety Concerns',
    'Feature Request',
    'Bug Report',
    'General Feedback'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchDriverRating();
    fetchRecentFeedback();
    loadPreviousFeedback();
  }

  @override
  void onClose() {
    feedbackController.dispose();
    contactController.dispose();
    super.onClose();
  }

  void setRating(int value) {
    rating.value = value;
  }

  String getFeedbackRatingText() {
    switch (rating.value) {
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
        return 'Tap to rate';
    }
  }

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }

  Future<void> submitFeedback() async {
    if (rating.value == 0) {
      showWarningSnackBar(
        'Please provide a rating before submitting',
        title: 'Rating Required',
      );
      return;
    }

    if (feedbackController.text.trim().isEmpty) {
      showWarningSnackBar(
        'Please provide your feedback before submitting',
        title: 'Feedback Required',
      );
      return;
    }

    try {
      isSubmitting.value = true;

      final feedbackData = {
        'rating': rating.value,
        'feedback': feedbackController.text.trim(),
        'categories': selectedCategories.toList(),
        'contact': contactController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await DriverApiService.submitFeedback(feedbackData);

      if (response.isSuccess) {
        showSuccessSnackBar(
          'Your feedback has been submitted successfully',
          title: 'Thank You!',
        );

        _clearForm();
        await loadPreviousFeedback();

        Future.delayed(const Duration(seconds: 2), () {
          Get.back();
        });
      } else {
        throw Exception(response.message ?? 'Failed to submit feedback');
      }
    } catch (e) {
      showErrorSnackBar(
        'Failed to submit feedback: ${e.toString()}',
        title: 'Error',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _clearForm() {
    rating.value = 0;
    feedbackController.clear();
    contactController.clear();
    selectedCategories.clear();
  }

  Future<void> loadPreviousFeedback() async {
    try {
      final response = await DriverApiService.getFeedbackHistory();

      if (response.isSuccess && response.data != null) {
        final feedbackList = response.data!['data'] as List<dynamic>? ?? [];
        previousFeedback.value = feedbackList.map((item) => {
          'rating': item['rating'] ?? 0,
          'feedback': item['feedback'] ?? '',
          'date': _formatDate(item['timestamp']),
          'status': item['status'] ?? 'Pending',
        }).toList();
      }
    } catch (e) {
      print('Error loading previous feedback: $e');
      // Set mock data for demo purposes
      previousFeedback.value = [
        {
          'rating': 5,
          'feedback': 'Great app! Very user-friendly and reliable.',
          'date': '2 days ago',
          'status': 'Resolved',
        },
        {
          'rating': 4,
          'feedback': 'Good experience overall, but could improve navigation accuracy.',
          'date': '1 week ago',
          'status': 'Under Review',
        },
      ];
    }
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown date';

      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Unknown date';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<void> fetchDriverRating() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await RatingApiService.getDriverRating();

      if (response.isSuccess && response.data != null) {
        final rating = RatingApiService.parseDriverRating(response.data!);
        if (rating != null) {
          driverRating.value = rating;
        } else {
          hasError.value = true;
          errorMessage.value = 'Failed to parse rating data';
        }
      } else {
        hasError.value = true;
        errorMessage.value = response.message ?? 'Failed to fetch rating';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'An error occurred: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRecentFeedback() async {
    try {
      isLoadingRecentFeedback.value = true;
      hasRecentFeedbackError.value = false;
      recentFeedbackErrorMessage.value = '';

      final response = await RecentFeedbackApiService.getRecentFeedback();

      if (response.isSuccess && response.data != null) {
        final feedbackResponse = RecentFeedbackApiService.parseRecentFeedback(response.data!);
        if (feedbackResponse != null) {
          recentFeedbacks.value = feedbackResponse.feedbacks;
          totalFeedbacks.value = feedbackResponse.totalFeedbacks;
        } else {
          hasRecentFeedbackError.value = true;
          recentFeedbackErrorMessage.value = 'Failed to parse feedback data';
        }
      } else {
        hasRecentFeedbackError.value = true;
        recentFeedbackErrorMessage.value = response.message ?? 'Failed to fetch recent feedback';
      }
    } catch (e) {
      hasRecentFeedbackError.value = true;
      recentFeedbackErrorMessage.value = 'An error occurred: ${e.toString()}';
    } finally {
      isLoadingRecentFeedback.value = false;
    }
  }

  Future<void> refreshRating() async {
    await fetchDriverRating();
  }

  Future<void> refreshRecentFeedback() async {
    await fetchRecentFeedback();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchDriverRating(),
      fetchRecentFeedback(),
      loadPreviousFeedback(),
    ]);
  }

  // Helper methods for UI
  String get displayRating {
    return driverRating.value?.formattedRating ?? '0.0';
  }

  int get totalRatings {
    return driverRating.value?.totalRatings ?? 0;
  }

  double get ratingProgress {
    final rating = driverRating.value?.averageRatingAsDouble ?? 0.0;
    return rating / 5.0;
  }

  Color getRatingColor() {
    final rating = driverRating.value?.averageRatingAsDouble ?? 0.0;
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.blue;
    if (rating >= 3.5) return Colors.orange;
    return Colors.red;
  }

  IconData getRatingIcon() {
    final rating = driverRating.value?.averageRatingAsDouble ?? 0.0;
    if (rating >= 4.5) return Icons.star;
    if (rating >= 4.0) return Icons.star_half;
    if (rating >= 3.5) return Icons.star_border;
    return Icons.star_outline;
  }

  String getRatingText() {
    final rating = driverRating.value?.averageRatingAsDouble ?? 0.0;
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Good';
    if (rating >= 3.5) return 'Average';
    if (rating >= 2.0) return 'Below Average';
    return 'Poor';
  }
}
