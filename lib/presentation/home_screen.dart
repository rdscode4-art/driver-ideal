import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';
import 'package:rideal_driver/presentation/drawar.dart';
import 'package:rideal_driver/presentation/kycdocumentsviewerscreen.dart';
import 'package:rideal_driver/presentation/widgets/contact_info_section.dart';
import '../controllers/home_controller.dart';
import '../controllers/earnings_controller.dart';
import '../routes/app_pages.dart';
import 'widgets/social_media_links.dart';
import '../core/sound_manager.dart';
import '../fcm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController homeController;
  String selectedPeriod = 'Daily';

  @override
  void initState() {
    super.initState();
    // Initialize controller lazily to prevent early creation
    homeController = Get.put(HomeController());
    Get.put(EarningsController());

    // Load initial data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      homeController.loadAvailableRidesCount();
      homeController.checkOngoingRide(); // Check for ongoing ride immediately
      // Start auto-refresh for status
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    // Auto-refresh status every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        homeController.refreshStatus(isSilent: true);
        _startAutoRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        durationUntilAlertAgain: const Duration(seconds: 1),
        debugLogging: false,
        debugDisplayAlways: false,
      ),
      barrierDismissible: false,
      showIgnore: false,
      showLater: false,
      shouldPopScope: () => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        drawer: const CustomDrawer(),
        body: CustomScrollView(
          slivers: [
            _buildEnhancedAppBar(context),
            // Custom App Bar with gradient
            // SliverAppBar(

            //   expandedHeight: 255,
            //   backgroundColor: Colors.transparent,
            //   elevation: 0,
            //   pinned: true,
            //   flexibleSpace: FlexibleSpaceBar(
            //     background: Container(
            //       decoration: BoxDecoration(
            //         gradient: LinearGradient(
            //           colors: [Colors.orange[600]!, Colors.orange[300]!],
            //           begin: Alignment.topLeft,
            //           end: Alignment.bottomRight,
            //         ),
            //         borderRadius: const BorderRadius.only(
            //           bottomLeft: Radius.circular(25),
            //           bottomRight: Radius.circular(25),
            //         ),
            //       ),
            //       child: const Padding(
            //         padding: EdgeInsets.fromLTRB(20, 0, 20, 60),
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           mainAxisAlignment: MainAxisAlignment.start,
            //           children: [
            //             SizedBox(height: 50),
            //             // App Logo at the top
            //             Center(
            //               child: Image(
            //                 height: 150,
            //                 image: AssetImage("assets/images/logo.png"),
            //               ),
            //             ),
            //             Spacer(),
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //               children: [
            //                 Expanded(
            //                   child: Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     children: [
            //                       SizedBox(height: 4),
            //                       Text(
            //                         'RiDeal Driver',
            //                         style: TextStyle(
            //                           color: Colors.white,
            //                           fontSize: 24,
            //                           fontWeight: FontWeight.bold,
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // Body content
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Driver Status Card
                  _buildDriverStatusCard(context),

                  // Ongoing Ride Status Card (shows when there's an active ride)
                  _buildOngoingRideStatusCard(context),

                  // Ride Request Notifications List
                  _buildRideRequestsListCard(context),

                  // Quick Actions Section (Enhanced with 4 cards)
                  _buildEnhancedQuickActionsSection(context),

                  // Today's Work Report Section
                  _buildTodaysWorkReportCard(context),

                  // Tip Section
                  _buildTipSection(),

                  const SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => SubscriptionPlansScreen(),
                  //       ),
                  //     );
                  //   },
                  //   child: Text("Subscription"),
                  // ),
                  // const SizedBox(height: 10),

                  // Social Media Links
                  const SocialMediaLinksEnhanced(),

                  const ContactInfoSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor =
        screenWidth /
        393; // Increased base width to 411 for more subtle scaling

    return SliverAppBar(
      expandedHeight: 230 * scaleFactor, // Increased to fit larger logo
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F9D58), // Brand Green
      actions: [
        IconButton(
          onPressed: () => homeController.refreshData(),
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh All Data',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0A6B3C), // Dark Green
                Color(0xFF0F9D58), // Brand Green
                Color(0xFF4CB050), // Light Green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50 * scaleFactor,
                right: -50 * scaleFactor,
                child: Container(
                  width: 200 * scaleFactor,
                  height: 200 * scaleFactor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30 * scaleFactor,
                left: -30 * scaleFactor,
                child: Container(
                  width: 150 * scaleFactor,
                  height: 150 * scaleFactor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Subtle Glow Accent
              Positioned(
                top: 20 * scaleFactor,
                left: 40 * scaleFactor,
                child: Container(
                  width: 100 * scaleFactor,
                  height: 100 * scaleFactor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.limeAccent.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20 * scaleFactor,
                  0,
                  20 * scaleFactor,
                  20 * scaleFactor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Logo
                    Center(
                      child: Image(
                        height: 110 * scaleFactor, // Increased from 90
                        image: const AssetImage("assets/images/logo.png"),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    Obx(
                      () => homeController.driverInfo.value != null
                          ? Column(
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14 * scaleFactor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactor),
                                Text(
                                  homeController.driverInfo.value!.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5 * scaleFactor,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'RiDeal Driver',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22 * scaleFactor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverStatusCard(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 393;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 18 * scaleFactor,
        vertical: 3 * scaleFactor,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scaleFactor),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(14 * scaleFactor),
          child: Column(
            children: [
              Row(
                children: [
                  Obx(
                    () => homeController.isStatusLoading.value
                        ? SizedBox(
                            width: 16 * scaleFactor,
                            height: 16 * scaleFactor,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0F9D58),
                              ),
                            ),
                          )
                        : Container(
                            width: 10 * scaleFactor,
                            height: 10 * scaleFactor,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: homeController.isOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                  ),
                  SizedBox(width: 8 * scaleFactor),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Text(
                            homeController.status.value,
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: homeController.isOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                        // Display driver name if available
                        Obx(
                          () => homeController.driverInfo.value != null
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    top: 2 * scaleFactor,
                                  ),
                                  child: Text(
                                    '(${homeController.driverInfo.value!.name})',
                                    style: TextStyle(
                                      fontSize: 12 * scaleFactor,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: homeController.isStatusLoading.value
                        ? null
                        : () => homeController.refreshStatus(),
                    icon: Icon(
                      Icons.refresh,
                      size: 18 * scaleFactor,
                      color: Colors.grey[600],
                    ),
                    padding: EdgeInsets.all(4 * scaleFactor),
                    constraints: BoxConstraints(
                      minWidth: 28 * scaleFactor,
                      minHeight: 28 * scaleFactor,
                    ),
                  ),
                  // Toggle switch for driver availability
                  Obx(
                    () => Transform.scale(
                      scale: 0.8 * scaleFactor,
                      child: Switch(
                        value: homeController.isOnline,
                        onChanged: (val) {
                          if (homeController.isLoading.value || 
                              homeController.isStatusLoading.value) return;
                          homeController.toggleDriverAvailability();
                        },
                        activeThumbColor: Colors.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: homeController.isOnline
                        ? Colors.green[50]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        homeController.isOnline
                            ? Icons.check_circle
                            : Icons.info,
                        color: homeController.isOnline
                            ? Colors.green
                            : Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          homeController.isOnline
                              ? 'You are available and ready to receive requests'
                              : 'Toggle switch to go online and start receiving requests',
                          style: TextStyle(
                            color: homeController.isOnline
                                ? Colors.green[800]
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (homeController.driverStatus.value != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: homeController.isOnline
                                ? Colors.green[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Replace your _buildOngoingRideStatusCard() method with this enhanced version

  Widget _buildOngoingRideStatusCard(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 393;

    return Obx(() {
      // Debug logging
      // ... (rest of logging remains same)

      // If no ongoing ride, show nothing
      if (!homeController.hasOngoingRide.value &&
          homeController.ongoingRide.value == null) {
        return const SizedBox.shrink();
      }

      // If flag is true but no ride object, try to fetch it
      if (homeController.hasOngoingRide.value &&
          homeController.ongoingRide.value == null) {
        // Trigger fetch in next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homeController.checkAndFetchOngoingRide();
        });
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: 18 * scaleFactor,
            vertical: 4 * scaleFactor,
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12 * scaleFactor),
            ),
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.1),
            color: const Color(0xFFE8F5E9), // lightGreen
            child: Padding(
              padding: EdgeInsets.all(14 * scaleFactor),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      }

      final ride = homeController.ongoingRide.value!;

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: 18 * scaleFactor,
          vertical: 4 * scaleFactor,
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scaleFactor),
          ),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          color: const Color(0xFFE8F5E9), // lightGreen
          child: InkWell(
            onTap: () {
              print('🔔 Ongoing ride card tapped, navigating...');
              homeController.navigateToOngoingRide();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8 * scaleFactor),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withOpacity(0.3), // accentGreen light
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.drive_eta,
                          color: const Color(0xFF0F9D58), // primaryGreen
                          size: 24 * scaleFactor,
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Ride in Progress',
                              style: TextStyle(
                                fontSize: 16 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A6B3C), // darkGreen
                              ),
                            ),
                            SizedBox(height: 2 * scaleFactor),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6 * scaleFactor,
                                    vertical: 2 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[200],
                                    borderRadius: BorderRadius.circular(
                                      4 * scaleFactor,
                                    ),
                                  ),
                                  child: Text(
                                    ride.rideType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10 * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6 * scaleFactor),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6 * scaleFactor,
                                    vertical: 2 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(ride.status),
                                    borderRadius: BorderRadius.circular(
                                      4 * scaleFactor,
                                    ),
                                  ),
                                  child: Text(
                                    ride.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10 * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Fare Display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scaleFactor,
                          vertical: 8 * scaleFactor,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8 * scaleFactor),
                        ),
                        child: Text(
                          ride.formattedFare,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * scaleFactor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location Details
                  Container(
                    padding: EdgeInsets.all(12 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                      border: Border.all(color: const Color(0xFFE8F5E9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup Location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: const Icon(
                                Icons.radio_button_checked,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pickup',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ride.pickupaddress.toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Connecting Line
                        Container(
                          margin: const EdgeInsets.only(
                            left: 8,
                            top: 4,
                            bottom: 4,
                          ),
                          height: 20,
                          width: 2,
                          color: Colors.grey[300],
                        ),

                        // Dropoff Location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dropoff',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ride.dropaddress.toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('📱 View Ride Details button pressed');
                        homeController.navigateToOngoingRide();
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text(
                        'View Ride Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58), // primaryGreen
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  // Tap hint
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tap anywhere on this card to open ride',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue[600]!;
      case 'ongoing':
      case 'started':
        return Colors.orange[600]!;
      case 'completed':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildRideRequestsListCard(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 393;

    return Obx(() {
      if (!homeController.isOnline || homeController.nearbyRides.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: 18 * scaleFactor,
          vertical: 4 * scaleFactor,
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scaleFactor),
          ),
          elevation: 3,
          color: Colors.orange[50],
          child: Padding(
            padding: EdgeInsets.all(14 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notification_important,
                        color: Colors.orange[700],
                        size: 20 * scaleFactor,
                      ),
                    ),
                    SizedBox(width: 10 * scaleFactor),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride Requests Available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            '${homeController.nearbyRides.length} rides waiting',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scaleFactor,
                        vertical: 4 * scaleFactor,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      child: Text(
                        '${homeController.nearbyRides.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * scaleFactor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // List of all available rides
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: homeController.nearbyRides.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ride = homeController.nearbyRides[index];
                    return Container(
                      padding: EdgeInsets.all(12 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10 * scaleFactor),
                        border: Border.all(color: Colors.orange[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.1),
                            blurRadius: 4 * scaleFactor,
                            offset: Offset(0, 2 * scaleFactor),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF81C784).withOpacity(0.3), // accentGreen
                                      borderRadius: BorderRadius.circular(
                                        4 * scaleFactor,
                                      ),
                                    ),
                                    child: Text(
                                      'Ride #${index + 1}',
                                      style: TextStyle(
                                        fontSize: 10 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0A6B3C), // darkGreen
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ride.rideType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                ride.formattedFare,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.radio_button_checked,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ride.pickupaddress.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ride.dropaddress.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // 🎵 Stop sounds immediately when user takes action
                                    SoundManager().stopRequestSound();
                                    FCMService.stopRequestSound();

                                    // Remove ride from list
                                    homeController.nearbyRides.removeAt(index);
                                  },
                                  icon: const Icon(Icons.close, size: 14),
                                  label: const Text(
                                    'Ignore',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[700],
                                    side: BorderSide(color: Colors.grey[300]!),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // 🎵 Stop sounds immediately
                                    SoundManager().stopRequestSound();
                                    FCMService.stopRequestSound();
                                    homeController.quickAcceptRide(
                                      ride.id,
                                      context,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Accept Ride',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTipSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for Better Earnings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Maintain a high acceptance rate to get more ride requests.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '2. Complete trips efficiently to improve your completion rate.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '3. Keep your vehicle clean and well-maintained for better ratings.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                '4. Be polite and professional to passengers to earn higher tips.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Text(
                'Bonus Tip: Drive safely and follow traffic rules to avoid penalties.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysWorkReportCard(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 393;
    final earningsController = Get.find<EarningsController>();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 14 * scaleFactor,
        vertical: 8 * scaleFactor,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scaleFactor),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16 * scaleFactor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Work Report",
                style: TextStyle(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12 * scaleFactor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Obx(() => Text(
                            '₹${earningsController.todayEarnings.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          )),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: 12 * scaleFactor,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 30 * scaleFactor,
                    width: 1 * scaleFactor,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Obx(() => Text(
                            '${earningsController.consecutiveTrips.value}',
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          )),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        'Trips',
                        style: TextStyle(
                          fontSize: 12 * scaleFactor,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedQuickActionsSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 393;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 14 * scaleFactor,
        vertical: 8 * scaleFactor,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20 * scaleFactor),
        ),
        elevation: 4,
        shadowColor: Colors.blue.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20 * scaleFactor),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!.withValues(alpha: 0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scaleFactor,
              vertical: 20 * scaleFactor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.dashboard_customize,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Four quick action cards in two rows
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedQuickActionButton(
                            context,
                            'Ride History',
                            Icons.history,
                            Colors.blue,
                            'View Past Trips',
                            Icons.timeline,
                            () => Get.toNamed(Routes.TRIP_HISTORY),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildEnhancedQuickActionButton(
                            context,
                            'Documents',
                            Icons.description_outlined,
                            Colors.teal,
                            'View Documents',
                            Icons.folder_open,
                            () => Get.to(
                              () => const KYCDocumentsViewerScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedQuickActionButton(
                            context,
                            'Subscription',
                            Icons.card_membership,
                            Colors.teal,
                            'Manage Plans',
                            Icons.star,
                            () => Get.toNamed(Routes.SUBSCRIPTION),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildEnhancedQuickActionButton(
                            context,
                            'Refer & Earn',
                            Icons.card_giftcard,
                            Colors.purple,
                            'Invite Friends',
                            Icons.group_add,
                            () => Get.toNamed(Routes.REWARDS),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedQuickActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    IconData backgroundIcon,
    VoidCallback onTap,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 393;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * scaleFactor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(18 * scaleFactor),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.5 * scaleFactor,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8 * scaleFactor,
              offset: Offset(0, 4 * scaleFactor),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icon
            Positioned(
              right: -8 * scaleFactor,
              top: -8 * scaleFactor,
              child: Icon(
                backgroundIcon,
                size: 35 * scaleFactor,
                color: color.withValues(alpha: 0.1),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8 * scaleFactor),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10 * scaleFactor),
                      ),
                      child: Icon(icon, color: color, size: 20 * scaleFactor),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color.withValues(alpha: 0.7),
                      size: 12 * scaleFactor,
                    ),
                  ],
                ),
                SizedBox(height: 12 * scaleFactor),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11 * scaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrackingCard(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 393;

    return Obx(() {
      // Only show if there's an ongoing ride or location tracking is active
      if (!homeController.hasOngoingRide.value &&
          !homeController.isLocationTracking.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: 18 * scaleFactor,
          vertical: 4 * scaleFactor,
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scaleFactor),
          ),
          elevation: 2,
          color: homeController.isLocationTracking.value
              ? Colors.green[50]
              : Colors.orange[50],
          child: Padding(
            padding: EdgeInsets.all(14 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6 * scaleFactor),
                      decoration: BoxDecoration(
                        color: homeController.isLocationTracking.value
                            ? Colors.green[100]
                            : Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        homeController.isLocationTracking.value
                            ? Icons.location_on
                            : Icons.location_off,
                        color: homeController.isLocationTracking.value
                            ? Colors.green[700]
                            : Colors.orange[700],
                        size: 20 * scaleFactor,
                      ),
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Tracking',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * scaleFactor,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            homeController.locationUpdateStatus.value,
                            style: TextStyle(
                              fontSize: 12 * scaleFactor,
                              color: homeController.isLocationTracking.value
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status indicator
                    Container(
                      width: 12 * scaleFactor,
                      height: 12 * scaleFactor,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: homeController.isLocationTracking.value
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Location info and stats
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: homeController.isLocationTracking.value
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (homeController.isLocationTracking.value) ...[
                        // Active tracking info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Updates sent:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${homeController.locationUpdateCount.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Update interval:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${HomeController.locationUpdateIntervalSeconds}s',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        if (homeController.locationUpdateErrors.value > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Errors:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${homeController.locationUpdateErrors.value}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Current coordinates (for debugging)
                        if (homeController.currentLatitude.value != 0.0) ...[
                          Text(
                            'Current: ${homeController.currentLatitude.value.toStringAsFixed(4)}, ${homeController.currentLongitude.value.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ] else ...[
                        // Not tracking
                        Text(
                          'Location sharing not active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    if (!homeController.isLocationTracking.value &&
                        homeController.hasOngoingRide.value) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => homeController
                              .startLocationTrackingForOngoingRide(),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text(
                            'Start Tracking',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ] else if (homeController.isLocationTracking.value) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              homeController.stopLocationTracking(),
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text(
                            'Stop Tracking',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Refresh button
                      ElevatedButton(
                        onPressed: () =>
                            homeController.ensureLocationTrackingIsActive(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(40, 36),
                        ),
                        child: const Icon(Icons.refresh, size: 16),
                      ),
                    ],
                  ],
                ),

                // API endpoint info (for debugging)
                if (homeController.currentRideId.value != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'API: backend.ridealmobility.com/rides/${homeController.currentRideId.value}/driver-location',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
