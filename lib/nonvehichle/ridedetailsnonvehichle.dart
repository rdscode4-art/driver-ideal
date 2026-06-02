import 'package:flutter/material.dart';
import 'package:rideal_driver/nonvehichle/nonvehichledashboard.dart';
import 'package:url_launcher/url_launcher.dart';

// Ride Details Screen - Mirroring the style from Trip History Details
class RideDetailsScreennonvehichle extends StatelessWidget {
  final OngoingRide ride;
  final Function(OngoingRide)? onComplete;
  final Function(OngoingRide)? onStart;

  const RideDetailsScreennonvehichle({
    super.key, 
    required this.ride,
    this.onComplete,
    this.onStart,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
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
    final isAccepted = ride.status.toLowerCase() == 'accepted';
    final isStarted = ride.status.toLowerCase() == 'started';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Ride Details',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Trip Summary',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ride.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(ride.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ride.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(ride.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 24),
              
              _buildDetailRow(Icons.person_rounded, 'Passenger', ride.passengerName),
              _buildDetailRow(Icons.phone_rounded, 'Phone', ride.passengerPhone, 
                onAction: () => _makePhoneCall(ride.passengerPhone),
                actionIcon: Icons.call,
                actionColor: Colors.green),
              
              _buildDetailRow(Icons.location_on_rounded, 'Pickup Location', ride.pickup),
              // Drop-off removed for non-vehicle rides
              // _buildDetailRow(Icons.location_searching_rounded, 'Drop-off', ride.dropoff),
              _buildDetailRow(Icons.timer_rounded, 'Duration', ride.distance),
              
              _buildDetailRow(Icons.payments_rounded, 'Total Fare', '₹${ride.fare.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF4CAF50)),
              
              if (ride.rating > 0)
                _buildDetailRow(Icons.star_rounded, 'Rating', '⭐' * ride.rating.round()),

              const SizedBox(height: 32),
              
              // Action Buttons
              if (isAccepted)
                ElevatedButton.icon(
                  onPressed: () {
                    if (onStart != null) {
                      onStart!(ride);
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 24),
                  label: const Text(
                    'Start Ride Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F00),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFFF6F00).withOpacity(0.4),
                  ),
                ),
              
              if (isStarted)
                ElevatedButton.icon(
                  onPressed: () {
                    if (onComplete != null) {
                      onComplete!(ride);
                    }
                  },
                  icon: const Icon(Icons.flag_rounded, size: 24),
                  label: const Text(
                    'Complete Ride',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
                  ),
                ),
                
              const SizedBox(height: 16),
              

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, 
      {Color? valueColor, VoidCallback? onAction, IconData? actionIcon, Color? actionColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6F00).withOpacity(0.1),
                  const Color(0xFF4CAF50).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFFF6F00),
            ),
          ),
          const SizedBox(width: 16),
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
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: valueColor ?? const Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null)
            IconButton(
              icon: Icon(actionIcon, color: actionColor),
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}
