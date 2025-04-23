import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/auth/auth_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/providers/theme_provider.dart';
import 'package:flutter_activity_app/screens/auth/login_screen.dart';
import 'package:flutter_activity_app/screens/verification/provider_verification_screen.dart';
import 'package:provider/provider.dart';

class ProviderProfileScreen extends StatefulWidget {
  final User user;

  const ProviderProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late AuthBloc _authBloc;
  
  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildVerificationStatus(),
                const SizedBox(height: 24),
                _buildBusinessInfo(),
                const SizedBox(height: 24),
                _buildContactInfo(),
                const SizedBox(height: 24),
                _buildSettings(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: widget.user.profileImage != null
                ? NetworkImage(widget.user.profileImage!)
                : null,
            child: widget.user.profileImage == null
                ? Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.user.verificationStatus == VerificationStatus.approved
                    ? Icons.verified
                    : Icons.pending,
                color: widget.user.verificationStatus == VerificationStatus.approved
                    ? Colors.blue
                    : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                widget.user.verificationStatus == VerificationStatus.approved
                    ? 'Verified Provider'
                    : widget.user.verificationStatus == VerificationStatus.pending
                        ? 'Verification Pending'
                        : widget.user.verificationStatus == VerificationStatus.rejected
                            ? 'Verification Rejected'
                            : 'Not Verified',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.user.verificationStatus == VerificationStatus.approved
                      ? Icons.verified
                      : Icons.shield,
                  color: widget.user.verificationStatus == VerificationStatus.approved
                      ? Colors.green
                      : widget.user.verificationStatus == VerificationStatus.pending
                          ? Colors.orange
                          : widget.user.verificationStatus == VerificationStatus.rejected
                              ? Colors.red
                              : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Verification Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.user.verificationStatus == VerificationStatus.approved
                    ? Colors.green.withOpacity(0.1)
                    : widget.user.verificationStatus == VerificationStatus.pending
                        ? Colors.orange.withOpacity(0.1)
                        : widget.user.verificationStatus == VerificationStatus.rejected
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.user.verificationStatus == VerificationStatus.approved
                      ? Colors.green.withOpacity(0.3)
                      : widget.user.verificationStatus == VerificationStatus.pending
                          ? Colors.orange.withOpacity(0.3)
                          : widget.user.verificationStatus == VerificationStatus.rejected
                              ? Colors.red.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.verificationStatus == VerificationStatus.approved
                        ? 'Your account is verified'
                        : widget.user.verificationStatus == VerificationStatus.pending
                            ? 'Your verification is pending review'
                            : widget.user.verificationStatus == VerificationStatus.rejected
                                ? 'Your verification was rejected'
                                : 'Your account is not verified',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.user.verificationStatus == VerificationStatus.approved
                          ? Colors.green
                          : widget.user.verificationStatus == VerificationStatus.pending
                              ? Colors.orange
                              : widget.user.verificationStatus == VerificationStatus.rejected
                                  ? Colors.red
                                  : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.verificationStatus == VerificationStatus.approved
                        ? 'You can now create and manage activities.'
                        : widget.user.verificationStatus == VerificationStatus.pending
                            ? 'We are reviewing your documents. This usually takes 1-2 business days.'
                            : widget.user.verificationStatus == VerificationStatus.rejected
                                ? 'Please update your information and try again.'
                                : 'Please complete the verification process to create activities.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderVerificationScreen(user: widget.user),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.user.verificationStatus == VerificationStatus.approved
                      ? 'View Verification Details'
                      : widget.user.verificationStatus == VerificationStatus.pending
                          ? 'Check Verification Status'
                          : widget.user.verificationStatus == VerificationStatus.rejected
                              ? 'Update Verification Information'
                              : 'Complete Verification',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.business,
              title: 'Business Name',
              value:  widget.user.name,
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.description,
              title: 'Description',
              value: widget.user.bio ?? 'No description provided',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Address',
              value: widget.user.address ?? 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.email,
              title: 'Email',
              value: widget.user.email,
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.phone,
              title: 'Phone',
              value: widget.user.phoneNumber ?? 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    if (value) {
                      themeProvider.setDarkTheme();
                    } else {
                      themeProvider.setLightTheme();
                    }
                  },
                  secondary: const Icon(Icons.dark_mode),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to change password screen
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to notifications settings screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authBloc.add(const LogoutRequested());
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
