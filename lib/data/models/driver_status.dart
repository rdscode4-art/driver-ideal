class DriverStatus {
  final bool isAvailable;
  final double lat;
  final double lng;

  DriverStatus({
    required this.isAvailable,
    required this.lat,
    required this.lng,
  });

  factory DriverStatus.fromJson(Map<String, dynamic> json) {
    // Handle both boolean 'isAvailable' and string 'status' from different endpoints
    bool available = false;
    if (json['isAvailable'] is bool) {
      available = json['isAvailable'];
    } else if (json['status'] is String) {
      available = json['status'].toLowerCase() == 'available' || 
                  json['status'].toLowerCase() == 'online';
    } else if (json['isAvailable'] is String) {
      available = json['isAvailable'].toLowerCase() == 'true';
    }

    return DriverStatus(
      isAvailable: available,
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'lat': lat,
      'lng': lng,
    };
  }

  String get displayStatus => isAvailable ? 'Online' : 'Offline';

  bool get isOnline => isAvailable;

  @override
  String toString() {
    return 'DriverStatus(isAvailable: $isAvailable, lat: $lat, lng: $lng)';
  }
}
