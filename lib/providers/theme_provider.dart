import 'package:flutter/material.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isSystemTheme = false;

  ThemeMode get themeMode => _themeMode;
  bool get isSystemTheme => _isSystemTheme;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isSystem = prefs.getBool('isSystemTheme') ?? false;
    final isDark = prefs.getBool('isDarkTheme') ?? false;

    _isSystemTheme = isSystem;
    _themeMode = isSystem 
        ? ThemeMode.system 
        : (isDark ? ThemeMode.dark : ThemeMode.light);
    notifyListeners();
  }

  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
    _isSystemTheme = false;
    await _saveThemePreference();
    notifyListeners();
  }

  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
    _isSystemTheme = false;
    await _saveThemePreference();
    notifyListeners();
  }

  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    _isSystemTheme = true;
    await _saveThemePreference();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_isSystemTheme) {
      _isSystemTheme = false;
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    await _saveThemePreference();
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSystemTheme', _isSystemTheme);
    await prefs.setBool('isDarkTheme', _themeMode == ThemeMode.dark);
  }
}
