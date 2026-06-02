import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Notifications', style: Theme.of(context).appBarTheme.titleTextStyle),
        backgroundColor: AppTheme.primary,
        elevation: 2,
        iconTheme: const IconThemeData(color: AppTheme.accent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildNotificationCard(context, 'Trip Assigned', 'You have a new trip request.', '2 min ago'),
          _buildNotificationCard(context, 'Document Approved', 'Your driver license has been verified.', '1 hr ago'),
          _buildNotificationCard(context, 'Earnings Update', 'You received ₹500 payout.', 'Yesterday'),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, String title, String subtitle, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: AppTheme.card,
      child: ListTile(
        leading: const Icon(Icons.notifications, color: AppTheme.accent),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
      ),
    );
  }
}
