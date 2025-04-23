import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final bool darkMode;
  final String? language;
  final bool notificationsEnabled;
  final List<String>? preferredCategories;
  final double? maxPrice;
  final double? minRating;
  final bool showOnlyAvailable;
  final Map<String, dynamic>? additionalPreferences;

  const UserPreferences({
    this.darkMode = false,
    this.language,
    this.notificationsEnabled = true,
    this.preferredCategories,
    this.maxPrice,
    this.minRating,
    this.showOnlyAvailable = true,
    this.additionalPreferences,
  });

  @override
  List<Object?> get props => [
    darkMode, language, notificationsEnabled, preferredCategories,
    maxPrice, minRating, showOnlyAvailable, additionalPreferences
  ];

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: json['darkMode'] ?? false,
      language: json['language'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      preferredCategories: json['preferredCategories'] != null 
          ? List<String>.from(json['preferredCategories']) 
          : null,
      maxPrice: json['maxPrice']?.toDouble(),
      minRating: json['minRating']?.toDouble(),
      showOnlyAvailable: json['showOnlyAvailable'] ?? true,
      additionalPreferences: json['additionalPreferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'preferredCategories': preferredCategories,
      'maxPrice': maxPrice,
      'minRating': minRating,
      'showOnlyAvailable': showOnlyAvailable,
      'additionalPreferences': additionalPreferences,
    };
  }

  UserPreferences copyWith({
    bool? darkMode,
    String? language,
    bool? notificationsEnabled,
    List<String>? preferredCategories,
    double? maxPrice,
    double? minRating,
    bool? showOnlyAvailable,
    Map<String, dynamic>? additionalPreferences,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      showOnlyAvailable: showOnlyAvailable ?? this.showOnlyAvailable,
      additionalPreferences: additionalPreferences ?? this.additionalPreferences,
    );
  }
}
