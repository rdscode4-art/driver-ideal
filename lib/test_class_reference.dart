import 'package:rideal_driver/ride.dart';
import 'package:rideal_driver/services/rides_api_service.dart';

void main() {
  // Try to reference the classes
  print('Ride class: $Ride');
  print('RidesApiService class: $RidesApiService');
  
  // Try to create instances (this will fail if constructor is wrong but should work for class resolution)
  try {
    var service = RidesApiService();
    print('RidesApiService created: $service');
  } catch (e) {
    print('Error creating RidesApiService: $e');
  }
}
