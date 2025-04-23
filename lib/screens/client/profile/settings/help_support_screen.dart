import 'package:flutter/material.dart';
import 'package:flutter_activity_app/config/app_theme.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactSection(context, isDarkMode),
            const SizedBox(height: 24),
            _buildFaqSection(context, isDarkMode),
            const SizedBox(height: 24),
            _buildHelpCenterSection(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Us',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[850]!,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
            ),
            child: Column(
              children: [
                _buildContactItem(
                  context,
                  icon: Icons.email,
                  title: 'Email',
                  value: 'help@support.com',
                  onTap: () => _launchEmail('help@support.com'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildContactItem(
                  context,
                  icon: Icons.phone,
                  title: 'Phone',
                  value: '+1 (555) 123-4567',
                  onTap: () => _launchPhone('+15551234567'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildContactItem(
                  context,
                  icon: Icons.chat,
                  title: 'Live Chat',
                  value: 'Available 24/7',
                  onTap: () {
                    // Open live chat
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
      ),
      title: Text(title),
      subtitle: Text(value),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.primaryColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFaqSection(BuildContext context, bool isDarkMode) {
    final faqs = [
      {
        'question': 'How do I book an activity?',
        'answer': 'You can book an activity by browsing the available options, selecting your preferred date and time, and confirming your booking with payment.'
      },
      {
        'question': 'Can I cancel my booking?',
        'answer': 'Yes, you can cancel your booking up to 24 hours before the scheduled time. Please note that cancellation policies may vary depending on the activity provider.'
      },
      {
        'question': 'How do I reset my password?',
        'answer': 'You can reset your password by clicking on the "Forgot Password" link on the login screen and following the instructions sent to your email.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[850]!,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
            ),
            child: ExpansionPanelList(
              elevation: 0,
              expandedHeaderPadding: EdgeInsets.zero,
              dividerColor: Colors.grey.withOpacity(0.3),
              expansionCallback: (index, isExpanded) {
                // This would be handled in a stateful widget
              },
              children: faqs.map((faq) {
                return ExpansionPanel(
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text(
                        faq['question']!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(faq['answer']!),
                  ),
                  isExpanded: false, // This would be a state variable
                  canTapOnHeader: true,
                );
              }).toList(),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {
              // Navigate to full FAQ page
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('View All FAQs'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpCenterSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help Center',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[850]!,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text('User Guides'),
                  subtitle: const Text('Step-by-step guides to use the app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to user guides
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.video_library,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text('Video Tutorials'),
                  subtitle: const Text('Watch how to use app features'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to video tutorials
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.feedback,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text('Send Feedback'),
                  subtitle: const Text('Help us improve the app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to feedback form
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Support Request',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Handle error
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // Handle error
    }
  }
}
