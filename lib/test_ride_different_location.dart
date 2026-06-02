import 'package:rideal_driver/ride_test.dart';

void main() {
  print('Testing Ride from different location...');
  var ride = Ride(id: 'test123', riderId: 'rider123');
  print('Ride created: ${ride.id}');
}
