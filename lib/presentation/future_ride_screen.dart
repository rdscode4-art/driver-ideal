import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rideal_driver/presentation/widgets/app_logo.dart';
import '../controllers/future_ride_controller.dart';
import '../data/models/future_ride_models.dart';
import '../routes/app_pages.dart';
import '../core/utils/app_snackbar.dart';

class FutureRideScreen extends StatefulWidget {
  const FutureRideScreen({super.key});

  @override
  State<FutureRideScreen> createState() => _FutureRideScreenState();
}

class _FutureRideScreenState extends State<FutureRideScreen>
    with SingleTickerProviderStateMixin {
  // Tab Controller
  TabController? _tabController;

  // GetX Controller
  final FutureRideController _futureRideController = Get.put(
    FutureRideController(),
  );

  // Orange-Yellow Theme Colors (matching app theme)
  static const primaryOrange = Color(0xFFF57C00); // Orange 700
  static const lightOrange = Color(0xFFFFB74D); // Orange 300
  static const accentYellow = Color(0xFFFFD54F); // Amber 300
  static const darkOrange = Color(0xFFE65100); // Orange 900

  // Form related fields
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _priceController = TextEditingController();
  final _perSeatPriceController =
      TextEditingController(); // Add per seat price controller
  final _vehicleNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _availableSeats = 1;
  String _vehicleType = 'sedan';

  final List<String> _vehicleTypes = ['sedan', 'suv', 'auto', 'bike', 'ev'];
  final List<int> _seatOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  // GPS location loading state
  bool _isLoadingLocation = false;

  // Calculate total price based on per seat price and available seats
  void _calculateTotalPrice() {
    if (_perSeatPriceController.text.isNotEmpty) {
      try {
        double perSeatPrice = double.parse(_perSeatPriceController.text);
        double totalPrice = perSeatPrice * _availableSeats;
        _priceController.text = totalPrice.toStringAsFixed(0);
      } catch (e) {
        _priceController.text = '';
      }
    } else {
      _priceController.text = '';
    }
  }

  // Fetch current location
  Future<void> _getCurrentLocation() async {
    print('🔍 GPS button pressed - starting location fetch...');

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📡 Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        showErrorSnackBar(
          'Please enable location services in your device settings and try again.',
          title: 'Location Services Disabled',
        );
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        print('🔐 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🔐 Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          showErrorSnackBar(
            'Location permission is required to detect your current location. Please grant permission and try again.',
            title: 'Permission Denied',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions permanently denied');
        showErrorSnackBar(
          'Location permission is permanently denied. Please enable it in Settings > Privacy & Security > Location Services.',
          title: 'Permission Permanently Denied',
        );
        return;
      }

      print('✅ Permissions granted, getting position...');

      // Show loading feedback
      Get.showSnackbar(
        const GetSnackBar(
          messageText: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Detecting your location...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: primaryOrange,
          duration: Duration(
            seconds: 10,
          ), // Will be dismissed when location is found
          snackPosition: SnackPosition.TOP,
        ),
      );

      // Get current position with extended timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30), // Increased timeout
      );

      print(
        '📍 Position obtained: ${position.latitude}, ${position.longitude}',
      );

      // Dismiss loading snackbar
      Get.closeCurrentSnackbar();

      // Convert coordinates to address
      print('🗺️ Converting coordinates to address...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        print('🏠 Placemark found: ${place.toString()}');

        // Build address string with fallbacks
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        String address = addressParts.join(', ');

        // Fallback if no proper address is found
        if (address.trim().isEmpty) {
          address =
              'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }

        print('📝 Final address: $address');

        setState(() {
          _fromController.text = address.trim();
        });

        showSuccessSnackBar(
          'Your current location has been set successfully.',
          title: 'Location Detected!',
        );
      } else {
        print('⚠️ No placemarks found for coordinates');
        // Still use coordinates as fallback
        String coordAddress =
            'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        setState(() {
          _fromController.text = coordAddress;
        });

        showWarningSnackBar(
          'Using coordinates as address. You can edit this field if needed.',
          title: 'Location Detected',
        );
      }
    } catch (e) {
      print('❌ GPS Error: $e');
      Get.closeCurrentSnackbar(); // Dismiss any loading snackbar

      String errorMessage = 'Failed to get location';
      if (e.toString().contains('timeout')) {
        errorMessage =
            'Location request timed out. Please try again or check your GPS signal.';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error while getting location. Please check your internet connection.';
      } else {
        errorMessage = 'Unable to get location: ${e.toString()}';
      }

      showErrorSnackBar(errorMessage, title: 'Location Error');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
      print('🏁 GPS location fetch completed');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
    _perSeatPriceController.dispose(); // Dispose per seat price controller
    _vehicleNumberController.dispose();
    _vehicleColorController.dispose();
    _vehicleNameController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createRideOffer() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        showErrorSnackBar('Please select a date', title: 'Error');
        return;
      }
      if (_selectedTime == null) {
        showErrorSnackBar('Please select a time', title: 'Error');
        return;
      }

      // Format time as HH:MM
      final timeString =
          "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

      // Call the real API through the controller using vehicle name from text field
      final success = await _futureRideController.createFutureRide(
        fromAddress: _fromController.text.trim(),
        toAddress: _toController.text.trim(),
        selectedDate: _selectedDate!,
        selectedTime: timeString,
        pricePerSeat: double.parse(_priceController.text),
        vehicleName: _vehicleNameController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        driverPhone: _driverPhoneController.text.trim(),
        maxPassengers: _availableSeats,
      );

      if (success) {
        // Clear form after successful submission
        _formKey.currentState!.reset();
        _fromController.clear();
        _toController.clear();
        _priceController.clear();
        _perSeatPriceController.clear(); // Clear per seat price controller
        _vehicleNumberController.clear();
        _vehicleColorController.clear();
        _vehicleNameController.clear();
        _driverNameController.clear();
        _driverPhoneController.clear();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _availableSeats = 1;
          _vehicleType = 'sedan';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Future Rides',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: primaryOrange,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: AppLogo(
            width: 130,
            height: 130,
            margin: EdgeInsets.only(bottom: 0.0),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(
          width: 120,
          height: 120,
          margin: EdgeInsets.only(bottom: 0.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[500]!,
        automaticallyImplyLeading: false,
        elevation: 3,
        bottom: TabBar(
          controller: _tabController!,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.add_road, size: 20), text: 'Create Offer'),
            Tab(icon: Icon(Icons.schedule, size: 20), text: 'Active Rides'),
            Tab(icon: Icon(Icons.inbox, size: 20), text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildCreateRideOfferTab(),
          _buildActiveFutureRidesTab(),
          _buildRideRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildCreateRideOfferTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            // Card(
            //   elevation: 4,
            //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            //   child: Container(
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(15),
            //       gradient: LinearGradient(
            //         colors: [lightOrange.withValues(alpha: 0.1), accentYellow.withValues(alpha: 0.1)],
            //         begin: Alignment.topLeft,
            //         end: Alignment.bottomRight,
            //       ),
            //     ),
            //     child: Padding(
            //       padding: EdgeInsets.all(20),
            //       child: Column(
            //         children: [
            //           Icon(
            //             Icons.add_road,
            //             size: 48,
            //             color: primaryOrange,
            //           ),
            //           SizedBox(height: 12),
            //           Text(
            //             'Offer Your Route',
            //             style: TextStyle(
            //               fontSize: 22,
            //               fontWeight: FontWeight.bold,
            //               color: darkOrange,
            //             ),
            //           ),
            //           SizedBox(height: 8),
            //           Text(
            //             'Share your journey and earn money by offering rides to passengers',
            //             textAlign: TextAlign.center,
            //             style: TextStyle(
            //               fontSize: 14,
            //               color: Colors.grey[600],
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 24),

            // Route Section
            const Text(
              'Route Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkOrange,
              ),
            ),
            const SizedBox(height: 16),

            // From Location
            TextFormField(
              controller: _fromController,
              decoration: InputDecoration(
                labelText: 'From Location',
                labelStyle: const TextStyle(color: primaryOrange),
                hintText: 'Enter pickup location or tap GPS to detect',
                prefixIcon: const Icon(Icons.my_location, color: primaryOrange),
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryOrange,
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.gps_fixed, color: primaryOrange),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Detect current location',
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pickup location';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // To Location
            TextFormField(
              controller: _toController,
              decoration: InputDecoration(
                labelText: 'To Location',
                labelStyle: const TextStyle(color: primaryOrange),
                hintText: 'Enter destination (e.g., Jaipur)',
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter destination';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Date & Time Section
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkOrange,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Date Picker
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: lightOrange.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: primaryOrange,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDate != null
                                      ? darkOrange
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Time Picker
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: lightOrange.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: primaryOrange),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select time',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedTime != null
                                      ? darkOrange
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Driver Details Section
            const Text(
              'RiDeal Driver Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkOrange,
              ),
            ),
            const SizedBox(height: 16),

            // Driver Phone Number
            TextFormField(
              controller: _driverPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile/Search RiDeal Driver',
                labelStyle: const TextStyle(color: primaryOrange),
                prefixIcon: const Icon(Icons.phone, color: primaryOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter driver phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Vehicle Details Section
            const Text(
              'Vehicle Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkOrange,
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Type
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                labelStyle: const TextStyle(color: primaryOrange),
                prefixIcon: const Icon(
                  Icons.directions_car,
                  color: primaryOrange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              items: _vehicleTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _vehicleType = newValue!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Vehicle Name
            TextFormField(
              controller: _vehicleNameController,
              decoration: InputDecoration(
                labelText: 'Vehicle Name',
                labelStyle: const TextStyle(color: primaryOrange),
                hintText: 'Enter vehicle name (e.g., Toyota Corolla)',
                prefixIcon: const Icon(Icons.car_repair, color: primaryOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Vehicle Number
            TextFormField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number',
                labelStyle: const TextStyle(color: primaryOrange),
                prefixIcon: const Icon(
                  Icons.confirmation_number,
                  color: primaryOrange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Vehicle Color
            TextFormField(
              controller: _vehicleColorController,
              decoration: InputDecoration(
                labelText: 'Vehicle Color',
                labelStyle: const TextStyle(color: primaryOrange),
                prefixIcon: const Icon(Icons.color_lens, color: primaryOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle color';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Available Seats
            DropdownButtonFormField<int>(
              initialValue: _availableSeats,
              decoration: InputDecoration(
                labelText: 'Available Seats',
                labelStyle: const TextStyle(color: primaryOrange),
                prefixIcon: const Icon(Icons.event_seat, color: primaryOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              items: _seatOptions.map((int seats) {
                return DropdownMenuItem<int>(
                  value: seats,
                  child: Text('$seats ${seats == 1 ? 'Seat' : 'Seats'}'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _availableSeats = newValue!;
                });
                _calculateTotalPrice(); // Recalculate total price when seats change
              },
            ),

            const SizedBox(height: 16),

            // Price per seat
            TextFormField(
              controller: _perSeatPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price per Seat (₹)',
                labelStyle: const TextStyle(color: primaryOrange),
                hintText: 'Enter price per seat in ₹ (e.g., 100)',
                prefixIcon: const Icon(
                  Icons.currency_rupee,
                  color: primaryOrange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price per seat';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onChanged: (value) {
                _calculateTotalPrice(); // Recalculate total price when per seat price changes
              },
            ),

            const SizedBox(height: 24),

            // Pricing Section
            const Text(
              'Total Price',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkOrange,
              ),
            ),
            const SizedBox(height: 16),

            // Total price (read-only)
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Total Amount (₹)',
                labelStyle: const TextStyle(color: primaryOrange),
                hintText: 'Total amount will be calculated automatically',
                prefixIcon: const Icon(
                  Icons.currency_rupee,
                  color: primaryOrange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
              readOnly: true,
            ),

            const SizedBox(height: 32),

            // Create Offer Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(
                () => ElevatedButton(
                  onPressed: _futureRideController.isLoading.value
                      ? null
                      : _createRideOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: primaryOrange.withValues(alpha: 0.3),
                  ),
                  child: _futureRideController.isLoading.value
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Creating Offer...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Create Ride Offer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFutureRidesTab() {
    return Obx(() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      lightOrange.withValues(alpha: 0.1),
                      accentYellow.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 48,
                        color: primaryOrange,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Future Rides',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: darkOrange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your upcoming scheduled rides',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _futureRideController.refreshActiveRides(),
                        icon: const Icon(Icons.refresh, color: primaryOrange),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Loading or Content
            if (_futureRideController.isLoadingRides.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                  ),
                ),
              )
            else if (_futureRideController.activeFutureRides.isEmpty)
              _buildEmptyState(
                Icons.schedule,
                'No Active Future Rides',
                'You don\'t have any scheduled rides yet. Create a ride offer to get started!',
              )
            else
              ...List.generate(_futureRideController.activeFutureRides.length, (
                index,
              ) {
                final ride = _futureRideController.activeFutureRides[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildActiveRideCardFromData(ride),
                );
              }),
          ],
        ),
      );
    });
  }

  Widget _buildActiveRideCardFromData(FutureRide ride) {
    final route = '${ride.fromLocation.address} to ${ride.toLocation.address}';
    final dateTime =
        '${ride.date.day}/${ride.date.month}/${ride.date.year} - ${ride.time}';
    final price = '₹${ride.pricePerPassenger.toInt()} per seat';
    final seatsInfo =
        '${ride.passengersBooked.length} of ${ride.maxPassengers} seats booked';
    final statusColor = ride.status == 'active' ? primaryOrange : lightOrange;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        dateTime,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ride.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vehicle and Driver Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 16,
                        color: primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Text('${ride.vehicle.name} (${ride.vehicle.color})'),
                      const Spacer(),
                      Text(
                        ride.vehicle.numberPlate,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: primaryOrange),
                      const SizedBox(width: 8),
                      Text(ride.driverPhone),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
                ),
                Text(
                  seatsInfo,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.toNamed(Routes.FUTURE_RIDE_DETAILS, arguments: ride);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryOrange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: primaryOrange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showWarningSnackBar(
                        'Cancel functionality coming soon!',
                        title: 'Info',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideRequestsTab() {
    return Obx(() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card with pending requests count
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.inbox, size: 48, color: Colors.black),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Passenger Requests',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _futureRideController.totalPendingRequests > 0
                                ? '${_futureRideController.totalPendingRequests} pending request${_futureRideController.totalPendingRequests > 1 ? 's' : ''} from passengers'
                                : 'Review and manage booking requests from passengers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _futureRideController.refreshRideRequests(),
                      icon: const Icon(Icons.refresh, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Loading or Content
            if (_futureRideController.isLoadingRequests.value)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading ride requests...',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else if (_futureRideController.rideRequests.isEmpty)
              _buildEmptyState(
                Icons.inbox,
                'No Ride Requests',
                'You don\'t have any passenger requests at the moment. Passengers will be able to request rides for your future ride offers.',
              )
            else
              ...List.generate(_futureRideController.rideRequests.length, (
                index,
              ) {
                final rideWithRequests =
                    _futureRideController.rideRequests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRideRequestCard(rideWithRequests),
                );
              }),
          ],
        ),
      );
    });
  }

  Widget _buildRideRequestCard(FutureRideWithRequests rideWithRequests) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rideWithRequests.routeText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        rideWithRequests.dateTimeText,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rideWithRequests.pendingRequestsCount} PENDING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${rideWithRequests.vehicle.name} (${rideWithRequests.vehicle.color})',
                  ),
                  const Spacer(),
                  Text(
                    rideWithRequests.vehicle.numberPlate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Passenger Requests (${rideWithRequests.passengersBooked.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...rideWithRequests.passengersBooked.map(
              (booking) => _buildPassengerRequestCard(booking),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerRequestCard(PassengerBooking booking) {
    Color statusColor = booking.status == 'pending'
        ? Colors.orange
        : booking.status == 'accepted'
        ? Colors.green
        : Colors.red;

    return Dismissible(
      key: Key('booking_${booking.bookingId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Delete Request'),
                content: Text(
                  'Are you sure you want to delete ${booking.rider.name}\'s request? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        _removeBookingLocally(booking.bookingId);
        showSuccessSnackBar(
          '${booking.rider.name}\'s request has been removed from your list',
          title: 'Request Deleted',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: statusColor.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    booking.rider.name.isNotEmpty
                        ? booking.rider.name[0].toUpperCase()
                        : 'P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            booking.rider.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            booking.rider.phone,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            booking.rider.gender,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.swipe_left, color: Colors.grey[400], size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_seat, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${booking.numOfSeats} seat${booking.numOfSeats > 1 ? 's' : ''} requested',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (booking.rider.rating > 0) ...[
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    booking.rider.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (booking.rider.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.rider.address,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm =
                            await Get.dialog<bool>(
                              AlertDialog(
                                title: const Text('Reject Request'),
                                content: Text(
                                  'Are you sure you want to reject ${booking.rider.name}\'s request for ${booking.numOfSeats} seat${booking.numOfSeats > 1 ? 's' : ''}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (confirm) {
                          try {
                            String? rideId;
                            for (var ride
                                in _futureRideController.rideRequests) {
                              if (ride.passengersBooked.any(
                                (b) => b.bookingId == booking.bookingId,
                              )) {
                                rideId = ride.id;
                                break;
                              }
                            }

                            if (rideId != null) {
                              await _futureRideController.rejectBookingRequest(
                                rideId,
                                booking.bookingId,
                              );
                            }
                          } catch (e) {
                            showErrorSnackBar(
                              'Failed to reject booking',
                              title: 'Error',
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm =
                            await Get.dialog<bool>(
                              AlertDialog(
                                title: const Text('Accept Request'),
                                content: Text(
                                  'Accept ${booking.rider.name}\'s request for ${booking.numOfSeats} seat${booking.numOfSeats > 1 ? 's' : ''}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green,
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (confirm) {
                          String? rideId;
                          for (var ride in _futureRideController.rideRequests) {
                            if (ride.passengersBooked.any(
                              (b) => b.bookingId == booking.bookingId,
                            )) {
                              rideId = ride.id;
                              break;
                            }
                          }

                          if (rideId != null) {
                            await _futureRideController.acceptBookingRequest(
                              rideId,
                              booking.bookingId,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(icon, size: 80, color: lightOrange.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  _removeBookingLocally(String bookingId) {
    final rideRequest = _futureRideController.rideRequests.firstWhereOrNull(
      (ride) => ride.passengersBooked.any(
        (booking) => booking.bookingId == bookingId,
      ),
    );

    if (rideRequest != null) {
      rideRequest.passengersBooked.removeWhere(
        (booking) => booking.bookingId == bookingId,
      );
      if (rideRequest.passengersBooked.isEmpty) {
        _futureRideController.rideRequests.remove(rideRequest);
      }
      _futureRideController.update();
    }
  }
}
