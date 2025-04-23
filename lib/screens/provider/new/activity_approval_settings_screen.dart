import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_event.dart';
import 'package:flutter_activity_app/bloc/provider/provider_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';

class ActivityApprovalSettingsScreen extends StatefulWidget {
  final String providerId;
  final List<Activity> activities;

  const ActivityApprovalSettingsScreen({
    Key? key,
    required this.providerId,
    required this.activities,
  }) : super(key: key);

  @override
  State<ActivityApprovalSettingsScreen> createState() => _ActivityApprovalSettingsScreenState();
}

class _ActivityApprovalSettingsScreenState extends State<ActivityApprovalSettingsScreen> {
  late ProviderBloc _providerBloc;
  
  @override
  void initState() {
    super.initState();
    _providerBloc = getIt<ProviderBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _providerBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approval Settings'),
          elevation: 0,
        ),
        body: BlocConsumer<ProviderBloc, ProviderState>(
          listener: (context, state) {
            if (state is ActivityUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity settings updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is ProviderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProviderLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            return _buildActivityList();
          },
        ),
      ),
    );
  }
  
  Widget _buildActivityList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        ...widget.activities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              const Text(
                'Reservation Approval Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose whether you want to approve reservations before clients can pay, or allow immediate payment without your approval.',
            style: TextStyle(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Require approval: You review and approve each reservation before payment',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Direct payment: Clients can pay immediately without your approval',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    activity.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${activity.price.toStringAsFixed(2)} · ${activity.duration}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Require approval before payment'),
                  subtitle: Text(
                    activity.requiresApproval
                        ? 'You will need to approve reservations before clients can pay'
                        : 'Clients can pay immediately without your approval',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: activity.requiresApproval,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    final updatedActivity = activity.copyWith(
                      requiresApproval: value,
                    );
                    
                    _providerBloc.add(UpdateActivity(updatedActivity));
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activity.requiresApproval
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        activity.requiresApproval
                            ? Icons.schedule
                            : Icons.flash_on,
                        color: activity.requiresApproval
                            ? Colors.orange
                            : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          activity.requiresApproval
                              ? 'Manual approval process may take longer but gives you more control'
                              : 'Direct payment provides a faster booking experience for clients',
                          style: TextStyle(
                            fontSize: 12,
                            color: activity.requiresApproval
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
