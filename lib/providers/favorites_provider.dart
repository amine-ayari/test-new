import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesProvider extends ChangeNotifier {
  List<String> _favorites = [];
  final String _favoritesKey = 'user_favorites';
  
  List<String> get favorites => _favorites;
  
  FavoritesProvider() {
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson != null) {
      _favorites = List<String>.from(jsonDecode(favoritesJson));
      notifyListeners();
    }
  }
  
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, jsonEncode(_favorites));
  }
  
  bool isFavorite(String activityId) {
    return _favorites.contains(activityId);
  }
  
  Future<void> toggleFavorite(String activityId) async {
    if (_favorites.contains(activityId)) {
      _favorites.remove(activityId);
    } else {
      _favorites.add(activityId);
    }
    
    await _saveFavorites();
    notifyListeners();
  }
  
  Future<void> addFavorite(String activityId) async {
    if (!_favorites.contains(activityId)) {
      _favorites.add(activityId);
      await _saveFavorites();
      notifyListeners();
    }
  }
  
  Future<void> removeFavorite(String activityId) async {
    if (_favorites.contains(activityId)) {
      _favorites.remove(activityId);
      await _saveFavorites();
      notifyListeners();
    }
  }
  
  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }
  
  Future<void> setFavorites(List<String> favorites) async {
    _favorites = favorites;
    await _saveFavorites();
    notifyListeners();
  }
}
