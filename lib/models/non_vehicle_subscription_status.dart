/// Response model for subscription status API
///
/// This model represents the response from:
/// GET /api/non-vehicle-driver/status/{driverId}
class NonVehicleSubscriptionStatus {
  /// Indicates if driver has an active subscription
  final bool subscribed;

  /// Current subscription plan details (if subscribed)
  final SubscriptionPlan? plan;

  /// Subscription start date (if subscribed)
  final DateTime? startDate;

  /// Subscription end date (if subscribed)
  final DateTime? endDate;

  /// Current subscription status
  final String? status;

  /// Driver ID for this subscription status
  final String? driverId;

  /// Last updated timestamp
  final DateTime? updatedAt;

  /// Subscription ID
  final String? subscriptionId;

  const NonVehicleSubscriptionStatus({
    required this.subscribed,
    this.plan,
    this.startDate,
    this.endDate,
    this.status,
    this.driverId,
    this.updatedAt,
    this.subscriptionId,
  });

  /// Create from JSON response
  factory NonVehicleSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return NonVehicleSubscriptionStatus(
      subscribed: json['subscribed'] == true,
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'])
          : null,
      startDate: _parseDateTime(json['startDate'] ?? json['start_date']),
      endDate: _parseDateTime(json['endDate'] ?? json['end_date']),
      status: json['status']?.toString(),
      driverId: json['driverId']?.toString() ?? json['driver_id']?.toString(),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      subscriptionId:
          json['subscriptionId']?.toString() ??
          json['subscription_id']?.toString(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'subscribed': subscribed,
      if (plan != null) 'plan': plan!.toJson(),
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (status != null) 'status': status,
      if (driverId != null) 'driverId': driverId,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
    };
  }

