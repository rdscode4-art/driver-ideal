class LoginResponse {
  final bool success;
  final String message;

  LoginResponse({
    required this.success,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'LoginResponse(success: $success, message: $message)';
  }
}
