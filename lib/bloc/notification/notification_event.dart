import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_activity_app/models/notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;

  const LoadNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;

  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ClearAllNotifications extends NotificationEvent {
  final String userId;

  const ClearAllNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadNotificationSettings extends NotificationEvent {
  final String userId;

  const LoadNotificationSettings(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateNotificationSettings extends NotificationEvent {
  final bool activityReminders;
  final bool bookingConfirmations;
  final bool promotions;
  final bool newsletter;
  final bool appUpdates;
  final bool quietHoursEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;

  const UpdateNotificationSettings({
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
}

class ConnectToNotificationSocket extends NotificationEvent {
  final String userId;
  final String userType;

  const ConnectToNotificationSocket({
    required this.userId,
    required this.userType,
  });

  @override
  List<Object?> get props => [userId, userType];
}

class DisconnectFromNotificationSocket extends NotificationEvent {
  const DisconnectFromNotificationSocket();
}

class NewNotificationReceived extends NotificationEvent {
  final AppNotification notification;

  const NewNotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationReceived extends NotificationEvent {
  final AppNotification notification;

  const NotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}
