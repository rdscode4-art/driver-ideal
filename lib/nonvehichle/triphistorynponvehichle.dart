import 'package:flutter/material.dart';
import 'package:rideal_driver/core/app_theme.dart';
import 'package:rideal_driver/nonvehichle/non_vehichle_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideal_driver/services/location_service.dart';

// Trip History Model (same as before)
class TripHistoryItem {
  final String id;
  final String date;
  final String time;
  final String passengerName;
  final String pickup;
  final String dropoff;
  final double fare;
  final String distance;
  final int rating;
  final String status;
  final String? passengerPhone;
  final String? otp;
  final int? hours;

  TripHistoryItem({
    required this.id,
    required this.date,
    required this.time,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.distance,
    this.rating = 0,
    required this.status,
    this.passengerPhone,
    this.otp,
    this.hours,
  });

  TripHistoryItem copyWith({
    String? id,
    String? date,
    String? time,
    String? passengerName,
    String? pickup,
    String? dropoff,
    double? fare,
    String? distance,
    int? rating,
    String? status,
    String? passengerPhone,
    String? otp,
    int? hours,
  }) {
    return TripHistoryItem(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      passengerName: passengerName ?? this.passengerName,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      otp: otp ?? this.otp,
      hours: hours ?? this.hours,
    );
  }

 factory TripHistoryItem.fromJson(Map<String, dynamic> json) {
  print("🔍 Parsing trip history item: $json");
  
  String passengerName = 'Unknown Passenger';
  String? passengerPhone;
  
  if (json['rider'] != null && json['rider'] is Map) {
    final rider = json['rider'] as Map<String, dynamic>;
    passengerName = rider['name']?.toString() ?? 'Unknown Passenger';
    passengerPhone = rider['phone']?.toString();
  } 

  String rawPickup = json['pickupLocation']?.toString() ?? json['pickup']?.toString() ?? '';
  String pickup = (rawPickup.isEmpty || rawPickup == 'null') ? 'Service Location' : rawPickup;
  String dropoff = (json['dropoffLocation']?.toString() ?? json['dropoff']?.toString() ?? 'Service Location');
  if (dropoff == 'null') dropoff = 'Service Location';
  
  // ✅ FIXED: Parse hours from duration string
  int hours = 0;
  
  // Try to get hours from 'hours' field first (for backward compatibility)
  if (json['hours'] != null) {
    hours = _toDouble(json['hours']).round();
  } 
  // If not found, parse from 'duration' string (e.g., "2 hours")
  else if (json['duration'] != null) {
    String durationStr = json['duration'].toString().toLowerCase();
    
    // Extract number from strings like "2 hours", "3 hour", "1.5 hours"
    RegExp regExp = RegExp(r'(\d+\.?\d*)');
    Match? match = regExp.firstMatch(durationStr);
    
    if (match != null) {
      hours = double.parse(match.group(1)!).round();
      print("✅ Parsed $hours hours from duration: '$durationStr'");
    } else {
      print("⚠️ Could not parse hours from duration: '$durationStr'");
    }
  }
  
  if (hours > 0) {
    // Keep pickup as is, only update dropoff if it was a generic one
    if (dropoff == 'Service Location') {
      dropoff = '$hours hour${hours > 1 ? 's' : ''} booking';
    }
  }

  // Parse fare from price or fare field
  double fare = 0.0;
  if (json['price'] != null) {
    fare = _toDouble(json['price']);
  } else if (json['fare'] != null) {
    fare = _toDouble(json['fare']);
  } else if (json['totalFare'] != null) {
    fare = _toDouble(json['totalFare']);
  }

  String distance = hours > 0 ? '${hours}h' : 'N/A';

  String dateStr = '';
  String timeStr = '';
  
  DateTime? dateTime;
  
  // Try to parse different date fields
  if (json['completedAt'] != null && json['completedAt'].toString() != 'null') {
    try {
      dateTime = DateTime.parse(json['completedAt'].toString()).toLocal();
    } catch (e) {
      print("❌ completedAt parsing error: $e");
    }
  }
  
  if (dateTime == null && json['startedAt'] != null && json['startedAt'].toString() != 'null') {
    try {
      dateTime = DateTime.parse(json['startedAt'].toString()).toLocal();
    } catch (e) {
      print("❌ startedAt parsing error: $e");
    }
  }
  
  if (dateTime == null && json['createdAt'] != null) {
    try {
      dateTime = DateTime.parse(json['createdAt'].toString()).toLocal();
    } catch (e) {
      print("❌ createdAt parsing error: $e");
    }
  }
  
  if (dateTime != null) {
    dateStr = _formatDate(dateTime);
    timeStr = _formatTime(dateTime);
  }

  // Parse rating
  int rating = 0;
  if (json['rating'] != null) {
    rating = _toDouble(json['rating']).round();
  } else if (json['driverRating'] != null) {
    rating = _toDouble(json['driverRating']).round();
  }

  String status = json['status']?.toString() ?? 'completed';
  String? otp = json['otp']?.toString();
  final id = json['rideId']?.toString() ?? json['id']?.toString() ?? json['_id']?.toString() ?? '';

  print("✅ Parsed trip: ID=$id, Hours=$hours, Fare=$fare, Status=$status");

  return TripHistoryItem(
    id: id,
    date: dateStr.isNotEmpty ? dateStr : 'Unknown Date',
    time: timeStr.isNotEmpty ? timeStr : 'Unknown Time',
    passengerName: passengerName,
    pickup: pickup,
    dropoff: dropoff,
    fare: fare,
    distance: distance,
    rating: rating,
    status: status,
    passengerPhone: passengerPhone,
    otp: otp,
    hours: hours,
  );
}
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  static String _formatTime(DateTime dateTime) {
    String period = dateTime.hour >= 12 ? "PM" : "AM";
    int hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }
}

