import 'dart:convert';

import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/repositories/activity_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final SharedPreferences _sharedPreferences;
  final ApiService _apiService;
  final String _favoritesKey = 'favorites';

  ActivityRepositoryImpl(this._sharedPreferences, this._apiService);

  @override
  Future<List<Activity>> getActivities() async {
    try {
      print('Fetching activities from API...');
      return await _apiService.getActivities();
    } catch (e) {
      throw Exception('Failed to load activities: $e');
    }
  }

  @override
  Future<Activity> getActivityById(String id) async {
    try {
      return await _apiService.getActivityById(id);
    } catch (e) {
      throw Exception('Activity not found: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    try {
      final activity = await getActivityById(id);
      await _apiService.toggleFavorite(id, !activity.isFavorite);
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  @override
  Future<List<Activity>> getFavoriteActivities() async {
    try {
      return await _apiService.getFavoriteActivities();
    } catch (e) {
      throw Exception('Failed to get favorite activities: $e');
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      return await _apiService.getCategories();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  @override
  Future<void> rejectActivity(String id) async {
    try {
      await _apiService.rejectActivity(id);
    } catch (e) {
      throw Exception('Failed to reject activity: $e');
    }
  }

  @override
  Future<void> likeActivity(String id) async {
    try {
      await _apiService.likeActivity(id);
    } catch (e) {
      throw Exception('Failed to like activity: $e');
    }
  }
}
