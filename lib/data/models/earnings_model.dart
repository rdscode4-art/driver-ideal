class Earnings {
  final double total;
  final double today;
  final double week;
  final double month;

  Earnings({
    required this.total,
    required this.today,
    required this.week,
    required this.month,
  });

  /// Create an empty Earnings object
  factory Earnings.empty() {
    return Earnings(
      total: 0.0,
      today: 0.0,
      week: 0.0,
      month: 0.0,
    );
  }

  /// Create Earnings from JSON
  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      total: (json['total'] ?? 0).toDouble(),
      today: (json['today'] ?? 0).toDouble(),
      week: (json['week'] ?? 0).toDouble(),
      month: (json['month'] ?? 0).toDouble(),
    );
  }

  /// Convert Earnings to JSON
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'today': today,
      'week': week,
      'month': month,
    };
  }

  /// Copy with method for updating specific fields
  Earnings copyWith({
    double? total,
    double? today,
    double? week,
    double? month,
  }) {
    return Earnings(
      total: total ?? this.total,
      today: today ?? this.today,
      week: week ?? this.week,
      month: month ?? this.month,
    );
  }

  /// Check if earnings data is empty
  bool get isEmpty => total == 0.0 && today == 0.0 && week == 0.0 && month == 0.0;

  /// Check if earnings data is not empty
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'Earnings(total: $total, today: $today, week: $week, month: $month)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Earnings &&
      other.total == total &&
      other.today == today &&
      other.week == week &&
      other.month == month;
  }

  @override
  int get hashCode {
    return total.hashCode ^
      today.hashCode ^
      week.hashCode ^
      month.hashCode;
  }
}