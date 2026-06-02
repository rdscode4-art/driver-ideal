class PaymentResponse {
  final bool success;
  final String message;
  final String? orderId;
  final int? amount;
  final String? currency;

  PaymentResponse({
    required this.success,
    required this.message,
    this.orderId,
    this.amount,
    this.currency,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      orderId: json['orderId'],
      amount: json['amount'],
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
    };
  }

  /// Format amount for display (converting from paise to rupees)
  String get formattedAmount {
    if (amount == null) return '₹0.00';
    final rupees = amount! / 100; // Convert paise to rupees
    return '₹${rupees.toStringAsFixed(2)}';
  }

  /// Check if this is a successful payment response with order details
  bool get hasOrderDetails => success && orderId != null && amount != null;
}
