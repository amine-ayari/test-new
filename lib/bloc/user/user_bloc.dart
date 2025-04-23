import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_event.dart';
import 'package:flutter_activity_app/bloc/user/user_state.dart';
import 'package:flutter_activity_app/repositories/user_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc(this._userRepository) : super(const UserInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    /* on<UpdateProfileImage>(_onUpdateProfileImage); */
    on<LoadFavoriteActivities>(_onLoadFavoriteActivities);
    /*    on<AddFavoriteActivity>(_onAddFavoriteActivity); */
    /*  on<RemoveFavoriteActivity>(_onRemoveFavoriteActivity); */
    on<ChangePassword>(_onChangePassword);
    on<LoadNotificationSettings>(_onLoadNotificationSettings);
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final profile = await _userRepository.getUserProfile(event.userId);
      emit(UserProfileLoaded(profile));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
  UpdateUserProfile event,
  Emitter<UserState> emit,
) async {
  emit(const UserLoading());
  try {
    print('Updating user profile with: ${event.profile.toJson()}');

    // Passer les deux arguments : UserProfile et image (si elle existe)
    final updatedProfile = await _userRepository.updateUserProfile(
        event.profile, imageFile: event.profileImage);

    emit(UserProfileUpdated(updatedProfile));
  } catch (e) {
    emit(UserError(e.toString()));
  }
}


 /*  Future<void> _onUpdateProfileImage(
    UpdateProfileImage event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      await _userRepository.updateProfileImage(event.userId, event.imagePath);
      emit(ProfileImageUpdated(event.imagePath));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  } */

  Future<void> _onLoadFavoriteActivities(
    LoadFavoriteActivities event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final favorites =
          await _userRepository.getFavoriteActivities(event.userId);
      emit(FavoritesLoaded(favorites.cast<Activity>()));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

/*   Future<void> _onAddFavoriteActivity(
    AddFavoriteActivity event,
    Emitter<UserState> emit,
  ) async {
    try {
      await _userRepository.addFavoriteActivity(event.userId, event.activityId);
      emit(FavoriteAdded(event.activityId));
      
      // Reload favorites to ensure state is up to date
      add(LoadFavoriteActivities(event.userId));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  } */

  /*  Future<void> _onRemoveFavoriteActivity(
    RemoveFavoriteActivity event,
    Emitter<UserState> emit,
  ) async {
    try {
      await _userRepository.removeFavoriteActivity(event.userId, event.activityId);
      emit(FavoriteRemoved(event.activityId));
      
      // Reload favorites to ensure state is up to date
      add(LoadFavoriteActivities(event.userId));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
 */
  Future<void> _onChangePassword(
    ChangePassword event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final success = await _userRepository.changePassword(
        event.currentPassword,
        event.newPassword,
      );

      if (success) {
        emit(const UserPasswordChanged());
      } else {
        emit(const UserError('Failed to change password. Please try again.'));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettings event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final settings = await _userRepository.getNotificationSettings();
      emit(NotificationSettingsLoaded(settings));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettings event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final success =
          await _userRepository.updateNotificationSettings(event.settings);

      if (success) {
        emit(NotificationSettingsUpdated(event.settings));
        emit(NotificationSettingsLoaded(event.settings));
      } else {
        emit(const UserError(
            'Failed to update notification settings. Please try again.'));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
