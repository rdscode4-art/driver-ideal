class OtpVerificationResponse {
  final bool success;
  final String message;
  final String? token;
  final Driver? driver;

  OtpVerificationResponse({
    required this.success,
    required this.message,
    this.token,
    this.driver,
  });

  factory OtpVerificationResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'driver': driver?.toJson(),
    };
  }
}

class Driver {
  final String id;
  final String phone;
  final String name;

  Driver({
    required this.id,
    required this.phone,
    required this.name,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
    };
  }
}
