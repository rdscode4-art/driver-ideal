class RideHistoryResponse {
  final int totalRides;
  final Map<String, int> rideCounts;
  final List<RideHistoryItem> rides;

  RideHistoryResponse({
    required this.totalRides,
    required this.rideCounts,
    required this.rides,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    return RideHistoryResponse(
      totalRides: json['totalRides'] ?? 0,
      rideCounts: Map<String, int>.from(json['rideCounts'] ?? {}),
      rides: (json['rides'] as List<dynamic>? ?? [])
          .map((ride) => RideHistoryItem.fromJson(ride))
          .toList(),
    );
  }
}

class RideHistoryItem {
  final String id;
  final RiderInfo rider;
  final DriverInfo driver;
  final String status;
  final LocationInfo pickup;
  final LocationInfo drop;
  final List<dynamic> stops;
  final String feedback;
  final DateTime createdAt;
  final String? rebookedFrom;
  final double? fare;
  final int? rating;
  final String? otp;
  final String? paymentMethod;

  RideHistoryItem({
    required this.id,
    required this.rider,
    required this.driver,
    required this.status,
    required this.pickup,
    required this.drop,
    required this.stops,
    required this.feedback,
    required this.createdAt,
    this.rebookedFrom,
    this.fare,
    this.rating,
    this.otp,
    this.paymentMethod,
  });

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    return RideHistoryItem(
      id: json['_id'] ?? '',
      rider: RiderInfo.fromJson(json['rider'] ?? {}),
      driver: DriverInfo.fromJson(json['driver'] ?? {}),
      status: json['status'] ?? '',
      pickup: LocationInfo.fromJson(json['pickup'] ?? {}),
      drop: LocationInfo.fromJson(json['drop'] ?? {}),
      stops: json['stops'] ?? [],
      feedback: json['feedback'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      rebookedFrom: json['rebookedFrom'],
      fare: (json['fare'] ?? json['estimatedFare'])?.toDouble(),
      rating: json['rating']?.toInt(),
      otp: json['otp']?.toString(),
      paymentMethod: json['paymentMethod'],
    );
  }

  // Helper methods for UI display
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedFare {
    if (fare == null) return 'N/A';
    return '₹${fare!.toStringAsFixed(0)}';
  }

  String get pickupAddress => pickup.address;
  String get dropAddress => drop.address;

  String operator [](String other) {
    switch (other) {
      case 'id':
        return id;
      case 'status':
        return status;
      case 'feedback':
        return feedback;
      case 'rebookedFrom':
        return rebookedFrom ?? '';
      case 'otp':
        return otp ?? '';
      case 'paymentMethod':
        return paymentMethod ?? '';
      default:
        return '';
    }
  }
}

class RiderInfo {
  final String id;
  final String name;
  final String phone;

  RiderInfo({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) {
    return RiderInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String phone;

  DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class LocationInfo {
  final String address;
  final double lat;
  final double lng;

  LocationInfo({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}
