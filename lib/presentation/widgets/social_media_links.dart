import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import '../../core/utils/app_snackbar.dart';

class SocialMediaLinks extends StatelessWidget {
  const SocialMediaLinks({super.key});

  // Social media URLs with corrected app deep links
  static const Map<String, Map<String, String>> socialMediaUrls = {
    'youtube': {
      'app': 'https://www.youtube.com/@ridealmobility', // Updated YouTube URL
      'web': 'https://www.youtube.com/@ridealmobility',
    },
    'facebook': {
      'app': 'https://www.facebook.com/profile.php?id=61579358969926', // Updated Facebook URL
      'web': 'https://www.facebook.com/profile.php?id=61579358969926',
    },
    'twitter': {
      'app': 'https://x.com/ridealmobi18276', // Updated Twitter/X URL
      'web': 'https://x.com/ridealmobi18276',
    },
    'instagram': {
      'app': 'https://www.instagram.com/ridealmobility__/', // Updated Instagram URL
      'web': 'https://www.instagram.com/ridealmobility__/',
    },
    'telegram': {
      'app': 'https://t.me/RiDealIndia', // Telegram web link works universally
      'web': 'https://t.me/RiDealIndia',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Follow us text
          Text(
            'Follow us on social media',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          // Social media icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(
                icon: FontAwesomeIcons.youtube,
                color: const Color(0xFFFF0000), // YouTube red
                platform: 'youtube',
                label: 'YouTube',
              ),
              const SizedBox(width: 20),
              _buildSocialIcon(
                icon: FontAwesomeIcons.facebook,
                color: const Color(0xFF1877F2), // Facebook blue
                platform: 'facebook',
                label: 'Facebook',
              ),
              const SizedBox(width: 20),
              _buildSocialIcon(
                icon: FontAwesomeIcons.xTwitter,
                color: const Color(0xFF1DA1F2), // Twitter blue
                platform: 'twitter',
                label: 'Twitter',
              ),
              const SizedBox(width: 20),
              _buildSocialIcon(
                icon: FontAwesomeIcons.instagram,
                color: const Color(0xFFE4405F), // Instagram pink
                platform: 'instagram',
                label: 'Instagram',
              ),
              const SizedBox(width: 20),
              _buildSocialIcon(
                icon: FontAwesomeIcons.telegram,
                color: const Color(0xFF0088CC), // Telegram blue
                platform: 'telegram',
                label: 'Telegram',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required String platform,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => _launchSocialMedia(platform, label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 150),
          tween: Tween(begin: 1.0, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: FaIcon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchSocialMedia(String platform, String label) async {
    try {
      final urls = socialMediaUrls[platform];
      if (urls == null) {
        _showError('Invalid platform', label);
        return;
      }

      final url = urls['app']!; // Use the main URL for launching

      final Uri uri = Uri.parse(url);

      // Try to launch the URL with external application mode
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        // Show success feedback
        showSuccessSnackBar(
          'Redirecting to $label...',
          title: 'Opening $label',
        );
      } else {
        _showError('Could not open $label', label);
      }
    } catch (e) {
      _showError('Failed to open $label: $e', label);
    }
  }

  void _showError(String message, String label) {
    showErrorSnackBar(message);
  }
}

// Enhanced version with tap animation and better app redirect handling
class SocialMediaLinksEnhanced extends StatelessWidget {
  const SocialMediaLinksEnhanced({super.key});

  // Enhanced social media URLs with proper web URLs for universal compatibility
  static const Map<String, Map<String, dynamic>> enhancedSocialMediaUrls = {
    'youtube': {
      'url': 'https://www.youtube.com/@ridealmobility',
      'icon': FontAwesomeIcons.youtube,
      'color': Color(0xFFFF0000),
    },
    'facebook': {
      'url': 'https://www.facebook.com/profile.php?id=61579358969926',
      'icon': FontAwesomeIcons.facebook,
      'color': Color(0xFF1877F2),
    },
    'twitter': {
      'url': 'https://x.com/ridealmobi18276',
      'icon': FontAwesomeIcons.xTwitter,
      'color': Color(0xFF1DA1F2),
    },
    'instagram': {
      'url': 'https://www.instagram.com/ridealmobility__/',
      'icon': FontAwesomeIcons.instagram,
      'color': Color(0xFFE4405F),
    },
    'telegram': {
      'url': 'https://t.me/RiDealIndia',
      'icon': FontAwesomeIcons.telegram,
      'color': Color(0xFF0088CC),
    },
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.share,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Follow RiDeal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Stay connected with us on social media',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Social media icons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: enhancedSocialMediaUrls.entries.map((entry) {
                  final platform = entry.key;
                  final data = entry.value;
                  return AnimatedSocialIcon(
                    icon: data['icon'] as IconData,
                    color: data['color'] as Color,
                    platform: platform,
                    label: platform.capitalize!,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Footer text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Get latest updates, offers, and driver tips!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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

  static Future<void> launchSocialMedia(String platform, String label) async {
    try {
      final data = enhancedSocialMediaUrls[platform];
      if (data == null) {
        _showError('Invalid platform', label);
        return;
      }

      final url = data['url'] as String;
      final Uri uri = Uri.parse(url);

      // Try to launch the URL
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        showSuccessSnackBar(
          'Redirecting to ${label.toLowerCase()}...',
          title: 'Opening $label',
        );
      } else {
        _showError('Could not open $label', label);
      }
    } catch (e) {
      _showError('Failed to open $label: $e', label);
    }
  }

  static void _showError(String message, String label) {
    showErrorSnackBar(message);
  }
}

// Enhanced version with tap animation
class AnimatedSocialIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String platform;
  final String label;

  const AnimatedSocialIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.platform,
    required this.label,
  });

  @override
  State<AnimatedSocialIcon> createState() => _AnimatedSocialIconState();
}

class _AnimatedSocialIconState extends State<AnimatedSocialIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () => SocialMediaLinksEnhanced.launchSocialMedia(widget.platform, widget.label),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.1),
                    widget.color.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(
                  widget.icon,
                  color: widget.color,
                  size: 22,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
