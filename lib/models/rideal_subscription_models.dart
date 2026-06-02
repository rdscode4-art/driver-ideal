/// Subscription Plan Model for available plans
class RidealSubscriptionPlan {
  final String id;
  final String title;
  final int rate;
  final int durationInMonths;
  final String? description;
  final List<String>? features;
  final bool isPopular;

  RidealSubscriptionPlan({
    required this.id,
    required this.title,
    required this.rate,
    required this.durationInMonths,
    this.description,
    this.features,
    this.isPopular = false,
  });

  /// Create from JSON (for API responses)
  factory RidealSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return RidealSubscriptionPlan(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Unknown Plan',
      rate: (json['rate'] ?? 0).toInt(),
      durationInMonths: (json['durationInMonths'] ?? 1).toInt(),
      description: json['description'],
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : null,
      isPopular: json['isPopular'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'rate': rate,
      'durationInMonths': durationInMonths,
      'description': description,
      'features': features,
      'isPopular': isPopular,
    };
  }

  /// Get formatted monthly rate
  String get formattedMonthlyRate {
    if (durationInMonths <= 1) {
      return '₹$rate/month';
    }
    final monthlyRate = (rate / durationInMonths).round();
    return '₹$monthlyRate/month';
  }

  /// Get formatted total price
  String get formattedTotalPrice => '₹$rate';

  /// Get formatted duration
  String get formattedDuration {
    if (durationInMonths == 1) {
      return '1 Month';
    } else if (durationInMonths == 12) {
      return '1 Year';
    } else {
      return '$durationInMonths Months';
    }
  }

  /// Get savings compared to monthly rate
  String? getSavingsText(int monthlyRate) {
    if (durationInMonths <= 1) return null;

    final totalMonthlyPrice = monthlyRate * durationInMonths;
    final savings = totalMonthlyPrice - rate;

    if (savings > 0) {
      return 'Save ₹$savings';
    }
    return null;
  }
}

/// Active Subscription Status Model
class RidealSubscriptionStatus {
  final bool isSubscribed;
  final RidealSubscriptionPlan? plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status; // active, expired, cancelled

  RidealSubscriptionStatus({
    required this.isSubscribed,
    this.plan,
    this.startDate,
    this.endDate,
    this.status,
  });

  /// Create from API response
  factory RidealSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return RidealSubscriptionStatus(
      isSubscribed: json['subscribed'] ?? false,
      plan: json['plan'] != null
          ? RidealSubscriptionPlan.fromJson(json['plan'])
          : null,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      status:
          json['status'] ??
          (json['subscribed'] == true ? 'active' : 'inactive'),
    );
  }

  /// Empty status for no subscription
  factory RidealSubscriptionStatus.empty() {
    return RidealSubscriptionStatus(isSubscribed: false, status: 'inactive');
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'subscribed': isSubscribed,
      'plan': plan?.toJson(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
    };
  }

  /// Check if subscription is active
  bool get isActive {
    if (!isSubscribed) return false;
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  /// Check if subscription is expired
  bool get isExpired {
    if (!isSubscribed) return false;
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Get days remaining
  int get daysRemaining {
    if (!isActive || endDate == null) return 0;
    final difference = endDate!.difference(DateTime.now());
    return difference.inDays.clamp(0, double.infinity).toInt();
  }

  /// Get formatted start date
  String get formattedStartDate {
    if (startDate == null) return 'Unknown';
    return '${startDate!.day}/${startDate!.month}/${startDate!.year}';
  }

  /// Get formatted end date
  String get formattedEndDate {
    if (endDate == null) return 'No expiry';
    return '${endDate!.day}/${endDate!.month}/${endDate!.year}';
  }

  /// Get subscription display title
  String get displayTitle {
    if (!isSubscribed || plan == null) return 'No Active Subscription';
    return plan!.title;
  }

  /// Get subscription display subtitle
  String get displaySubtitle {
    if (!isActive) return 'Select a plan to get started';

    if (daysRemaining > 0) {
      return 'Valid until $formattedEndDate • $daysRemaining days left';
    } else if (isExpired) {
      return 'Expired on $formattedEndDate';
    } else {
      return 'Active subscription';
    }
  }

  /// Get status color for UI
  String get statusColor {
    if (!isSubscribed) return 'grey';
    if (isExpired) return 'red';
    if (daysRemaining <= 7) return 'orange';
    return 'green';
  }
}

/// Razorpay Order Model
class RazorpayOrder {
  final String orderId;
  final int amount;
  final String currency;
  final DateTime createdAt;

  RazorpayOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from API response
  factory RazorpayOrder.fromJson(Map<String, dynamic> json) {
    return RazorpayOrder(
      orderId: json['orderId'] ?? json['order_id'] ?? '',
      amount: (json['amount'] ?? 0).toInt(),
      currency: json['currency'] ?? 'INR',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get amount in rupees (Razorpay uses paise)
  int get amountInPaise => amount * 100;

  /// Get formatted amount
  String get formattedAmount => '₹$amount';
}
