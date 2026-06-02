class SubscriptionStatusModel {
  final bool isSubscribed;
  final String status;
  final String? planId;
  final String? planName;
  final int? planRate;
  final int? durationInMonths;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? message;

  SubscriptionStatusModel({
    required this.isSubscribed,
    required this.status,
    this.planId,
    this.planName,
    this.planRate,
    this.durationInMonths,
    this.startDate,
    this.endDate,
    this.message,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      isSubscribed: json['subscribed'] ?? false,
      status: json['subscribed'] == true ? 'active' : 'not_subscribed',
      planId: json['plan']?['_id'],
      planName: json['plan']?['title'] ?? 'Premium Plan',
      planRate: json['plan']?['rate'],
      durationInMonths: json['plan']?['durationInMonths'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      message: json['message'],
    );
  }

  factory SubscriptionStatusModel.empty() {
    return SubscriptionStatusModel(
      isSubscribed: false,
      status: 'not_subscribed',
    );
  }

  bool get isActive => isSubscribed && status == 'active';
  
  String get displayName => planName ?? 'Premium Plan';
  
  String get formattedStartDate {
    if (startDate == null) return 'N/A';
    return '${startDate!.day}/${startDate!.month}/${startDate!.year}';
  }
  
  String get formattedEndDate {
    if (endDate == null) return 'N/A';
    return '${endDate!.day}/${endDate!.month}/${endDate!.year}';
  }
  
  int get daysRemaining {
    if (endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  @override
  String toString() {
    return 'SubscriptionStatusModel(isSubscribed: $isSubscribed, status: $status, planName: $planName)';
  }
}