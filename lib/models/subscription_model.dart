class SubscriptionStatusModel {
  final String planName;
  final int amount;
  final String duration;
  final String status;
  final String expiry;

  SubscriptionStatusModel({
    required this.planName,
    required this.amount,
    required this.duration,
    required this.status,
    required this.expiry,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      planName: json['planName'] ?? '',
      amount: json['amount'] ?? 0,
      duration: json['duration'] ?? '',
      status: json['status'] ?? '',
      expiry: json['expiry'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planName': planName,
      'amount': amount,
      'duration': duration,
      'status': status,
      'expiry': expiry,
    };
  }

  bool get isActive => status.toLowerCase() == 'active';

  DateTime? get expiryDate {
    try {
      return DateTime.parse(expiry);
    } catch (e) {
      return null;
    }
  }

  String get formattedExpiry {
    final date = expiryDate;
    if (date == null) return expiry;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  String toString() {
    return 'SubscriptionStatusModel(planName: $planName, amount: $amount, duration: $duration, status: $status, expiry: $expiry)';
  }
}
