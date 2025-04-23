import 'package:flutter/material.dart';
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/models/notification_settings.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications(String userId);
  
  Future<bool> markNotificationAsRead(String notificationId);
  
  Future<bool> markAllNotificationsAsRead(String userId);
  
  Future<bool> deleteNotification(String notificationId);
  
  Future<bool> clearAllNotifications(String userId);
  
  Future<NotificationSettings> getNotificationSettings(String userId);
  
  Future<bool> updateNotificationSettings({
    required bool activityReminders,
    required bool bookingConfirmations,
    required bool promotions,
    required bool newsletter,
    required bool appUpdates,
    bool quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  });
  
  Future<AppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  });
  
  // Nouvelle méthode pour sauvegarder une notification reçue via socket
  Future<void> saveSocketNotification(AppNotification notification);
}
