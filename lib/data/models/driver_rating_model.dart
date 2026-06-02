class DriverRating {
  final String driverId;
  final String avgRating;
  final int totalRatings;

  DriverRating({
    required this.driverId,
    required this.avgRating,
    required this.totalRatings,
  });

  factory DriverRating.fromJson(Map<String, dynamic> json) {
    return DriverRating(
      driverId: json['driverId'] ?? '',
      avgRating: json['avgRating'] ?? '0.00',
      totalRatings: json['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'avgRating': avgRating,
      'totalRatings': totalRatings,
    };
  }

  double get averageRatingAsDouble {
    return double.tryParse(avgRating) ?? 0.0;
  }

  String get formattedRating {
    final rating = averageRatingAsDouble;
    return rating.toStringAsFixed(1);
  }
}
