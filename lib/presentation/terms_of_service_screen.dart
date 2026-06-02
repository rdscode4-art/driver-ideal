import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  final String termsContent = '''
1. Acceptance of Terms
By downloading, accessing, or using the Rideal application, you agree to be bound by these Terms and Conditions. If you do not agree, you must refrain from using the App.

2. Compliance with Law
Users agree to strictly adhere to all applicable traffic laws, motor vehicle regulations, and public safety rules in India while using Rideal.

3. Prohibited Conduct
The following actions are strictly prohibited and will result in immediate suspension or termination of User access to the App without notice:
* Operating a vehicle under the influence of alcohol, drugs, or any other intoxicating substance.
* Engaging in reckless, dangerous, or unlawful driving practices.
* Misuse of the App for purposes contrary to law or public safety.

4. Suspension and Termination
If a User is found guilty of, or reasonably suspected of, involvement in drunk driving cases or any activity jeopardizing road safety, Rideal reserves the right to suspend or permanently terminate the User's account immediately.

5. Commitment to Public Safety
Rideal is committed to supporting national efforts to prevent road accidents and unlawful activities on Indian roads. By using the App, Users acknowledge their duty as responsible citizens and agree to cooperate in making Bharat's roads safer for all.

6. Limitation of Liability
Rideal shall not be held liable for any accidents, legal violations, or consequences arising out of the User's negligence, unlawful conduct, or violation of these Terms.

7. Amendments
Rideal reserves the right to modify or update these Terms at any time. Continued use of the App after such modifications constitutes acceptance of the revised Terms.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 160,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[700]!, Colors.orange[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Last Updated: September 2025',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Terms Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction Card
                  _buildIntroductionCard(),
                  const SizedBox(height: 20),

                  // Terms Content Card
                  _buildTermsContentCard(),

                  const SizedBox(height: 20),

                  // Safety Commitment Card
                  _buildSafetyCommitmentCard(),

                  const SizedBox(height: 20),

                  // Contact Card
                  _buildContactCard(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.orange[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.gavel,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'These Terms and Conditions govern your use of the Rideal driver application. Please read them carefully as they contain important information about your rights and responsibilities.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description, color: Colors.grey[700], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                termsContent,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCommitmentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.red[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.red[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Safety Commitment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Zero Tolerance Policy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rideal maintains a strict zero-tolerance policy for drunk driving and reckless behavior. Any violation will result in immediate account termination.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🇮🇳 Supporting Bharat\'s Road Safety',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Together, we are committed to making India\'s roads safer for everyone. Your responsibility as a driver extends beyond just transportation.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
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

  Widget _buildContactCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // child: Padding(
        //   padding: EdgeInsets.all(20),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Row(
        //         children: [
        //           Container(
        //             padding: EdgeInsets.all(12),
        //             decoration: BoxDecoration(
        //               color: Colors.blue[100],
        //               borderRadius: BorderRadius.circular(12),
        //             ),
        //             child: Icon(
        //               Icons.help_outline,
        //               color: Colors.blue[700],
        //               size: 24,
        //             ),
        //           ),
        //           SizedBox(width: 16),
        //           Expanded(
        //             child: Text(
        //               'Need Help?',
        //               style: TextStyle(
        //                 fontSize: 18,
        //                 fontWeight: FontWeight.bold,
        //                 color: Colors.grey[800],
        //               ),
        //             ),
        //           ),
        //         ],
        //       ),
        //       SizedBox(height: 16),
        //       Text(
        //         'If you have any questions about these terms or need clarification, please contact our support team:',
        //         style: TextStyle(
        //           fontSize: 15,
        //           color: Colors.grey[700],
        //           height: 1.5,
        //         ),
        //       ),
        //       SizedBox(height: 16),
        //       Container(
        //         padding: EdgeInsets.all(16),
        //         decoration: BoxDecoration(
        //           color: Colors.white,
        //           borderRadius: BorderRadius.circular(12),
        //           border: Border.all(color: Colors.blue[200]!),
        //         ),
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             _buildContactInfo(Icons.email, 'Email', 'legal@rideal.app'),
        //             SizedBox(height: 12),
        //             _buildContactInfo(Icons.phone, 'Phone', '+91-XXXX-XXXXXX'),
        //             SizedBox(height: 12),
        //             _buildContactInfo(Icons.location_on, 'Address', 'RiDeal Technologies, India'),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