// Trip History Screen
class TripHistoryScreennonvehichle extends StatefulWidget {
  const TripHistoryScreennonvehichle({super.key});

  @override
  State<TripHistoryScreennonvehichle> createState() => _TripHistoryScreennonvehichleState();
}

class _TripHistoryScreennonvehichleState extends State<TripHistoryScreennonvehichle> {
  Future<List<TripHistoryItem>>? _tripHistoryFuture;
  String? _authToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }

  Future<void> _loadTripHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      
      if (_authToken == null || _authToken!.isEmpty) {
        print("❌ No auth token found");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Authentication required. Please login again.'),
                  ),
                ],
              ),
              backgroundColor: Colors.deepOrange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      setState(() {
        _tripHistoryFuture = _fetchTripHistory();
      });
    } catch (e) {
      print("❌ Error loading trip history: $e");
    }
  }

  Future<String> _resolveAddressIfNeeded(dynamic locationData) async {
    if (locationData == null) return 'Location not provided';
    
    if (locationData is Map) {
      try {
        final lat = locationData['lat'] != null ? double.tryParse(locationData['lat'].toString()) : null;
        final lng = locationData['lng'] != null ? double.tryParse(locationData['lng'].toString()) : null;
        
        if (lat != null && lng != null) {
          final address = await LocationService.getAddressFromCoordinates(lat, lng);
          return address ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
      } catch (e) {
        print('⚠️ Error resolving coordinate Map: $e');
      }
    }

    String location = locationData.toString();
    if (location.isEmpty || location == 'null' || location == 'Service Location') return location;
    
    if (location.contains(',') && !location.contains(RegExp(r'[a-zA-Z]'))) {
      try {
        final coords = location.split(',');
        if (coords.length >= 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());
          if (lat != null && lng != null) {
            final address = await LocationService.getAddressFromCoordinates(lat, lng);
            if (address != null) return address;
          }
        }
      } catch (e) {
        print('⚠️ Error resolving coordinate string: $e');
      }
    }
    return location;
  }

  Future<List<TripHistoryItem>> _fetchTripHistory() async {
    try {
      print("🔄 Fetching trip history...");
      
      final response = await NonVehicleAuthService.getTripHistory(_authToken!);
      
      print("📬 Trip history response: $response");
      
      if (response['success'] == true) {
        final data = response['data'];
        
        List<dynamic> tripsJson = [];
        
        if (data is List) {
          tripsJson = data;
        } else if (data is Map) {
          if (data['rides'] != null && data['rides'] is List) {
            tripsJson = data['rides'] as List;
          } else if (data['trips'] != null && data['trips'] is List) {
            tripsJson = data['trips'] as List;
          } else if (data['history'] != null && data['history'] is List) {
            tripsJson = data['history'] as List;
          } else if (data['data'] != null && data['data'] is List) {
            tripsJson = data['data'] as List;
          }
        }
        
        print("✅ Found ${tripsJson.length} trips");
        
        if (tripsJson.isEmpty) {
          return [];
        }
        
        List<TripHistoryItem> rawTrips = tripsJson
            .map((json) {
              try {
                return TripHistoryItem.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print("❌ Error parsing trip: $e");
                return null;
              }
            })
            .whereType<TripHistoryItem>()
            .toList();

        // Resolve addresses for all trips
        final List<TripHistoryItem> resolvedTrips = await Future.wait(rawTrips.map((trip) async {
          // Find original JSON to get coordinates
          final originalJson = tripsJson.firstWhere(
            (j) => (j['rideId']?.toString() ?? j['id']?.toString() ?? j['_id']?.toString()) == trip.id,
            orElse: () => null,
          );

          if (originalJson != null) {
            final pickup = await _resolveAddressIfNeeded(originalJson['pickupLocation'] ?? originalJson['pickup']);
            final dropoff = await _resolveAddressIfNeeded(originalJson['dropoffLocation'] ?? originalJson['dropoff']);
            
            return trip.copyWith(
              pickup: pickup,
              dropoff: dropoff,
            );
          }
          return trip;
        }));
        
        resolvedTrips.sort((a, b) => b.id.compareTo(a.id));
        
        return resolvedTrips;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch trip history');
      }
    } catch (e) {
      print("❌ Error fetching trip history: $e");
      rethrow;
    }
  }

  // START RIDE FROM TRIP HISTORY
  Future<void> _startRideFromHistory(TripHistoryItem trip) async {
    if (_authToken == null) {
      _showErrorSnackbar('Please login to continue');
      return;
    }

    final TextEditingController otpController = TextEditingController();
    
    final shouldStart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Verify Passenger OTP')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ask the passenger for their 6-digit OTP to start the ride',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                  color: AppTheme.primary,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: Colors.grey[300],
                    letterSpacing: 10,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.primary.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'The passenger has received this OTP on their phone',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (otpController.text.length == 6) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid 6-digit OTP'),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldStart == true && otpController.text.isNotEmpty) {
      setState(() => _isLoading = true);

      final result = await NonVehicleAuthService.startRide(
        _authToken!,
        trip.id,
        otpController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSuccessSnackbar('🎉 Ride started successfully!');
        _loadTripHistory();
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showErrorSnackbar(result['message'] ?? 'Failed to start ride');
      }
    }
  }

  // COMPLETE RIDE FROM TRIP HISTORY
  Future<void> _completeRideFromHistory(TripHistoryItem trip) async {
    if (_authToken == null) {
      _showErrorSnackbar('Please login to continue');
      return;
    }

    String? selectedPaymentMethod;
    final TextEditingController otpController = TextEditingController();

    final shouldComplete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text('Complete Ride'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 64,
                      color: Colors.green[700],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method Selection
                    Row(
                      children: [
                        // Wallet Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedPaymentMethod = 'wallet'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedPaymentMethod == 'wallet' 
                                    ? Colors.green[50] 
                                    : Colors.white,
                                border: Border.all(
                                  color: selectedPaymentMethod == 'wallet' 
                                      ? Colors.green[700]! 
                                      : Colors.grey[300]!,
                                  width: selectedPaymentMethod == 'wallet' ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Center(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Wallet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: selectedPaymentMethod == 'wallet' 
                                                ? Colors.green[700] 
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Deduct from wallet',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedPaymentMethod == 'wallet')
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Cash Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedPaymentMethod = 'cash'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedPaymentMethod == 'cash' 
                                    ? Colors.green[50] 
                                    : Colors.white,
                                border: Border.all(
                                  color: selectedPaymentMethod == 'cash' 
                                      ? Colors.green[700]! 
                                      : Colors.grey[300]!,
                                  width: selectedPaymentMethod == 'cash' ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Center(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cash',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: selectedPaymentMethod == 'cash' 
                                                ? Colors.green[700] 
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pay with cash',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedPaymentMethod == 'cash')
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Trip Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Fare:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${trip.fare}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // OTP Text Field for Completion from History
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.green[700],
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter 6-digit OTP to Complete',
                        hintText: '------',
                        hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 8),
                        counterText: '',
                        prefixIcon: const Icon(Icons.security, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: selectedPaymentMethod != null && otpController.text.length == 6
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Ride'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  
    if (shouldComplete == true && selectedPaymentMethod != null) {
      setState(() => _isLoading = true);
  
      // 🔍 DEBUG: Print karo kya send ho raha hai
      print('🔍 Completing ride with:');
      print('   Trip ID: ${trip.id}');
      print('   Payment Method: $selectedPaymentMethod');
      print('   Auth Token: ${_authToken?.substring(0, 20)}...');
  
      final result = await NonVehicleAuthService.completeRide(
        _authToken!,
        trip.id,
        selectedPaymentMethod!,
        otpController.text,
      );
  
      // 🔍 DEBUG: Print karo kya response aaya
      print('🔍 API Response:');
      print('   Success: ${result['success']}');
      print('   Message: ${result['message']}');
      print('   Full Response: $result');

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSuccessSnackbar('🏁 Ride completed successfully!');
        _loadTripHistory();
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // 🔍 DEBUG: Detailed error message
        final errorMsg = result['message'] ?? 'Failed to complete ride';
        print('❌ Error Details: $errorMsg');
        
        // Show detailed error to user
        _showErrorSnackbar('❌ $errorMsg');
        
        // Show debug dialog in debug mode
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Debug Info'),
              content: SingleChildScrollView(
                child: Text(
                  'Payment Method: $selectedPaymentMethod\n\n'
                  'Response: ${result.toString()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFFF5722);
      case 'ongoing':
      case 'started':
        return const Color(0xFF2196F3);
      case 'accepted':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Trip History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6F00), Color(0xFFFF9100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                _loadTripHistory();
              },
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<TripHistoryItem>>(
            future: _tripHistoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Loading trip history...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.deepOrange[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Failed to load trip history',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            _loadTripHistory();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.05),
                              Colors.green[50]!,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No trip history yet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your completed trips will appear here',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final trips = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  _loadTripHistory();
                  await _tripHistoryFuture;
                },
                color: const Color(0xFFFF6F00),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(trip);
                  },
                ),
              );
            },
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripHistoryItem trip) {
    final isAccepted = trip.status.toLowerCase() == 'accepted';
    final isStarted = trip.status.toLowerCase() == 'started';
    final isOngoing = isAccepted || isStarted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOngoing ? Border.all(
          color: isStarted ? Colors.blue[500]! : AppTheme.primary,
          width: 2,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: isOngoing 
                ? (isStarted ? Colors.blue : AppTheme.primary).withOpacity(0.2)
                : Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showTripDetails(trip);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Passenger name and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6F00), Color(0xFFFF9100)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            trip.passengerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF212121),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(trip.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isStarted ? Icons.directions_car : 
                          isAccepted ? Icons.check_circle : 
                          Icons.info,
                          size: 12,
                          color: _getStatusColor(trip.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trip.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(trip.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date and Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Color(0xFFFF6F00),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.date} • ${trip.time}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF6F00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Service Location
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Location',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trip.pickup,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Distance, Rating, and Fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.distance,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trip.rating > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFFFA726),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trip.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFFFA726),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '₹${trip.fare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              // START RIDE BUTTON FOR ACCEPTED RIDES
              if (isAccepted) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary.withOpacity(0.05), AppTheme.primary.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'This ride is waiting to be started',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _startRideFromHistory(trip),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text(
                            'Start Ride Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // COMPLETE RIDE BUTTON FOR STARTED RIDES
              if (isStarted) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[300]!, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, size: 18, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Ride is currently in progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //  UNCOMMENT WHEN PAYMENT INTEGRATION COME
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _completeRideFromHistory(trip),  // ✅ YE LINE USE
                          // onPressed: _isLoading ? null : () => _completeRideFromHistory(trip),
                          icon: const Icon(Icons.flag_rounded, size: 20),
                          label: const Text(
                            'Complete Ride',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTripDetails(TripHistoryItem trip) {
    final isAccepted = trip.status.toLowerCase() == 'accepted';
    final isStarted = trip.status.toLowerCase() == 'started';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6F00), Color(0xFFFF9100)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.person_rounded, 'Passenger', trip.passengerName),
            if (trip.passengerPhone != null)
              _buildDetailRow(Icons.phone_rounded, 'Phone', trip.passengerPhone!),
            _buildDetailRow(Icons.calendar_today_rounded, 'Date', trip.date),
            _buildDetailRow(Icons.access_time_rounded, 'Time', trip.time),
            _buildDetailRow(Icons.location_on_rounded, 'Service Type', trip.pickup),
            _buildDetailRow(Icons.timer_rounded, 'Duration', trip.distance),
            _buildDetailRow(Icons.payments_rounded, 'Fare', '₹${trip.fare.toStringAsFixed(2)}',
                valueColor: const Color(0xFF4CAF50)),
            if (trip.rating > 0)
              _buildDetailRow(Icons.star_rounded, 'Rating', '⭐' * trip.rating),
            _buildDetailRow(Icons.info_rounded, 'Status', trip.status.toUpperCase(),
                valueColor: _getStatusColor(trip.status)),
            
            // START RIDE BUTTON IN DETAILS MODAL
            if (isAccepted) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startRideFromHistory(trip);
                },
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text(
                  'Start Ride Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
            
            // COMPLETE RIDE BUTTON IN DETAILS MODAL
            if (isStarted) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _completeRideFromHistory(trip);
                },
                icon: const Icon(Icons.flag_rounded, size: 20),
                label: const Text(
                  'Complete Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6F00).withOpacity(0.15),
                  const Color(0xFF4CAF50).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFFFF6F00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: valueColor ?? const Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}