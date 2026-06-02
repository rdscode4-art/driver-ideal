import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_theme.dart';
import '../controllers/home_controller.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'earnings_screen.dart';
import 'future_ride_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FutureRideScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Refresh home controller data after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeController = Get.isRegistered<HomeController>()
          ? Get.find<HomeController>()
          : null;
      homeController?.refreshDataAfterLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryLight,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.background,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Future Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
