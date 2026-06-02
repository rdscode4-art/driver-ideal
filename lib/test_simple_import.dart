// Simple test to see if imports work
import 'package:rideal_driver/ride.dart' as ride_model;
import 'package:rideal_driver/services/rides_api_service.dart' as api_service;

void main() {
  print('Imports test completed');

  // Test that we can reference the classes
  print('Ride class available: ${ride_model.Ride}');
  print('API service available: ${api_service.RidesApiService}');
}
