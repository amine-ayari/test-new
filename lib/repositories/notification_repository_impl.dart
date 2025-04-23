import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/models/notification_settings.dart';
import 'package:flutter_activity_app/repositories/notification_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SharedPreferences _sharedPreferences;
  final ApiService _apiService;
  
  // Keys for SharedPreferences
  static const String _notificationsKey = 'user_notifications_';
  static const String _notificationSettingsKey = 'notification_settings_';
  static const String _currentUserIdKey = 'current_user_id';

  NotificationRepositoryImpl(this._sharedPreferences, this._apiService);

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      // Try to fetch from API first
      try {
        final response = await _apiService.get('/notifications/user/$userId');
        if (response != null && response['success'] == true) {
          final List<dynamic> notificationsList = response['data'];
          final notifications = notificationsList
              .map((json) => AppNotification.fromJson(json))
              .toList();
          
          // Update local cache
          await _saveNotificationsLocally(userId, notifications);
          
          return notifications;
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Get from local storage
      return _getLocalNotifications(userId);
    } catch (e) {
      print('Failed to get notifications: $e');
      return []; // Return empty list instead of throwing to prevent UI crashes
    }
  }

  // Helper method to get notifications from local storage
  List<AppNotification> _getLocalNotifications(String userId) {
    final notificationsJson = _sharedPreferences.getString('$_notificationsKey$userId');
    
    if (notificationsJson != null) {
      try {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        return notificationsList
            .map((json) => AppNotification.fromJson(json))
            .toList();
      } catch (e) {
        print('Error parsing local notifications: $e');
      }
    }
    
    return []; // Return empty list if none found or error occurs
  }

  // Helper method to save notifications to local storage
  Future<void> _saveNotificationsLocally(String userId, List<AppNotification> notifications) async {
    try {
      await _sharedPreferences.setString(
        '$_notificationsKey$userId',
        jsonEncode(notifications.map((n) => n.toJson()).toList()),
      );
    } catch (e) {
      print('Error saving notifications locally: $e');
    }
  }

  @override
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      // Try to update via API first
      try {
        final response = await _apiService.put('/notifications/$notificationId/read', {});
        if (response != null && response['success'] == true) {
          // Update was successful, now update local storage
          await _updateLocalNotification(notificationId, (notification) => notification.markAsRead());
          return true;
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Update in local storage only
      return await _updateLocalNotification(notificationId, (notification) => notification.markAsRead());
    } catch (e) {
      print('Failed to mark notification as read: $e');
      return false;
    }
  }

  // Helper method to update a notification in local storage
  Future<bool> _updateLocalNotification(
    String notificationId, 
    AppNotification Function(AppNotification) updateFn
  ) async {
    final allKeys = _sharedPreferences.getKeys();
    String? targetKey;
    
    // Find which user this notification belongs to
    for (final key in allKeys) {
      if (key.startsWith(_notificationsKey)) {
        final notifications = _getLocalNotificationsFromKey(key);
        if (notifications.any((n) => n.id == notificationId)) {
          targetKey = key;
          break;
        }
      }
    }
    
    if (targetKey != null) {
      final notifications = _getLocalNotificationsFromKey(targetKey);
      bool updated = false;
      
      final updatedNotifications = notifications.map((notification) {
        if (notification.id == notificationId) {
          updated = true;
          return updateFn(notification);
        }
        return notification;
      }).toList();
      
      if (updated) {
        await _sharedPreferences.setString(
          targetKey,
          jsonEncode(updatedNotifications.map((n) => n.toJson()).toList()),
        );
        return true;
      }
    }
    
    return false;
  }

  // Helper method to get notifications from a specific key
  List<AppNotification> _getLocalNotificationsFromKey(String key) {
    final notificationsJson = _sharedPreferences.getString(key);
    if (notificationsJson != null) {
      try {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        return notificationsList
            .map((json) => AppNotification.fromJson(json))
            .toList();
      } catch (e) {
        print('Error parsing notifications from key $key: $e');
      }
    }
    return [];
  }

  @override
  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      // Try to update via API first
      try {
        final response = await _apiService.put('/notifications/user/$userId/read-all', {});
        if (response != null && response['success'] == true) {
          // Update was successful, now update local storage
          final notifications = _getLocalNotifications(userId);
          final updatedNotifications = notifications.map((n) => n.markAsRead()).toList();
          await _saveNotificationsLocally(userId, updatedNotifications);
          return true;
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Update in local storage only
      final notifications = _getLocalNotifications(userId);
      final updatedNotifications = notifications.map((n) => n.markAsRead()).toList();
      await _saveNotificationsLocally(userId, updatedNotifications);
      return true;
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteNotification(String notificationId) async {
    try {
      // Try to delete via API first
      try {
        final response = await _apiService.delete('/notifications/$notificationId');
        if (response != null && response['success'] == true) {
          // Delete was successful, now update local storage
          await _removeLocalNotification(notificationId);
          return true;
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Delete from local storage only
      return await _removeLocalNotification(notificationId);
    } catch (e) {
      print('Failed to delete notification: $e');
      return false;
    }
  }

  // Helper method to remove a notification from local storage
  Future<bool> _removeLocalNotification(String notificationId) async {
    final allKeys = _sharedPreferences.getKeys();
    String? targetKey;
    
    // Find which user this notification belongs to
    for (final key in allKeys) {
      if (key.startsWith(_notificationsKey)) {
        final notifications = _getLocalNotificationsFromKey(key);
        if (notifications.any((n) => n.id == notificationId)) {
          targetKey = key;
          break;
        }
      }
    }
    
    if (targetKey != null) {
      final notifications = _getLocalNotificationsFromKey(targetKey);
      final updatedNotifications = notifications.where((n) => n.id != notificationId).toList();
      
      await _sharedPreferences.setString(
        targetKey,
        jsonEncode(updatedNotifications.map((n) => n.toJson()).toList()),
      );
      return true;
    }
    
    return false;
  }

  @override
  Future<bool> clearAllNotifications(String userId) async {
    try {
      // Try to clear via API first
      try {
        final response = await _apiService.delete('/notifications/user/$userId');
        if (response != null && response['success'] == true) {
          // Clear was successful, now clear local storage
          await _sharedPreferences.setString('$_notificationsKey$userId', jsonEncode([]));
          return true;
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Clear from local storage only
      await _sharedPreferences.setString('$_notificationsKey$userId', jsonEncode([]));
      return true;
    } catch (e) {
      print('Failed to clear all notifications: $e');
      return false;
    }
  }

  @override
  Future<NotificationSettings> getNotificationSettings(String userId) async {
    try {
      // Try to fetch from API first
      try {
        final response = await _apiService.get('/notifications/settings/user/$userId');
        if (response != null && response['success'] == true) {
          final Map<String, dynamic> settingsMap = response['data'];
          
          // Convert TimeOfDay from API format
          TimeOfDay? quietHoursStart;
          TimeOfDay? quietHoursEnd;
          
          if (settingsMap['quietHoursStart'] != null) {
            final parts = settingsMap['quietHoursStart'].split(':');
            quietHoursStart = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          
          if (settingsMap['quietHoursEnd'] != null) {
            final parts = settingsMap['quietHoursEnd'].split(':');
            quietHoursEnd = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          
          final settings = NotificationSettings(
            activityReminders: settingsMap['activityReminders'] ?? true,
            bookingConfirmations: settingsMap['bookingConfirmations'] ?? true,
            promotions: settingsMap['promotions'] ?? false,
            newsletter: settingsMap['newsletter'] ?? false,
            appUpdates: settingsMap['appUpdates'] ?? true,
            quietHoursEnabled: settingsMap['quietHoursEnabled'] ?? false,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
          );
          
          // Update local cache
          await _saveSettingsLocally(userId, settings);
          
          return settings;
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Get from local storage
      return _getLocalSettings(userId);
    } catch (e) {
      print('Failed to get notification settings: $e');
      // Return default settings if error occurs
      return const NotificationSettings(
        activityReminders: true,
        bookingConfirmations: true,
        promotions: false,
        newsletter: false,
        appUpdates: true,
        quietHoursEnabled: false,
      );
    }
  }

  // Helper method to get settings from local storage
  NotificationSettings _getLocalSettings(String userId) {
    final settingsJson = _sharedPreferences.getString('$_notificationSettingsKey$userId');
    
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        
        // Convert TimeOfDay from stored format
        TimeOfDay? quietHoursStart;
        TimeOfDay? quietHoursEnd;
        
        if (settingsMap['quietHoursStart'] != null) {
          final parts = settingsMap['quietHoursStart'].split(':');
          quietHoursStart = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
        
        if (settingsMap['quietHoursEnd'] != null) {
          final parts = settingsMap['quietHoursEnd'].split(':');
          quietHoursEnd = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
        
        return NotificationSettings(
          activityReminders: settingsMap['activityReminders'] ?? true,
          bookingConfirmations: settingsMap['bookingConfirmations'] ?? true,
          promotions: settingsMap['promotions'] ?? false,
          newsletter: settingsMap['newsletter'] ?? false,
          appUpdates: settingsMap['appUpdates'] ?? true,
          quietHoursEnabled: settingsMap['quietHoursEnabled'] ?? false,
          quietHoursStart: quietHoursStart,
          quietHoursEnd: quietHoursEnd,
        );
      } catch (e) {
        print('Error parsing local settings: $e');
      }
    }
    
    // Return default settings if none found or error occurs
    return const NotificationSettings(
      activityReminders: true,
      bookingConfirmations: true,
      promotions: false,
      newsletter: false,
      appUpdates: true,
      quietHoursEnabled: false,
    );
  }

  // Helper method to save settings to local storage
  Future<void> _saveSettingsLocally(String userId, NotificationSettings settings) async {
    try {
      final Map<String, dynamic> settingsMap = {
        'activityReminders': settings.activityReminders,
        'bookingConfirmations': settings.bookingConfirmations,
        'promotions': settings.promotions,
        'newsletter': settings.newsletter,
        'appUpdates': settings.appUpdates,
        'quietHoursEnabled': settings.quietHoursEnabled,
      };
      
      // Convert TimeOfDay to storable format
      if (settings.quietHoursStart != null) {
        settingsMap['quietHoursStart'] = '${settings.quietHoursStart!.hour}:${settings.quietHoursStart!.minute}';
      }
      
      if (settings.quietHoursEnd != null) {
        settingsMap['quietHoursEnd'] = '${settings.quietHoursEnd!.hour}:${settings.quietHoursEnd!.minute}';
      }
      
      await _sharedPreferences.setString(
        '$_notificationSettingsKey$userId',
        jsonEncode(settingsMap),
      );
    } catch (e) {
      print('Error saving settings locally: $e');
    }
  }

  @override
  Future<bool> updateNotificationSettings({
    required bool activityReminders,
    required bool bookingConfirmations,
    required bool promotions,
    required bool newsletter,
    required bool appUpdates,
    bool quietHoursEnabled = false,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  }) async {
    try {
      // We need to get the userId from the current user
      final userId = await _getCurrentUserId();
      
      final settings = NotificationSettings(
        activityReminders: activityReminders,
        bookingConfirmations: bookingConfirmations,
        promotions: promotions,
        newsletter: newsletter,
        appUpdates: appUpdates,
        quietHoursEnabled: quietHoursEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
      );
      
      // Try to update via API first
      try {
        final Map<String, dynamic> requestBody = {
          'activityReminders': activityReminders,
          'bookingConfirmations': bookingConfirmations,
          'promotions': promotions,
          'newsletter': newsletter,
          'appUpdates': appUpdates,
          'quietHoursEnabled': quietHoursEnabled,
        };
        
        // Convert TimeOfDay to API format
        if (quietHoursStart != null) {
          requestBody['quietHoursStart'] = '${quietHoursStart.hour}:${quietHoursStart.minute}';
        }
        
        if (quietHoursEnd != null) {
          requestBody['quietHoursEnd'] = '${quietHoursEnd.hour}:${quietHoursEnd.minute}';
        }
        
        final response = await _apiService.put('/notifications/settings', requestBody);
        if (response != null && response['success'] == true) {
          // Update was successful, now update local storage
          await _saveSettingsLocally(userId, settings);
          return true;
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Update in local storage only
      await _saveSettingsLocally(userId, settings);
      return true;
    } catch (e) {
      print('Failed to update notification settings: $e');
      return false;
    }
  }

  // Helper method to get current user ID
  Future<String> _getCurrentUserId() async {
    // In a real app, you would get this from your auth service or user repository
    final userId = _sharedPreferences.getString(_currentUserIdKey);
    return userId ?? '1'; // Default to '1' if not found
  }

  @override
  Future<AppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create a new notification object
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
      );
      
      // Try to create via API first
      try {
        final Map<String, dynamic> requestBody = {
          'userId': userId,
          'title': title,
          'message': message,
          'type': type.toString().split('.').last,
          'data': data,
        };
        
        final response = await _apiService.post('/notifications', requestBody);
        if (response != null && response['success'] == true) {
          // If API returns the created notification, use that instead
          if (response['data'] != null) {
            final createdNotification = AppNotification.fromJson(response['data']);
            // Update local storage with the server-created notification
            await _addNotificationLocally(userId, createdNotification);
            return createdNotification;
          }
        }
      } catch (apiError) {
        print('API error, falling back to local storage: $apiError');
        // Fall back to local storage if API fails
      }
      
      // Add to local storage only
      await _addNotificationLocally(userId, notification);
      return notification;
    } catch (e) {
      print('Failed to create notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  // Helper method to add a notification to local storage
  Future<void> _addNotificationLocally(String userId, AppNotification notification) async {
    try {
      final notifications = _getLocalNotifications(userId);
      notifications.insert(0, notification); // Add to the beginning of the list
      await _saveNotificationsLocally(userId, notifications);
    } catch (e) {
      print('Error adding notification locally: $e');
    }
  }

  @override
  Future<void> saveSocketNotification(AppNotification notification) async {
    try {
      await _addNotificationLocally(notification.userId, notification);
    } catch (e) {
      print('Error saving socket notification: $e');
    }
  }
}