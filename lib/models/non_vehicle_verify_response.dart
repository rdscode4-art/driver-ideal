/// Response model for payment verification API
///
/// This model represents the response from:
/// POST /api/non-vehicle-driver/verify-payment
class NonVehicleVerifyResponse {
  /// Indicates if payment verification was successful
  final bool success;

  /// Success or error message from backend
  final String message;

  /// Subscription details after successful payment
  final SubscriptionDetails? subscription;

  /// Transaction details
  final TransactionDetails? transaction;

  /// Verification timestamp
  final DateTime? verifiedAt;

  const NonVehicleVerifyResponse({
    required this.success,
    required this.message,
    this.subscription,
    this.transaction,
    this.verifiedAt,
  });

  /// Create from JSON response
  factory NonVehicleVerifyResponse.fromJson(Map<String, dynamic> json) {
    return NonVehicleVerifyResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Payment verification completed',
      subscription: json['subscription'] != null
          ? SubscriptionDetails.fromJson(json['subscription'])
          : null,
      transaction: json['transaction'] != null
          ? TransactionDetails.fromJson(json['transaction'])
          : null,
      verifiedAt: _parseDateTime(json['verifiedAt'] ?? json['verified_at']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (subscription != null) 'subscription': subscription!.toJson(),
      if (transaction != null) 'transaction': transaction!.toJson(),
      if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
    };
  }

  /// Helper method to safely parse DateTime
  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;

    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) return DateTime.tryParse(dateTime);
    if (dateTime is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    }

    return null;
  }

  /// Check if verification was successful and subscription is active
  bool get isSubscriptionActive {
    return success && subscription != null && subscription!.isActive;
  }

  @override
  String toString() {
    return 'NonVehicleVerifyResponse(success: $success, message: $message, '
        'hasSubscription: ${subscription != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NonVehicleVerifyResponse &&
        other.success == success &&
        other.message == message &&
        other.subscription == subscription &&
        other.transaction == transaction &&
        other.verifiedAt == verifiedAt;
  }

  @override
  int get hashCode {
    return Object.hash(success, message, subscription, transaction, verifiedAt);
  }
}

/// Subscription details from verification response
class SubscriptionDetails {
  /// Subscription ID
  final String id;

  /// Driver ID who owns this subscription
  final String driverId;

  /// Plan details
  final PlanDetails plan;

  /// Subscription start date
  final DateTime startDate;

  /// Subscription end date
  final DateTime endDate;

  /// Current subscription status
  final String status;

  /// Payment reference ID
  final String? paymentId;

  const SubscriptionDetails({
    required this.id,
    required this.driverId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.paymentId,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      plan: PlanDetails.fromJson(json['plan'] ?? {}),
      startDate: DateTime.parse(
        json['startDate']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        json['endDate']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      status: json['status']?.toString() ?? 'active',
      paymentId: json['paymentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'plan': plan.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      if (paymentId != null) 'paymentId': paymentId,
    };
  }

  /// Check if subscription is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == 'active' &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  /// Get remaining days in subscription
  int get remainingDays {
    if (!isActive) return 0;

    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inDays;
  }

  /// Get formatted remaining time
  String get formattedRemainingTime {
    if (!isActive) return 'Expired';

    final remaining = remainingDays;
    if (remaining <= 0) return 'Expires today';
    if (remaining == 1) return '1 day remaining';
    return '$remaining days remaining';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubscriptionDetails &&
        other.id == id &&
        other.driverId == driverId &&
        other.plan == plan &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.status == status &&
        other.paymentId == paymentId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      driverId,
      plan,
      startDate,
      endDate,
      status,
      paymentId,
    );
  }
}

/// Plan details within subscription
class PlanDetails {
  /// Plan ID
  final String id;

  /// Plan title/name
  final String title;

  /// Plan description
  final String? description;

  /// Duration in months
  final int durationInMonths;

  /// Plan rate/price
  final int rate;

  /// Plan features list
  final List<String> features;

  const PlanDetails({
    required this.id,
    required this.title,
    this.description,
    required this.durationInMonths,
    required this.rate,
    this.features = const [],
  });

  factory PlanDetails.fromJson(Map<String, dynamic> json) {
    return PlanDetails(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Plan',
      description: json['description']?.toString(),
      durationInMonths: _parseInt(json['durationInMonths']) ?? 1,
      rate: _parseInt(json['rate']) ?? 0,
      features:
          (json['features'] as List<dynamic>?)
              ?.map((f) => f.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'durationInMonths': durationInMonths,
      'rate': rate,
      'features': features,
    };
  }

  /// Helper method to safely parse integers
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Get formatted price
  String get formattedPrice {
    return '₹$rate';
  }

  /// Get duration text
  String get formattedDuration {
    if (durationInMonths == 1) return '1 month';
    if (durationInMonths == 12) return '1 year';
    return '$durationInMonths months';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlanDetails &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.durationInMonths == durationInMonths &&
        other.rate == rate &&
        other.features.toString() == features.toString();
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
    );
  }
}

/// Transaction details from payment verification
class TransactionDetails {
  /// Razorpay payment ID
  final String paymentId;

  /// Razorpay order ID
  final String orderId;

  /// Payment amount
  final int amount;

  /// Payment currency
  final String currency;

  /// Payment status
  final String status;

  /// Payment method used
  final String? method;

  /// Transaction timestamp
  final DateTime? timestamp;

  const TransactionDetails({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    this.method,
    this.timestamp,
  });

  factory TransactionDetails.fromJson(Map<String, dynamic> json) {
    return TransactionDetails(
      paymentId: json['paymentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: _parseInt(json['amount']) ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? 'unknown',
      method: json['method']?.toString(),
      timestamp: _parseDateTime(json['timestamp'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'status': status,
      if (method != null) 'method': method,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  /// Helper methods
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) return DateTime.tryParse(dateTime);
    if (dateTime is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    }
    return null;
  }

  /// Get formatted amount
  String get formattedAmount {
    return '₹${(amount / 100).toStringAsFixed(2)}';
  }

  /// Check if transaction was successful
  bool get isSuccessful {
    return status.toLowerCase() == 'captured' ||
        status.toLowerCase() == 'success' ||
        status.toLowerCase() == 'authorized';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionDetails &&
        other.paymentId == paymentId &&
        other.orderId == orderId &&
        other.amount == amount &&
        other.currency == currency &&
        other.status == status &&
        other.method == method &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      paymentId,
      orderId,
      amount,
      currency,
      status,
      method,
      timestamp,
    );
  }
}
