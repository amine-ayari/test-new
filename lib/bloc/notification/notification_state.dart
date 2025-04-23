import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_activity_app/models/notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationSettingsLoaded extends NotificationState {
  final bool activityReminders;
  final bool bookingConfirmations;
  final bool promotions;
  final bool newsletter;
  final bool appUpdates;
  final bool quietHoursEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;

  const NotificationSettingsLoaded({
    required this.activityReminders,
    required this.bookingConfirmations,
    required this.promotions,
    required this.newsletter,
    required this.appUpdates,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  @override
  List<Object?> get props => [
    activityReminders,
    bookingConfirmations,
    promotions,
    newsletter,
    appUpdates,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
  ];

  NotificationSettingsLoaded copyWith({
    bool? activityReminders,
    bool? bookingConfirmations,
    bool? promotions,
    bool? newsletter,
    bool? appUpdates,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  }) {
    return NotificationSettingsLoaded(
      activityReminders: activityReminders ?? this.activityReminders,
      bookingConfirmations: bookingConfirmations ?? this.bookingConfirmations,
      promotions: promotions ?? this.promotions,
      newsletter: newsletter ?? this.newsletter,
      appUpdates: appUpdates ?? this.appUpdates,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

class NotificationSocketConnected extends NotificationState {}

class NotificationSocketDisconnected extends NotificationState {}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object> get props => [message];
}

// État pour les notifications reçues
class NotificationReceivedState extends NotificationState {
  final AppNotification notification;

  const NotificationReceivedState(this.notification);

  @override
  List<Object?> get props => [notification];
}
