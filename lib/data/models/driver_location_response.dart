class DriverLocationResponse {
  final bool success;
  final String message;
  final LocationData? location;

  DriverLocationResponse({
    required this.success,
    required this.message,
    this.location,
  });

  factory DriverLocationResponse.fromJson(Map<String, dynamic> json) {
    return DriverLocationResponse(
      success: json['success'] ?? false,
      message: json['msg'] ?? json['message'] ?? '',
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'location': location?.toJson(),
    };
  }
}

class LocationData {
  final double lat;
  final double lng;

  LocationData({
    required this.lat,
    required this.lng,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}
