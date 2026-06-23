import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal_driver/core/token_manager.dart';
import 'package:rideal_driver/core/storage_helper.dart';
import 'package:rideal_driver/core/app_theme.dart';
import 'package:rideal_driver/nonvehichle/homescreennonvehichle.dart';
import 'package:rideal_driver/nonvehichle/earningnonvehichle.dart';
import 'package:rideal_driver/nonvehichle/profilenonvehichle.dart';

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TokenManager _tokenManager = TokenManager.instance;
  final _storage = GetStorage();
  
  String? authToken;
  String? driverId;
  int _currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get token from TokenManager
      final token = await _tokenManager.getCurrentToken();
      
      // Get driver ID from storage
      String? id = await StorageHelper.getDriverId();
      
      // If not found in StorageHelper, try GetStorage
      if (id == null || id.isEmpty) {
        final userData = _storage.read('user_data');
        if (userData != null) {
          id = userData['id']?.toString() ?? 
               userData['_id']?.toString() ?? 
               userData['driverId']?.toString();
        }
        
        // Also check driver_data
        if (id == null || id.isEmpty) {
          final driverData = _storage.read('driver_data');
          if (driverData != null) {
            id = driverData['id']?.toString() ?? 
                 driverData['_id']?.toString() ?? 
                 driverData['driverId']?.toString();
          }
        }
      }
      
      print('🔑 Loaded Token: ${token != null ? "✅" : "❌"}');
      print('🆔 Loaded Driver ID: ${id ?? "Not found"}');
      
      setState(() {
        authToken = token;
        driverId = id;
        isLoading = false;
      });
      
      // Validate data
      if (token == null || id == null) {
        print('⚠️ Missing auth data - Token: ${token != null}, ID: ${id != null}');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Widget> get _screens => [
    const HomeScreennonvehichle(),
    EarningsScreennonvehichle(
      authToken: authToken ?? '',
      driverId: driverId ?? '',
    ),
     const ProfileScreennonvehichle(
      
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    }

    // Show error if missing critical data
    if (authToken == null || driverId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Missing ${authToken == null ? "token" : "driver ID"}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await _tokenManager.clearToken();
                  // Navigate to login - adjust route as needed
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                ),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.r,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: Colors.grey[400],
            backgroundColor: Colors.transparent,
            showUnselectedLabels: true,
            elevation: 0,
            iconSize: 24.w,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Earnings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data Models
class RideRequest {
  final String id;
  final String passengerName;
  final String passengerPhone;
  final String pickup;
  final String dropoff;
  final String distance;
  final int fare;
  final String estimatedTime;
  final double rating;

  RideRequest({
    required this.id,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.estimatedTime,
    required this.rating,
  });
}

class OngoingRide {
  final String id;
  final String passengerName;
  final String passengerPhone;
  final String pickup;
  final String dropoff;
  final String distance;
  final int fare;
  final String status;
  final String otp;
  final String estimatedTime;
  final double rating;

  OngoingRide({
    required this.id,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.status,
    required this.otp,
    required this.estimatedTime,
    required this.rating,
  });
}

class TripHistory {
  final String id;
  final String date;
  final String time;
  final String passengerName;
  final String pickup;
  final String dropoff;
  final int fare;
  final String distance;
  final int rating;

  TripHistory({
    required this.id,
    required this.date,
    required this.time,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.distance,
    required this.rating,
  });
}