class DriverRegistrationResponse {
  final bool success;
  final String message;
  final String? referralCode;

  DriverRegistrationResponse({
    required this.success,
    required this.message,
    this.referralCode,
  });

  factory DriverRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return DriverRegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      referralCode: json['referralCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'referralCode': referralCode,
    };
  }
}
