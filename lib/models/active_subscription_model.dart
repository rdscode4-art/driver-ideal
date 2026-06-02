class ActiveSubscriptionModel {
  final String planName;
  final int amount;
  final String duration;
  final String status;
  final DateTime expiry;

  ActiveSubscriptionModel({
    required this.planName,
    required this.amount,
    required this.duration,
    required this.status,
    required this.expiry,
  });

  factory ActiveSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ActiveSubscriptionModel(
      planName: json['plan_name'] ?? json['planName'] ?? '',
      amount: json['plan_rate'] ?? json['amount'] ?? 0,
      duration: json['plan_duration'] != null
          ? '${json['plan_duration']} ${json['plan_duration'] == 1 ? 'Month' : 'Months'}'
          : json['duration'] ?? '',
      status: json['status'] ?? '',
      expiry: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : json['expiry'] != null
          ? DateTime.parse(json['expiry'])
          : DateTime.now(),
    );
  }

  bool get isActive =>
      status.toLowerCase() == 'active' && expiry.isAfter(DateTime.now());

  int get daysRemaining {
    final remaining = expiry.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  String get formattedExpiry {
    return '${expiry.day}/${expiry.month}/${expiry.year}';
  }
}
