import 'package:flutter/material.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/models/notification.dart';

class NotificationPopup extends StatefulWidget {
  final AppNotification notification;
  final NotificationBloc notificationBloc;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationPopup({
    Key? key,
    required this.notification,
    required this.notificationBloc,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Determine icon and color based on notification type
  IconData _getNotificationIcon() {
    if (widget.notification.isReservationUpdate) {
      return Icons.calendar_today;
    } else if (widget.notification.type == NotificationType.message || 
              (widget.notification.type is String && widget.notification.type == 'message')) {
      return Icons.message;
    } else if (widget.notification.type == NotificationType.payment || 
              (widget.notification.type is String && widget.notification.type == 'payment')) {
      return Icons.payment;
    } else {
      return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    if (widget.notification.isReservationUpdate) {
      return Colors.blue;
    } else if (widget.notification.type == NotificationType.message || 
              (widget.notification.type is String && widget.notification.type == 'message')) {
      return Colors.green;
    } else if (widget.notification.type == NotificationType.payment || 
              (widget.notification.type is String && widget.notification.type == 'payment')) {
      return Colors.purple;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getNotificationColor();
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: () {
                // Mark as read and handle tap
                widget.notificationBloc.add(MarkNotificationAsRead(widget.notification.id));
                _animationController.reverse().then((_) {
                  widget.onTap();
                });
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                  // Swipe right to dismiss
                  _animationController.reverse().then((_) {
                    widget.onDismiss();
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_getNotificationIcon(), color: color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getNotificationTypeText(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            _getTimeAgo(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getNotificationIcon(),
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.notification.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.notification.message,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              _animationController.reverse().then((_) {
                                widget.onDismiss();
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getNotificationTypeText() {
    if (widget.notification.isReservationUpdate) {
      return 'Mise à jour de réservation';
    } else if (widget.notification.type == NotificationType.message || 
              (widget.notification.type is String && widget.notification.type == 'message')) {
      return 'Nouveau message';
    } else if (widget.notification.type == NotificationType.payment || 
              (widget.notification.type is String && widget.notification.type == 'payment')) {
      return 'Information de paiement';
    } else {
      return 'Notification';
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(widget.notification.createdAt);
    
    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}