  /// Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;

    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        print('⚠️ Failed to parse date: $dateTime');
        return null;
      }
    }
    if (dateTime is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    }

    return null;
  }

  /// Factory constructor for no subscription state
  factory NonVehicleSubscriptionStatus.noSubscription({String? driverId}) {
    return NonVehicleSubscriptionStatus(
      subscribed: false,
      driverId: driverId,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if subscription is currently active and not expired
  bool get isActive {
    if (!subscribed) return false;

    final now = DateTime.now();

    // Check if we have end date and it's not expired
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    // Check if we have start date and it's started
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    // Check status if available
    if (status != null) {
      final lowerStatus = status!.toLowerCase();
      return lowerStatus == 'active' || lowerStatus == 'valid';
    }

    return true; // Default to active if subscribed and no contradicting info
  }

  /// Check if subscription is expired
  bool get isExpired {
    if (!subscribed) return false;

    if (endDate != null) {
      return DateTime.now().isAfter(endDate!);
    }

    // Check status for expired states
    if (status != null) {
      final lowerStatus = status!.toLowerCase();
      return lowerStatus == 'expired' ||
          lowerStatus == 'cancelled' ||
          lowerStatus == 'inactive';
    }

    return false;
  }

  /// Get remaining days in subscription
  int get remainingDays {
    if (!isActive || endDate == null) return 0;

    final now = DateTime.now();
    final difference = endDate!.difference(now);

    return difference.inDays;
  }

  /// Get formatted remaining time
  String get formattedRemainingTime {
    if (!isActive) {
      if (isExpired) return 'Expired';
      return 'No active subscription';
    }

    final remaining = remainingDays;

    if (remaining <= 0) return 'Expires today';
    if (remaining == 1) return '1 day remaining';
    if (remaining <= 30) return '$remaining days remaining';

    final months = remaining ~/ 30;
    if (months == 1) return '1 month remaining';
    return '$months months remaining';
  }

  /// Get status display text
  String get statusDisplayText {
    if (!subscribed) return 'No Subscription';
    if (isActive) return 'Active';
    if (isExpired) return 'Expired';
    return status?.toUpperCase() ?? 'Unknown';
  }

  /// Get status color for UI (as string for easy parsing)
  String get statusColor {
    if (!subscribed) return 'grey';
    if (isActive) {
      if (remainingDays <= 7) return 'orange'; // Expiring soon
      return 'green'; // Active
    }
    if (isExpired) return 'red';
    return 'grey';
  }

  /// Check if subscription is expiring soon (within 7 days)
  bool get isExpiringSoon {
    return isActive && remainingDays > 0 && remainingDays <= 7;
  }

  /// Get subscription summary for display
  String get summaryText {
    if (!subscribed) return 'No active subscription';

    if (plan != null) {
      final planName = plan!.title;
      final timeInfo = formattedRemainingTime;
      return '$planName - $timeInfo';
    }

    return formattedRemainingTime;
  }

  @override
  String toString() {
    return 'NonVehicleSubscriptionStatus(subscribed: $subscribed, '
        'isActive: $isActive, plan: ${plan?.title}, remainingDays: $remainingDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NonVehicleSubscriptionStatus &&
        other.subscribed == subscribed &&
        other.plan == plan &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.status == status &&
        other.driverId == driverId &&
        other.updatedAt == updatedAt &&
        other.subscriptionId == subscriptionId;
  }

  @override
  int get hashCode {
    return Object.hash(
      subscribed,
      plan,
      startDate,
      endDate,
      status,
      driverId,
      updatedAt,
      subscriptionId,
    );
  }

  /// Create a copy with updated values
  NonVehicleSubscriptionStatus copyWith({
    bool? subscribed,
    SubscriptionPlan? plan,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? driverId,
    DateTime? updatedAt,
    String? subscriptionId,
  }) {
    return NonVehicleSubscriptionStatus(
      subscribed: subscribed ?? this.subscribed,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }
}

/// Subscription plan model for status response
class SubscriptionPlan {
  /// Plan unique identifier
  final String id;

  /// Plan title/name
  final String title;

  /// Plan description
  final String? description;

  /// Duration in months
  final int durationInMonths;

  /// Plan rate/price in rupees
  final int rate;

  /// Plan features list
  final List<String> features;

  /// Plan category
  final String? category;

  /// Plan type (e.g., 'basic', 'premium')
  final String? type;

  /// Whether this plan is currently available
  final bool isAvailable;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    this.description,
    required this.durationInMonths,
    required this.rate,
    this.features = const [],
    this.category,
    this.type,
    this.isAvailable = true,
  });

  /// Create from JSON response
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Plan',
      description: json['description']?.toString(),
      durationInMonths:
          _parseInt(json['durationInMonths'] ?? json['duration']) ?? 1,
      rate: _parseInt(json['rate'] ?? json['price']) ?? 0,
      features: _parseStringList(json['features']),
      category: json['category']?.toString(),
      type: json['type']?.toString(),
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'durationInMonths': durationInMonths,
      'rate': rate,
      'features': features,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      'isAvailable': isAvailable,
    };
  }

  /// Helper method to safely parse integers
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper method to parse string list from various formats
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String) {
      // Try to parse as comma-separated values
      return value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Get formatted price display
  String get formattedPrice {
    return '₹$rate';
  }

  /// Get formatted duration display
  String get formattedDuration {
    if (durationInMonths == 1) return '1 month';
    if (durationInMonths == 12) return '1 year';
    if (durationInMonths % 12 == 0) {
      final years = durationInMonths ~/ 12;
      return years == 1 ? '1 year' : '$years years';
    }
    return '$durationInMonths months';
  }

  /// Get monthly price (for display purposes)
  double get monthlyPrice {
    return rate / durationInMonths;
  }

  /// Get formatted monthly price
  String get formattedMonthlyPrice {
    return '₹${monthlyPrice.toStringAsFixed(0)}/month';
  }

  /// Check if this is a long-term plan (6+ months)
  bool get isLongTerm {
    return durationInMonths >= 6;
  }

  /// Check if this is an annual plan
  bool get isAnnual {
    return durationInMonths == 12;
  }

  /// Get savings percentage compared to monthly rate (if applicable)
  double? getSavingsPercentage(double monthlyRate) {
    if (monthlyRate <= 0 || durationInMonths <= 1) return null;

    final totalMonthlyPrice = monthlyRate * durationInMonths;
    final savings = totalMonthlyPrice - rate;
    return (savings / totalMonthlyPrice) * 100;
  }

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, title: $title, rate: ₹$rate, duration: $formattedDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubscriptionPlan &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.durationInMonths == durationInMonths &&
        other.rate == rate &&
        other.features.toString() == features.toString() &&
        other.category == category &&
        other.type == type &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      durationInMonths,
      rate,
      features,
      category,
      type,
      isAvailable,
    );
  }

  /// Create a copy with updated values
  SubscriptionPlan copyWith({
    String? id,
    String? title,
    String? description,
    int? durationInMonths,
    int? rate,
    List<String>? features,
    String? category,
    String? type,
    bool? isAvailable,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationInMonths: durationInMonths ?? this.durationInMonths,
      rate: rate ?? this.rate,
      features: features ?? this.features,
      category: category ?? this.category,
      type: type ?? this.type,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
