class RiderRatingRequest {
  final int rating;
  final String comment;

  RiderRatingRequest({
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
    };
  }
}

class RiderRatingResponse {
  final bool success;
  final String message;
  final RiderRating? riderRating;

  RiderRatingResponse({
    required this.success,
    required this.message,
    this.riderRating,
  });

  factory RiderRatingResponse.fromJson(Map<String, dynamic> json) {
    return RiderRatingResponse(
      success: json['success'] ?? false,
      message: json['msg'] ?? json['message'] ?? '',
      riderRating: json['riderRating'] != null
          ? RiderRating.fromJson(json['riderRating'])
          : null,
    );
  }
}

class RiderRating {
  final int rating;
  final String comment;

  RiderRating({
    required this.rating,
    required this.comment,
  });

  factory RiderRating.fromJson(Map<String, dynamic> json) {
    return RiderRating(
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
    };
  }
}
