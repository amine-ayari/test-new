import 'dart:io';

import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/notification_settings.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile> getUserProfile(String userId);
  Future<UserProfile> updateUserProfile(UserProfile profile , {File? imageFile});
 /*  Future<void> updateProfileImage(String userId, String imagePath); */
  Future<List<Activity>> getFavoriteActivities(String userId);
  Future<void> addFavoriteActivity(String userId, String activityId);
  Future<void> removeFavoriteActivity(String userId, String activityId);

  /// Change the user password
  Future<bool> changePassword(String currentPassword, String newPassword);

  /// Get the user notification settings
  Future<NotificationSettings> getNotificationSettings();

  /// Update the user notification settings
  Future<bool> updateNotificationSettings(NotificationSettings settings);
}
