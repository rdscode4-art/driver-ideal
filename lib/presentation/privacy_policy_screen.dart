import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  final List<Map<String, String>> _policyItems = const [
    {
      'title': '1. Information Collection',
      'content':
          'We collect only the information that is necessary to provide mobility and utility services.\n\nPersonal Information:\n• Name\n• Phone number\n• Email address\n\nLocation Data:\n• Precise location data only during an active ride or active service duty, used for navigation, pickup, drop, fare calculation, and safety\n\nTrip Information:\n• Pickup and drop locations\n• Trip history and fare details\n\nDriver Information (Driver App Only):\n• Driving License\n• Vehicle Registration Certificate (RC)\n• Vehicle details\n• Profile photograph\n\nGovernment-issued identity details are collected only for driver verification, safety, and legal compliance. Such data is not used for advertising, profiling, or marketing purposes.\n\nDevice Information:\n• App version\n• Device type\n• Operating system\n\nThis information is used solely for app performance, security, and diagnostics.',
    },
    {
      'title': '2. Use of Information',
      'content':
          'Collected information is used strictly for the following purposes:\n\n• Ride booking, assignment, and trip completion\n• Navigation, fare calculation, and service delivery\n• Driver and user verification for safety and fraud prevention\n• Customer support and dispute resolution\n• Compliance with legal and regulatory requirements\n• Improving app functionality and user experience',
    },
    {
      'title': '3. Location Data Usage',
      'content':
          'RiDeal collects location data only when required, such as:\n\n• During an active ride\n• During active duty status (Driver App)\n\nLocation data:\n• Is not collected when the app is idle or when the driver is offline\n• Is not used for advertising or marketing purposes',
    },
    {
      'title': '4. Data Sharing',
      'content':
          'RiDeal does not sell or rent personal data.\n\nInformation may be shared only with:\n• Trusted third-party service providers (payment gateways, maps, SMS services, analytics) solely to enable app functionality\n• Government or legal authorities when required by law or for safety and legal investigations\n\nAll third-party partners are contractually obligated to maintain strict data protection standards.',
    },
    {
      'title': '5. Data Security',
      'content':
          'We implement appropriate technical and organizational security measures to protect personal data from unauthorized access, alteration, disclosure, or misuse. Users are responsible for maintaining the confidentiality of their login credentials.',
    },
    {
      'title': '6. Data Retention & Deletion',
      'content':
          'Personal data is retained only for as long as necessary for operational, safety, and legal purposes.\n\nUsers may request:\n• Account deletion\n• Data correction or erasure\n\nRequests can be made by:\n• Using the Delete Account option available within the app, or\n• Emailing info@ridealmobility.com\n\nDeletion requests are generally processed within 7–10 working days, subject to applicable legal requirements.',
    },
    {
      'title': '7. Children\'s Privacy',
      'content':
          'RiDeal services are intended only for individuals 18 years of age or older. We do not knowingly collect personal data from minors.',
    },
    {
      'title': '8. User Consent',
      'content':
          'By using RiDeal, you provide explicit consent to the collection, processing, and use of your data in accordance with this Privacy Policy.',
    },
    {
      'title': '9. Updates to This Policy',
      'content':
          'RiDeal may update this Privacy Policy from time to time. Any significant changes will be communicated through the app or other appropriate channels.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with logo and intro
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green[50]!, Colors.white],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Logo with shadow
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Company name
                    Text(
                      'RiDeal Mobility Drive Pvt. Ltd.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Effective date
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Effective Date: 23 December 2025',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Welcome text
                    Text(
                      'Your Privacy Matters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'At RiDeal Mobility Drive Pvt. Ltd. ("RiDeal", "we", "our", "us"), we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, store, share, and protect data when you use the RiDeal Customer App, RiDeal Driver App, or any related services.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'By using RiDeal, you agree to the practices described in this Privacy Policy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Policy sections
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: _policyItems
                    .map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.green[400],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['title']!,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item['content']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Contact Information Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '10. Contact Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'If you have any questions or concerns regarding this Privacy Policy, please contact us:',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    Icons.business,
                    'Company Name',
                    'RiDeal Mobility Drive Pvt. Ltd.',
                  ),
                  const SizedBox(height: 10),
                  _buildContactItem(
                    Icons.location_city,
                    'Company Address',
                    'Ward No. 24, Kalikapur, Palabani Chhak\nMayurbhanj, Baripada, Odisha – 757001\nIndia',
                  ),
                  const SizedBox(height: 10),
                  _buildContactItem(
                    Icons.email,
                    'Email',
                    'info@ridealmobility.com',
                  ),
                  const SizedBox(height: 10),
                  _buildContactItem(
                    Icons.phone,
                    'Contact Number',
                    '+91-9040545756',
                  ),
                  const SizedBox(height: 10),
                  _buildContactItem(Icons.public, 'Country', 'India'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'For account deletion or data correction, use the "Delete Account" option in Settings or email us.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer with compliance badges
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Data is Protected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We use industry-standard security measures to keep your information safe and secure. Your data is never sold or shared without your consent.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildComplianceBadge('✓ Driver Verified'),
                      _buildComplianceBadge('✓ Secure Data'),
                      _buildComplianceBadge('✓ No Data Selling'),
                      _buildComplianceBadge('✓ Legal Compliant'),
                      _buildComplianceBadge('✓ 24/7 Support'),
                      _buildComplianceBadge('✓ India Based'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.green[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
