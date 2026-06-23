import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../routes/app_pages.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  SettingsScreen({super.key});

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
                    colors: [Colors.orange[600]!, Colors.orange[400]!],
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
                          'Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage your preferences',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Settings Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Section
                  // _buildProfileSection(),
                  // SizedBox(height: 16),

                  // Account Settings
                  _buildSettingsSection('Account', Icons.account_circle, [
                    _buildSettingItem(
                      'Personal Information',
                      'Edit your profile details',
                      Icons.person_outline,
                      () => Get.toNamed(Routes.PROFILE),
                    ),
                    _buildSettingItem(
                      'Documents',
                      'Manage your verification documents',
                      Icons.description_outlined,
                      () => Get.toNamed(Routes.KYC_DOCUMENTS),
                    ),
                    // _buildSettingItem(
                    //   'Vehicle Information',
                    //   'Update vehicle details',
                    //   Icons.directions_car_outlined,
                    //   () => Get.toNamed(Routes.VEHICLE_INFO),
                    // ),
                  ]),
                  const SizedBox(height: 16),

                  // App Settings
                  _buildSettingsSection('App Settings', Icons.settings, [
                    _buildSettingItem(
                      'Notifications',
                      'Manage notification preferences',
                      Icons.notifications_outlined,
                      () => Get.toNamed(Routes.NOTIFICATION_SETTINGS),
                    ),
                    // _buildSettingItem(
                    //   'Privacy & Security',
                    //   'Control your privacy settings',
                    //   Icons.security_outlined,
                    //   () => Get.toNamed(Routes.PRIVACY_SETTINGS),
                    // ),
                    // _buildSettingItem(
                    //   'Language',
                    //   'Change app language',
                    //   Icons.language_outlined,
                    //   () => _showLanguageDialog(),
                    // ),
                    _buildSettingItem(
                      'Theme',
                      'Switch between light and dark mode',
                      Icons.palette_outlined,
                      () => _showThemeDialog(),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // About & Legal
                  _buildSettingsSection('About & Legal', Icons.info_outline, [
                    _buildSettingItem(
                      'About RiDeal',
                      'Learn more about our app',
                      Icons.info_outlined,
                      () => Get.toNamed(Routes.ABOUT),
                    ),
                    _buildSettingItem(
                      'Terms of Service',
                      'Read our terms and conditions',
                      Icons.description_outlined,
                      () => Get.toNamed(Routes.TERMS),
                    ),
                    _buildSettingItem(
                      'Privacy Policy',
                      'View our privacy policy',
                      Icons.privacy_tip_outlined,
                      () => Get.toNamed(Routes.PRIVACY_POLICY),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Logout Button
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
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
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.driverName.value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        controller.driverEmail.value,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    String title,
    IconData icon,
    List<Widget> items,
  ) {
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
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.orange[700], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.grey[700], size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio(
                value: 'en',
                groupValue: controller.selectedLanguage.value,
                onChanged: (value) {
                  controller.changeLanguage(value.toString());
                  Get.back();
                },
              ),
            ),
            ListTile(
              title: const Text('हिंदी'),
              leading: Radio(
                value: 'hi',
                groupValue: controller.selectedLanguage.value,
                onChanged: (value) {
                  controller.changeLanguage(value.toString());
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light Mode'),
              leading: Radio(
                value: 'light',
                groupValue: controller.selectedTheme.value,
                onChanged: (value) {
                  controller.changeTheme(value.toString());
                  Get.back();
                },
              ),
            ),
            ListTile(
              title: const Text('Dark Mode'),
              leading: Radio(
                value: 'dark',
                groupValue: controller.selectedTheme.value,
                onChanged: (value) {
                  controller.changeTheme(value.toString());
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.logout();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
