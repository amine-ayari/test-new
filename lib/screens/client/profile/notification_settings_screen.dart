import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_event.dart';
import 'package:flutter_activity_app/bloc/user/user_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/notification_settings.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(const LoadNotificationSettings()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          elevation: 0,
        ),
        body: BlocConsumer<UserBloc, UserState>(
          listener: (context, state) {
            if (state is NotificationSettingsUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings updated'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is UserLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is NotificationSettingsLoaded) {
              return _buildSettingsList(context, state.settings);
            }
            
            return const Center(child: Text('Failed to load notification settings'));
          },
        ),
      ),
    );
  }
  
  Widget _buildSettingsList(BuildContext context, NotificationSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildMasterToggle(context, settings),
        const Divider(height: 32),
        if (settings.enabled) ...[
          _buildSettingsGroup(
            title: 'Activity Notifications',
            children: [
              _buildSettingItem(
                context: context,
                title: 'New Activities',
                subtitle: 'Get notified when new activities are added',
                value: settings.newActivities,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(newActivities: value),
                  );
                },
              ),
              _buildSettingItem(
                context: context,
                title: 'Price Drops',
                subtitle: 'Get notified when activity prices drop',
                value: settings.priceDrops,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(priceDrops: value),
                  );
                },
              ),
              _buildSettingItem(
                context: context,
                title: 'Recommendations',
                subtitle: 'Get personalized activity recommendations',
                value: settings.recommendations,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(recommendations: value),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSettingsGroup(
            title: 'Booking Notifications',
            children: [
              _buildSettingItem(
                context: context,
                title: 'Booking Confirmations',
                subtitle: 'Get notified when your booking is confirmed',
                value: settings.bookingConfirmations,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(bookingConfirmations: value),
                  );
                },
              ),
              _buildSettingItem(
                context: context,
                title: 'Booking Reminders',
                subtitle: 'Get reminders before your booked activities',
                value: settings.bookingReminders,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(bookingReminders: value),
                  );
                },
              ),
              _buildSettingItem(
                context: context,
                title: 'Booking Changes',
                subtitle: 'Get notified about changes to your bookings',
                value: settings.bookingChanges,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(bookingChanges: value),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSettingsGroup(
            title: 'Marketing Notifications',
            children: [
              _buildSettingItem(
                context: context,
                title: 'Promotions',
                subtitle: 'Get notified about special offers and promotions',
                value: settings.promotions,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(promotions: value),
                  );
                },
              ),
              _buildSettingItem(
                context: context,
                title: 'Newsletter',
                subtitle: 'Receive our weekly newsletter',
                value: settings.newsletter,
                onChanged: (value) {
                  _updateSettings(
                    context,
                    settings.copyWith(newsletter: value),
                  );
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: AppTheme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Customize which notifications you want to receive. You can turn them all off with the master switch.',
                style: TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMasterToggle(BuildContext context, NotificationSettings settings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: settings.enabled
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.notifications,
                color: settings.enabled ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enable Notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    settings.enabled
                        ? 'You will receive notifications'
                        : 'You will not receive any notifications',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.enabled,
              onChanged: (value) {
                _updateSettings(
                  context,
                  settings.copyWith(enabled: value),
                );
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
  
  void _updateSettings(BuildContext context, NotificationSettings settings) {
    context.read<UserBloc>().add(UpdateNotificationSettings(settings));
  }
}
