import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationResponse {
  final String origin;
  final String destination;
  final String distance;
  final String duration;
  final double? originLatitude;
  final double? originLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final List<LatLng>? points; // Decoded polyline points

  NavigationResponse({
    required this.origin,
    required this.destination,
    required this.distance,
    required this.duration,
    this.originLatitude,
    this.originLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.points,
  });

  factory NavigationResponse.fromJson(Map<String, dynamic> json) {
    return NavigationResponse(
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      distance: json['distance'] ?? '',
      duration: json['duration'] ?? '',
      originLatitude: _extractLatFromString(json['origin']?.toString()),
      originLongitude: _extractLngFromString(json['origin']?.toString()),
      destinationLatitude: _extractLatFromString(json['destination']?.toString()),
      destinationLongitude: _extractLngFromString(json['destination']?.toString()),
      points: null, // Initially null, will be populated by service
    );
  }

  static double? _extractLatFromString(String? coordString) {
    if (coordString == null || coordString.isEmpty) return null;
    try {
      final parts = coordString.split(',');
      if (parts.length >= 2) return double.parse(parts[0].trim());
    } catch (e) {}
    return null;
  }

  static double? _extractLngFromString(String? coordString) {
    if (coordString == null || coordString.isEmpty) return null;
    try {
      final parts = coordString.split(',');
      if (parts.length >= 2) return double.parse(parts[1].trim());
    } catch (e) {}
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'distance': distance,
      'duration': duration,
      'originLatitude': originLatitude,
      'originLongitude': originLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
    };
  }

  String get formattedDistance => distance.isNotEmpty ? distance : 'Unknown distance';
  String get formattedDuration => duration.isNotEmpty ? duration : 'Unknown duration';
  bool get isValid => origin.isNotEmpty && destination.isNotEmpty && distance.isNotEmpty && duration.isNotEmpty;
}
