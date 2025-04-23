// TODO Implement this library.
import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/notification_settings.dart';
import 'package:flutter_activity_app/models/user_profile.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserProfileLoaded extends UserState {
  final UserProfile profile;

  const UserProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UserProfileUpdated extends UserState {
  final UserProfile profile;

  const UserProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileImageUpdated extends UserState {
  final String imagePath;

  const ProfileImageUpdated(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class FavoritesLoaded extends UserState {
  final List<Activity> favorites;
  const FavoritesLoaded(this.favorites);
}

class FavoriteAdded extends UserState {
  final String activityId;

  const FavoriteAdded(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class FavoriteRemoved extends UserState {
  final String activityId;

  const FavoriteRemoved(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}


class UserPasswordChanged extends UserState {
  const UserPasswordChanged();
}

class NotificationSettingsLoaded extends UserState {
  final NotificationSettings settings;

  const NotificationSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class NotificationSettingsUpdated extends UserState {
  final NotificationSettings settings;

  const NotificationSettingsUpdated(this.settings);

  @override
  List<Object?> get props => [settings];
}


