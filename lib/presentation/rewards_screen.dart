import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../core/utils/app_snackbar.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final String myReferralCode =
      "RD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
  final TextEditingController _referralCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Refer & Earn Header Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.people, color: Colors.orange, size: 50),
                    const SizedBox(height: 10),
                    const Text(
                      'Refer Friends & Earn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Earn ₹500 for each successful referral!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // My Referral Code Section
            const Text(
              'Your Referral Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  myReferralCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: myReferralCode),
                                    );
                                    showSuccessSnackBar(
                                      'Referral code copied to clipboard',
                                      title: 'Copied!',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _shareReferralCode();
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Enter Referral Code Section
            const Text(
              'Enter Referral Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _referralCodeController,
                      decoration: InputDecoration(
                        hintText: 'Enter friend\'s referral code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(
                          Icons.code,
                          color: Colors.orange,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        _applyReferralCode();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Apply Referral Code'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),

            // Referral Stats Section
            // Text('Referral Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // SizedBox(height: 15),
            //
            // // Row(
            //   children: [
            //     Expanded(child: _buildStatCard('Total Referrals', '8', Colors.blue)),
            //     SizedBox(width: 15),
            //     Expanded(child: _buildStatCard('Active Drivers', '5', Colors.green)),
            //     SizedBox(width: 15),
            //     Expanded(child: _buildStatCard('Earnings', '₹2,500', Colors.orange)),
            //   ],
            // ),
            // SizedBox(height: 20),

            // How it Works Section
            // Text('How Referral Works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // SizedBox(height: 15),
            //
            // _buildHowItWorksCard('1', 'Share your referral code', 'Send your unique code to friends who want to become drivers', Icons.share),
            // _buildHowItWorksCard('2', 'Friend signs up', 'Your friend registers using your referral code', Icons.person_add),
            // _buildHowItWorksCard('3', 'Complete requirements', 'Friend completes verification and drives 10 trips', Icons.check_circle),
            // _buildHowItWorksCard('4', 'Both earn rewards', 'You get ₹500, your friend gets ₹300 bonus', Icons.attach_money),
            //
            const SizedBox(height: 20),

            // Recent Referrals
            // Text('Recent Referrals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // SizedBox(height: 15),
            //
            // _buildReferralItem('Amit Kumar', 'Verified • 15 trips completed', '₹500', Colors.green, true),
            // _buildReferralItem('Priya Sharma', 'Pending verification', '₹0', Colors.orange, false),
            // _buildReferralItem('Rahul Singh', 'Active • 8 trips completed', '₹0', Colors.blue, false),
          ],
        ),
      ),
    );
  }

  void _shareReferralCode() {
    final String message =
        '''
🚗 Join RiDeal Driver and start earning!

Use my referral code: $myReferralCode

✅ Flexible working hours
✅ Good earning potential  
✅ ₹300 bonus for new drivers

Download the app and start your journey as a driver today!
''';

    // In a real app, you would use share_plus package
    // Share.share(message);

    showInfoSnackBar(
      'Sharing referral code: $myReferralCode',
      title: 'Share Referral',
    );

    print('Sharing message: $message'); // Use the message variable
  }

  void _applyReferralCode() {
    if (_referralCodeController.text.trim().isEmpty) {
      showErrorSnackBar('Please enter a referral code', title: 'Error');
      return;
    }

    if (_referralCodeController.text.trim() == myReferralCode) {
      showErrorSnackBar(
        'You cannot use your own referral code',
        title: 'Error',
      );
      return;
    }

    // Simulate applying referral code
    showSuccessSnackBar(
      'Referral code applied successfully! You\'ll receive ₹300 bonus after completing 10 trips.',
      title: 'Success!',
    );
    _referralCodeController.clear();
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard(
    String step,
    String title,
    String description,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Icon(icon, color: Colors.orange, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralItem(
    String name,
    String status,
    String amount,
    Color statusColor,
    bool isCompleted,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            name[0],
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
      ),
    );
  }
}
