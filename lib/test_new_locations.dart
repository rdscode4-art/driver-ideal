import 'package:rideal_driver/ride.dart';
import 'package:rideal_driver/services/rides_api_service.dart';

void main() {
  print('Testing new locations...');
  
  // Test Ride class
  var ride = Ride(
    id: 'test123',
    riderId: 'rider123', 
    pickupLocation: 'Location A',
    dropoffLocation: 'Location B',
    rideType: 'normal',
    estimatedFare: 100.0,
    status: 'pending',
    feedback: '',
    otp: '123456',
    createdAt: DateTime.now(),
  );
  print('Ride created: ${ride.id}');
  
  // Test RidesApiService class
  var service = RidesApiService();
  print('RidesApiService created: $service');
}
