// TODO Implement this library.
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/notification_settings.dart';
import 'package:flutter_activity_app/models/user_profile.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends UserEvent {
  final String userId;

  const LoadUserProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserProfile extends UserEvent {
  final UserProfile profile;
  final File? profileImage;  // Ajout de l'image en option

  UpdateUserProfile(this.profile, {this.profileImage});
}


class UpdateProfileImage extends UserEvent {
  final String userId;
  final String imagePath;

  const UpdateProfileImage(this.userId, this.imagePath);

  @override
  List<Object?> get props => [userId, imagePath];
}

class LoadFavoriteActivities extends UserEvent {
  final String userId;

  const LoadFavoriteActivities(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddFavoriteActivity extends UserEvent {
  final String userId;
  final String activityId;

  const AddFavoriteActivity(this.userId, this.activityId);

  @override
  List<Object?> get props => [userId, activityId];
}

class RemoveFavoriteActivity extends UserEvent {
  final String userId;
  final String activityId;

  const RemoveFavoriteActivity(this.userId, this.activityId);

  @override
  List<Object?> get props => [userId, activityId];
}
class ChangePassword extends UserEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class LoadNotificationSettings extends UserEvent {
  const LoadNotificationSettings();
}
class UpdateNotificationSettings extends UserEvent {
  final NotificationSettings settings;

  const UpdateNotificationSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}
