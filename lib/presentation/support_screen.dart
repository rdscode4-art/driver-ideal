import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/support_controller.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupportController controller = Get.put(SupportController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Support & Help'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.orange[600],
              child: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  // Tab(text: 'Get Help'),
                  Tab(text: 'My Tickets'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // _buildGetHelpTab(controller, screenWidth, screenHeight),
                  _buildMyTicketsTab(controller, screenWidth, screenHeight),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketDialog(controller),
        backgroundColor: Colors.orange[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Ticket', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildGetHelpTab(SupportController controller, double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Help Categories
          Text(
            'Quick Help',
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),

          _buildHelpCategoriesGrid(screenWidth, screenHeight),

          SizedBox(height: screenHeight * 0.025),

          // FAQ Section
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),

          _buildFAQSection(screenWidth),
        ],
      ),
    );
  }

  Widget _buildHelpCategoriesGrid(double screenWidth, double screenHeight) {
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;
    final childAspectRatio = isTablet ? 1.3 : 1.2; // Increased aspect ratio to prevent overflow

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: screenWidth * 0.025, // Reduced spacing
      mainAxisSpacing: screenWidth * 0.025, // Reduced spacing
      childAspectRatio: childAspectRatio,
      children: [
        _buildHelpCard(
          icon: Icons.account_circle,
          title: 'Account Issues',
          subtitle: 'Profile, verification, login problems',
          color: Colors.orange[600]!,
          onTap: () => _showCategoryHelp('Account Issues'),
          screenWidth: screenWidth,
        ),
        _buildHelpCard(
          icon: Icons.payment,
          title: 'Payment Help',
          subtitle: 'Earnings, withdrawals, payment issues',
          color: Colors.green[600]!,
          onTap: () => _showCategoryHelp('Payment Problems'),
          screenWidth: screenWidth,
        ),
        _buildHelpCard(
          icon: Icons.directions_car,
          title: 'Trip Issues',
          subtitle: 'Ride problems, navigation, cancellations',
          color: Colors.blue[600]!,
          onTap: () => _showCategoryHelp('Trip Issues'),
          screenWidth: screenWidth,
        ),
        _buildHelpCard(
          icon: Icons.bug_report,
          title: 'Technical Support',
          subtitle: 'App bugs, crashes, performance',
          color: Colors.purple[600]!,
          onTap: () => _showCategoryHelp('Technical Support'),
          screenWidth: screenWidth,
        ),
      ],
    );
  }

  void _showNewTicketDialog(SupportController controller, {String? category}) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Create Support Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller.titleController..text = category ?? '',
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                initialValue: controller.selectedPriority.value,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  if (value != null) controller.selectedPriority.value = value;
                },
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.submitSupportTicket(),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              )),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab(SupportController controller, double screenWidth, double screenHeight) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.supportTickets.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No support tickets yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.supportTickets.length,
        itemBuilder: (context, index) {
          final ticket = controller.supportTickets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: controller.getStatusColor(ticket.status).withAlpha(51),
                child: Icon(
                  Icons.support_agent,
                  color: controller.getStatusColor(ticket.status),
                ),
              ),
              title: Text(ticket.ticketTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${ticket.status.toUpperCase()}'),
                  Text('Created: ${_formatDateTime(ticket.createdAt)}'),
                  Text('Priority: ${ticket.priority.toUpperCase()}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      );
    });
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: screenWidth * 0.055),
              ),
              SizedBox(height: screenWidth * 0.02),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: screenWidth * 0.008),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: screenWidth * 0.025,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(double screenWidth) {
    final faqItems = [
      {
        'question': 'How do I update my bank details?',
        'answer': 'Go to Profile > Settings > Payment Settings to update your bank account information.',
      },
      {
        'question': 'Why am I not receiving ride requests?',
        'answer': 'Ensure you are online, have a good internet connection, and your location services are enabled.',
      },
      {
        'question': 'How do I cancel a ride?',
        'answer': 'Contact the passenger first, then use the Cancel Ride button. Valid reasons include emergency or passenger no-show.',
      },
      {
        'question': 'When will I receive my payment?',
        'answer': 'Payments are processed daily and transferred to your account within 1-2 business days.',
      },
    ];

    return Column(
      children: faqItems.map((item) => _buildFAQItem(
        item['question']!,
        item['answer']!,
        screenWidth,
      )).toList(),
    );
  }

  Widget _buildFAQItem(String question, String answer, double screenWidth) {
    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: screenWidth * 0.037,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          iconColor: Colors.orange[600],
          collapsedIconColor: Colors.grey[600],
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.04,
                0,
                screenWidth * 0.04,
                screenWidth * 0.04,
              ),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: screenWidth * 0.033,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, SupportController controller, double screenWidth) {
    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ticket['subject'],
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenWidth * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: controller.getStatusColor(ticket['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket['status'],
                    style: TextStyle(
                      color: controller.getStatusColor(ticket['status']),
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.02),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenWidth * 0.01,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket['category'],
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              ticket['description'],
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: screenWidth * 0.033,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.03),
            Row(
              children: [
                Icon(Icons.calendar_today, size: screenWidth * 0.035, color: Colors.grey[500]),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  ticket['createdAt'],
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: screenWidth * 0.03,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${ticket['id']}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryHelp(String category) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('$category Help'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Common solutions for $category:'),
              const SizedBox(height: 12),
              if (category == 'Account Issues') ...[
                const Text('• Check your internet connection'),
                const Text('• Clear app cache and restart'),
                const Text('• Verify your email address'),
                const Text('• Update the app to latest version'),
              ] else if (category == 'Payment Problems') ...[
                const Text('• Check bank account details'),
                const Text('• Verify tax information'),
                const Text('• Contact bank for payment blocks'),
                const Text('• Check minimum payout threshold'),
              ] else if (category == 'Trip Issues') ...[
                const Text('• Enable GPS location services'),
                const Text('• Keep app running in foreground'),
                const Text('• Communicate with passengers'),
                const Text('• Follow pickup instructions'),
              ] else if (category == 'Technical Support') ...[
                const Text('• Restart the app'),
                const Text('• Update to latest version'),
                const Text('• Clear app cache'),
                const Text('• Restart your device'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showNewTicketDialog(Get.find<SupportController>(), category: category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Still Need Help?'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr).toLocal();
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
