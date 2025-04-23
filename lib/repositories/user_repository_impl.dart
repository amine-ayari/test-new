// TODO Implement this library.
import 'dart:convert';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/notification_settings.dart';
import 'package:flutter_activity_app/models/user_profile.dart';
import 'package:flutter_activity_app/repositories/user_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'package:http/http.dart' as http;


class UserRepositoryImpl implements UserRepository {
  final SharedPreferences _sharedPreferences;
  final ApiService _apiService;
  final String _userProfileKey = 'user_profile';
  final String _favoritesKey = 'user_favorites';
  static const String _notificationSettingsKey = 'notification_settings';

  UserRepositoryImpl(this._sharedPreferences, this._apiService);

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    final response = await _apiService.getWithAuth('/users/profile');
  
    final profile = UserProfile.fromJson(response);
      print('Profile fetched successfully $profile');
    // Optionally cache the profile locally
    await _saveLocalUserProfile(profile);
    return profile;
  }



@override
Future<UserProfile> updateUserProfile(UserProfile profile, {File? imageFile}) async {
  print('Saving profile...');

  // Créer une requête multipart
  var request = http.MultipartRequest('PUT', Uri.parse('${_apiService.baseUrl}/users/profile'));

  // Ajouter les données du profil dans les champs de la requête
  request.fields.addAll(profile.toJson().map((key, value) => MapEntry(key, value.toString())));

  // Si un fichier image est fourni, l'ajouter à la requête
  if (imageFile != null) {
    request.files.add(await http.MultipartFile.fromPath('profileImage', imageFile.path));
  }

  // Envoyer la requête
  var response = await _apiService.sendMultipartRequest(request);
  print('Profile saved successfully $response');

  // Extraire le champ 'data' de la réponse
  final updatedProfile = UserProfile.fromJson(response['data']);

  // Mettre à jour le cache local
  await _saveLocalUserProfile(updatedProfile);
  return updatedProfile;
}




 @override
  Future<List<Activity>> getFavoriteActivities(String userId) async {
    // Example implementation: fetch from API
    final response = await _apiService.getWithAuth('/users/favorites');
    return (response['data'] as List)
        .map((json) => Activity.fromJson(json))
        .toList();
  }

 

 

  // Local storage helpers
  Future<UserProfile> _getLocalUserProfile(String userId) async {
    final jsonString = _sharedPreferences.getString('$_userProfileKey:$userId');
    if (jsonString == null) {
      // Return a default profile if none exists
      return UserProfile(
        id: userId,
        name: 'User',
        email: 'user@example.com',
      );
    }
    
    return UserProfile.fromJson(jsonDecode(jsonString));
  }

  Future<void> _saveLocalUserProfile(UserProfile profile) async {
    await _sharedPreferences.setString(
      '$_userProfileKey:${profile.id}',
      jsonEncode(profile.toJson()),
    );
  }

  Future<List<String>> _getLocalFavorites(String userId) async {
    final jsonString = _sharedPreferences.getString('$_favoritesKey:$userId');
    if (jsonString == null) return [];
    
    return List<String>.from(jsonDecode(jsonString));
  }

  Future<void> _saveLocalFavorites(String userId, List<String> favorites) async {
    await _sharedPreferences.setString(
      '$_favoritesKey:$userId',
      jsonEncode(favorites),
    );
  }

  @override
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      // In a real app, we would change password via API
      // final response = await _apiService.post('/user/change-password', body: {
      //   'currentPassword': currentPassword,
      //   'newPassword': newPassword,
      // });
      
      // For demo purposes, we'll simulate a successful password change
      // Add a delay to simulate network request
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      // In a real app, we would fetch from API
      // final response = await _apiService.get('/user/notification-settings');
      
      // For demo purposes, we'll use SharedPreferences
      final settingsJson = _sharedPreferences.getString(_notificationSettingsKey);
      
      if (settingsJson != null) {
        return NotificationSettings.fromJson(jsonDecode(settingsJson));
      }
      
      // Return default settings if none are found
      return const NotificationSettings();
    } catch (e) {
      throw Exception('Failed to get notification settings: $e');
    }
  }

  @override
  Future<bool> updateNotificationSettings(NotificationSettings settings) async {
    try {
      // In a real app, we would update via API
      // final response = await _apiService.put('/user/notification-settings', body: settings.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      await _sharedPreferences.setString(_notificationSettingsKey, jsonEncode(settings.toJson()));
      
      // Add a delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 500));
      
      return true;
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }
  
  @override
  Future<void> addFavoriteActivity(String userId, String activityId) async {
    try {
      // Send a request to the backend to add the activity to the user's favorites
      await _apiService.postWithAuth('/users/favorites', {'activityId': activityId});
      
      // Optionally update local cache
      final favorites = await _getLocalFavorites(userId);
      if (!favorites.contains(activityId)) {
        favorites.add(activityId);
        await _saveLocalFavorites(userId, favorites);
      }
    } catch (e) {
      throw Exception('Failed to add favorite activity: $e');
    }
  }
  
  @override
  Future<void> removeFavoriteActivity(String userId, String activityId) async {
    try {
      // Send a request to the backend to remove the activity from the user's favorites
      await _apiService.delete('/users/favorites/$activityId');
      
      // Optionally update local cache
      final favorites = await _getLocalFavorites(userId);
      if (favorites.contains(activityId)) {
        favorites.remove(activityId);
        await _saveLocalFavorites(userId, favorites);
      }
    } catch (e) {
      throw Exception('Failed to remove favorite activity: $e');
    }
  }
}
