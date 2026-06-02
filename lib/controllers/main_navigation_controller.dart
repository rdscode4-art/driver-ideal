import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/home_screen.dart';
import '../presentation/earnings_screen.dart';
import '../presentation/profile_screen.dart';

class MainNavigationController extends GetxController {
  var currentIndex = 0.obs;

  final List<Widget> screens = [
    const HomeScreen(),           // Tab 0: Home
     // const(),      // Tab 1: Maps
    const EarningsScreen(),       // Tab 2: Earnings
    const ProfileScreen(),        // Tab 3: Profile
  ];

  final List<BottomNavigationBarItem> navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.car_rental_outlined),
      activeIcon: Icon(Icons.car_rental_sharp),
      label: 'Rides',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_outlined),
      activeIcon: Icon(Icons.account_balance_wallet),
      label: 'Earnings',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void changeTab(int index) {
    currentIndex.value = index;
  }

  // Helper methods to navigate to specific tabs programmatically
  void goToHome() => changeTab(0);
  void goToRides() => changeTab(1);
  void goToEarnings() => changeTab(2);
  void goToProfile() => changeTab(3);
}
