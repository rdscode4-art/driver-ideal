class Location {
  final String address;
  final double lat;
  final double lng;

  Location({
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}

class Vehicle {
  final String name;
  final String color;
  final String numberPlate;

  Vehicle({
    required this.name,
    required this.color,
    required this.numberPlate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'numberPlate': numberPlate,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      numberPlate: json['numberPlate'] ?? '',
    );
  }
}

// New models for ride requests
class Rider {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final String address;
  final double rating;

  Rider({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.address,
    required this.rating,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}

class PassengerBooking {
  final String bookingId;
  final Rider rider;
  final int numOfSeats;
  final String status;

  PassengerBooking({
    required this.bookingId,
    required this.rider,
    required this.numOfSeats,
    required this.status,
  });

  factory PassengerBooking.fromJson(Map<String, dynamic> json) {
    return PassengerBooking(
      bookingId: json['bookingId'] ?? '',
      rider: Rider.fromJson(json['rider'] ?? {}),
      numOfSeats: json['numOfSeats'] ?? 0,
      status: json['status'] ?? 'pending',
    );
  }
}

class FutureRideWithRequests {
  final String id;
  final Location fromLocation;
  final Location toLocation;
  final DateTime date;
  final String time;
  final Vehicle vehicle;
  final List<PassengerBooking> passengersBooked;

  FutureRideWithRequests({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.date,
    required this.time,
    required this.vehicle,
    required this.passengersBooked,
  });

  // Add rideId getter for backward compatibility
  String get rideId => id;

  factory FutureRideWithRequests.fromJson(Map<String, dynamic> json) {
    return FutureRideWithRequests(
      id: json['_id'] ?? '',
      fromLocation: Location.fromJson(json['fromLocation'] ?? {}),
      toLocation: Location.fromJson(json['toLocation'] ?? {}),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      time: json['time'] ?? '',
      vehicle: Vehicle.fromJson(json['vehicle'] ?? {}),
      passengersBooked: (json['passengersBooked'] as List<dynamic>? ?? [])
          .map((booking) => PassengerBooking.fromJson(booking))
          .toList(),
    );
  }

  // Helper getters
  String get routeText => '${fromLocation.address} to ${toLocation.address}';
  String get dateTimeText => '${date.day}/${date.month}/${date.year} - $time';
  int get pendingRequestsCount => passengersBooked.where((b) => b.status == 'pending').length;
  int get totalSeatsRequested => passengersBooked.fold(0, (sum, booking) => sum + booking.numOfSeats);
}

class FutureRideRequest {
  final Location fromLocation;
  final Location toLocation;
  final String date; // Format: "2025-09-05"
  final String time; // Format: "09:30"
  final double pricePerPassenger;
  final Vehicle vehicle;
  final String driverPhone;
  final int maxPassengers;

  FutureRideRequest({
    required this.fromLocation,
    required this.toLocation,
    required this.date,
    required this.time,
    required this.pricePerPassenger,
    required this.vehicle,
    required this.driverPhone,
    required this.maxPassengers,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromLocation': fromLocation.toJson(),
      'toLocation': toLocation.toJson(),
      'date': date,
      'time': time,
      'pricePerPassenger': pricePerPassenger,
      'vehicle': vehicle.toJson(),
      'driverPhone': driverPhone,
      'maxPassengers': maxPassengers,
      'passengersBooked': [], // Add empty array for backend compatibility
    };
  }
}

class FutureRide {
  final String id;
  final String driverId;
  final Location fromLocation;
  final Location toLocation;
  final DateTime date;
  final String time;
  final double pricePerPassenger;
  final Vehicle vehicle;
  final String driverPhone;
  final int maxPassengers;
  final String status;
  final List<dynamic> passengersBooked;
  final DateTime createdAt;
  final DateTime updatedAt;

  FutureRide({
    required this.id,
    required this.driverId,
    required this.fromLocation,
    required this.toLocation,
    required this.date,
    required this.time,
    required this.pricePerPassenger,
    required this.vehicle,
    required this.driverPhone,
    required this.maxPassengers,
    required this.status,
    required this.passengersBooked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FutureRide.fromJson(Map<String, dynamic> json) {
    return FutureRide(
      id: json['_id'] ?? '',
      driverId: json['driverId'] ?? '',
      fromLocation: Location.fromJson(json['fromLocation'] ?? {}),
      toLocation: Location.fromJson(json['toLocation'] ?? {}),
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      pricePerPassenger: (json['pricePerPassenger'] ?? 0.0).toDouble(),
      vehicle: Vehicle.fromJson(json['vehicle'] ?? {}),
      driverPhone: json['driverPhone'] ?? '',
      maxPassengers: json['maxPassengers'] ?? 0,
      status: json['status'] ?? '',
      passengersBooked: json['passengersBooked'] ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class FutureRideResponse {
  final String message;
  final FutureRide ride;
  final bool success;

  FutureRideResponse({
    required this.message,
    required this.ride,
    required this.success,
  });

  factory FutureRideResponse.fromJson(Map<String, dynamic> json) {
    return FutureRideResponse(
      message: json['msg'] ?? '',
      ride: FutureRide.fromJson(json['ride'] ?? {}),
      success: true, // API doesn't return success flag, assume true if no error
    );
  }
}
