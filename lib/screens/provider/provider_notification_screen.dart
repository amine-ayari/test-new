import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/bloc/notification/notification_state.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/screens/provider/provider_reservations_screen.dart';
import 'package:intl/intl.dart';

class ProviderNotificationScreen extends StatefulWidget {
  final String providerId;

  const ProviderNotificationScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderNotificationScreen> createState() => _ProviderNotificationScreenState();
}

class _ProviderNotificationScreenState extends State<ProviderNotificationScreen> {
  late NotificationBloc _notificationBloc;
  late ReservationBloc _reservationBloc;
  
  @override
  void initState() {
    super.initState();
    _notificationBloc = getIt<NotificationBloc>();
    _reservationBloc = getIt<ReservationBloc>();
    
    // Load notifications for this provider
    _notificationBloc.add(LoadNotifications(widget.providerId));
    
    // Connect to the notification socket for real-time updates
    _notificationBloc.add(ConnectToNotificationSocket(
      userId: widget.providerId,
      userType: 'provider',
    ));
  }
  
  @override
  void dispose() {
    // Disconnect from the socket when leaving the screen
    _notificationBloc.add(const DisconnectFromNotificationSocket());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _notificationBloc),
        BlocProvider.value(value: _reservationBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provider Notifications'),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationsLoaded && state.notifications.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.done_all),
                    onPressed: () {
                      _notificationBloc.add(MarkAllNotificationsAsRead(widget.providerId));
                    },
                    tooltip: 'Mark all as read',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return _buildEmptyState();
              }
              return _buildNotificationsList(state.notifications);
            } else if (state is NotificationError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have any notifications yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    // Filter notifications to show only those relevant to providers
    final providerNotifications = notifications.where((notification) {
      // Include reservation notifications and system notifications
      return notification.type == NotificationType.reservation ||
             notification.type == NotificationType.system;
    }).toList();
    
    if (providerNotifications.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: providerNotifications.length,
      itemBuilder: (context, index) {
        final notification = providerNotifications[index];
        return _buildProviderNotificationItem(notification);
      },
    );
  }

  Widget _buildProviderNotificationItem(AppNotification notification) {
    final theme = Theme.of(context);
    
    // Determine if this is a new reservation notification
    final isNewReservation = notification.type == NotificationType.reservation &&
                            notification.data != null &&
                            notification.data!['status'] == 'pending';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(color: theme.colorScheme.primary, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (!notification.isRead) {
                _notificationBloc.add(MarkNotificationAsRead(notification.id));
              }
              
              // Handle notification tap based on type and data
              _handleProviderNotificationTap(notification);
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: notification.type == NotificationType.reservation
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notification.type == NotificationType.reservation
                          ? Icons.calendar_today
                          : Icons.info,
                      color: notification.type == NotificationType.reservation
                          ? Colors.blue
                          : Colors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatNotificationTime(notification.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Show action buttons for new reservation notifications
          if (isNewReservation && notification.data != null && notification.data!.containsKey('reservationId'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectReservation(notification.data!['reservationId']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmReservation(notification.data!['reservationId']),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleProviderNotificationTap(AppNotification notification) {
    // Handle different notification types for providers
    if (notification.type == NotificationType.reservation && notification.data != null) {
      // Navigate to the reservations screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProviderReservationsScreen(
            providerId: widget.providerId,
          ),
        ),
      );
    }
  }

  void _confirmReservation(String reservationId) {
    _reservationBloc.add(UpdateReservationStatus(
      reservationId,
      ReservationStatus.confirmed,
    ));
    
    // Mark the notification as read
    _notificationBloc.add(MarkNotificationAsRead(reservationId));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reservation confirmed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectReservation(String reservationId) {
    // Show dialog to get rejection reason
    showDialog(
      context: context,
      builder: (context) => _buildRejectionDialog(reservationId),
    );
  }

  Widget _buildRejectionDialog(String reservationId) {
    final TextEditingController reasonController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Reject Reservation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to reject this reservation?'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _reservationBloc.add(UpdateReservationStatus(
              reservationId,
              ReservationStatus.rejected,
              reason: reasonController.text,
            ));
            
            // Mark the notification as read
            _notificationBloc.add(MarkNotificationAsRead(reservationId));
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reservation rejected'),
                backgroundColor: Colors.red,
              ),
            );
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
