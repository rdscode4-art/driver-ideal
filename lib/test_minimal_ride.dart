import 'package:rideal_driver/ride.dart';

void main() {
  print('Testing minimal Ride...');
  var ride = Ride(
    id: 'test123',
    riderId: 'rider123',
    pickupLocation: 'Test Pickup Location',
    dropoffLocation: 'Test Dropoff Location',
    rideType: 'sedan',
    estimatedFare: 25.50,
    status: 'pending',
    feedback: '',
    otp: '123456',
    createdAt: DateTime.now(),
    // Adding coordinate information for origin (green mark) and destination (red mark)
    pickupLatitude: 28.6139,    // Origin coordinates (green mark)
    pickupLongitude: 77.2090,
    dropoffLatitude: 28.5355,   // Destination coordinates (red mark)
    dropoffLongitude: 77.3910,
  );

  print('Ride created: ${ride.id}');
  print('Ride fare: ${ride.formattedFare}');
  print('Ride type: ${ride.rideTypeDisplayName}');

  // Test coordinate functionality
  print('\n=== Location Details ===');
  print('Origin (Green Mark):');
  print('  Address: ${ride.pickupLocation}');
  print('  Coordinates: ${ride.pickupLatitude}, ${ride.pickupLongitude}');

  print('Destination (Red Mark):');
  print('  Address: ${ride.dropoffLocation}');
  print('  Coordinates: ${ride.dropoffLatitude}, ${ride.dropoffLongitude}');

  // Test coordinate validation
  print('\n=== Coordinate Validation ===');
  bool hasValidPickupCoords = ride.pickupLatitude != null && ride.pickupLongitude != null;
  bool hasValidDropoffCoords = ride.dropoffLatitude != null && ride.dropoffLongitude != null;

  print('Valid pickup coordinates: $hasValidPickupCoords');
  print('Valid dropoff coordinates: $hasValidDropoffCoords');

  if (hasValidPickupCoords && hasValidDropoffCoords) {
    print('✅ Ride has complete coordinate information for mapping');
  } else {
    print('❌ Ride missing coordinate information');
  }
}
