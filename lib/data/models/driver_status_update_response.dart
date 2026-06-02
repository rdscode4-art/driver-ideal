class DriverStatusUpdateResponse {
  final bool success;
  final String message;
  final DriverInfo? driver;

  DriverStatusUpdateResponse({
    required this.success,
    required this.message,
    this.driver,
  });

  factory DriverStatusUpdateResponse.fromJson(Map<String, dynamic> json) {
    return DriverStatusUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      driver: json['driver'] != null ? DriverInfo.fromJson(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'driver': driver?.toJson(),
    };
  }
}

class DriverInfo {
  final String id;
  final String name;
  final bool isAvailable;

  DriverInfo({
    required this.id,
    required this.name,
    required this.isAvailable,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isAvailable': isAvailable,
    };
  }

  @override
  String toString() {
    return 'DriverInfo(id: $id, name: $name, isAvailable: $isAvailable)';
  }
}
