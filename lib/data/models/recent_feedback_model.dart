class RecentFeedback {
  final String rideId;
  final Rider rider;
  final int rating;
  final String? feedback;
  final DateTime createdAt;

  RecentFeedback({
    required this.rideId,
    required this.rider,
    required this.rating,
    this.feedback,
    required this.createdAt,
  });

  factory RecentFeedback.fromJson(Map<String, dynamic> json) {
    return RecentFeedback(
      rideId: json['rideId'] ?? '',
      rider: Rider.fromJson(json['rider'] ?? {}),
      rating: json['rating'] ?? 0,
      feedback: json['feedback'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'rider': rider.toJson(),
      'rating': rating,
      'feedback': feedback,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class Rider {
  final String id;
  final String name;
  final String phone;

  Rider({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }
}

class RecentFeedbackResponse {
  final bool success;
  final int totalFeedbacks;
  final List<RecentFeedback> feedbacks;

  RecentFeedbackResponse({
    required this.success,
    required this.totalFeedbacks,
    required this.feedbacks,
  });

  factory RecentFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return RecentFeedbackResponse(
      success: json['success'] ?? false,
      totalFeedbacks: json['totalFeedbacks'] ?? 0,
      feedbacks: (json['feedbacks'] as List<dynamic>? ?? [])
          .map((item) => RecentFeedback.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'totalFeedbacks': totalFeedbacks,
      'feedbacks': feedbacks.map((feedback) => feedback.toJson()).toList(),
    };
  }
}
