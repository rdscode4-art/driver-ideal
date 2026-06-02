class LocationDetectionModel {
  final String lat;
  final String lng;
  final String address;

  LocationDetectionModel({
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory LocationDetectionModel.fromJson(Map<String, dynamic> json) {
    return LocationDetectionModel(
      lat: json['lat'] ?? '',
      lng: json['lng'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }

  // Convert string coordinates to double
  double get latitude => double.tryParse(lat) ?? 0.0;
  double get longitude => double.tryParse(lng) ?? 0.0;

  // Check if location is valid
  bool get isValid => latitude != 0.0 && longitude != 0.0 && address.isNotEmpty;

  @override
  String toString() {
    return 'LocationDetectionModel(lat: $lat, lng: $lng, address: $address)';
  }
}
