class DriverStatus {
  final bool isAvailable;
  final String? currentStatus;
  final DateTime? lastUpdated;

  DriverStatus({
    required this.isAvailable,
    this.currentStatus,
    this.lastUpdated,
  });

  factory DriverStatus.fromJson(Map<String, dynamic> json) {
    return DriverStatus(
      isAvailable: json['isAvailable'] ?? false,
      currentStatus: json['currentStatus'],
      lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'currentStatus': currentStatus,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  String get displayStatus {
    return isAvailable ? 'Online' : 'Offline';
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isAvailable;
  final double? rating;
  final int? totalTrips;
  final String? profileImage;

  DriverInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isAvailable,
    this.rating,
    this.totalTrips,
    this.profileImage,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      totalTrips: json['totalTrips'] as int?,
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isAvailable': isAvailable,
      'rating': rating,
      'totalTrips': totalTrips,
      'profileImage': profileImage,
    };
  }
}

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
      driver: json['driver'] != null
        ? DriverInfo.fromJson(json['driver'])
        : null,
    );
  }
}
