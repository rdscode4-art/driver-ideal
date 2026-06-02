/// Response model for Razorpay order creation API
///
/// This model represents the response from:
/// POST /api/non-vehicle-driver/buy-subscription
class NonVehicleOrderResponse {
  /// Razorpay order ID for payment processing
  final String orderId;

  /// Amount in smallest currency unit (paise for INR)
  final int amount;

  /// Currency code (e.g., 'INR')
  final String currency;

  /// Additional order details from backend
  final String? receipt;

  /// Order creation timestamp
  final DateTime? createdAt;

  /// Order status from Razorpay
  final String? status;

  const NonVehicleOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.receipt,
    this.createdAt,
    this.status,
  });

  /// Create from JSON response
  factory NonVehicleOrderResponse.fromJson(Map<String, dynamic> json) {
    return NonVehicleOrderResponse(
      orderId: json['orderId']?.toString() ?? json['id']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      currency: json['currency']?.toString() ?? 'INR',
      receipt: json['receipt']?.toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      status: json['status']?.toString(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      if (receipt != null) 'receipt': receipt,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (status != null) 'status': status,
    };
  }

  /// Helper method to safely parse amount from various formats
  static int _parseAmount(dynamic amount) {
    if (amount == null) return 0;

    if (amount is int) return amount;
    if (amount is double) return amount.round();
    if (amount is String) {
      final parsed = int.tryParse(amount) ?? double.tryParse(amount)?.round();
      return parsed ?? 0;
    }

    return 0;
  }

  /// Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;

    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      return DateTime.tryParse(dateTime);
    }
    if (dateTime is int) {
      // Assume timestamp in milliseconds
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    }

    return null;
  }

  /// Get formatted amount for display (in rupees)
  String get formattedAmount {
    return '₹${(amount / 100).toStringAsFixed(2)}';
  }

  /// Get amount in rupees as double
  double get amountInRupees {
    return amount / 100.0;
  }

  /// Check if order is valid for payment processing
  bool get isValid {
    return orderId.isNotEmpty && amount > 0 && currency.isNotEmpty;
  }

  /// Check if order is created successfully
  bool get isCreated {
    return status == null || status == 'created';
  }

  @override
  String toString() {
    return 'NonVehicleOrderResponse(orderId: $orderId, amount: $amount, '
        'currency: $currency, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NonVehicleOrderResponse &&
        other.orderId == orderId &&
        other.amount == amount &&
        other.currency == currency &&
        other.receipt == receipt &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(orderId, amount, currency, receipt, createdAt, status);
  }

  /// Create a copy with updated values
  NonVehicleOrderResponse copyWith({
    String? orderId,
    int? amount,
    String? currency,
    String? receipt,
    DateTime? createdAt,
    String? status,
  }) {
    return NonVehicleOrderResponse(
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      receipt: receipt ?? this.receipt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
