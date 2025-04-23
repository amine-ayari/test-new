import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class NotificationSettings extends Equatable {
  final bool enabled;
  final bool activityReminders;
  final bool bookingConfirmations;
  final bool promotions;
  final bool newsletter;
  final bool appUpdates;
  final bool quietHoursEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  
  // Propriétés supplémentaires utilisées dans NotificationSettingsScreen
  final bool newActivities;
  final bool priceDrops;
  final bool recommendations;
  final bool bookingReminders;
  final bool bookingChanges;

  const NotificationSettings({
    this.enabled = true,
    this.activityReminders = true,
    this.bookingConfirmations = true,
    this.promotions = false,
    this.newsletter = false,
    this.appUpdates = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.newActivities = true,
    this.priceDrops = true,
    this.recommendations = true,
    this.bookingReminders = true,
    this.bookingChanges = true,
  });

  @override
  List<Object?> get props => [
    enabled,
    activityReminders,
    bookingConfirmations,
    promotions,
    newsletter,
    appUpdates,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
    newActivities,
    priceDrops,
    recommendations,
    bookingReminders,
    bookingChanges,
  ];

  NotificationSettings copyWith({
    bool? enabled,
    bool? activityReminders,
    bool? bookingConfirmations,
    bool? promotions,
    bool? newsletter,
    bool? appUpdates,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? newActivities,
    bool? priceDrops,
    bool? recommendations,
    bool? bookingReminders,
    bool? bookingChanges,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      activityReminders: activityReminders ?? this.activityReminders,
      bookingConfirmations: bookingConfirmations ?? this.bookingConfirmations,
      promotions: promotions ?? this.promotions,
      newsletter: newsletter ?? this.newsletter,
      appUpdates: appUpdates ?? this.appUpdates,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      newActivities: newActivities ?? this.newActivities,
      priceDrops: priceDrops ?? this.priceDrops,
      recommendations: recommendations ?? this.recommendations,
      bookingReminders: bookingReminders ?? this.bookingReminders,
      bookingChanges: bookingChanges ?? this.bookingChanges,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'enabled': enabled,
      'activityReminders': activityReminders,
      'bookingConfirmations': bookingConfirmations,
      'promotions': promotions,
      'newsletter': newsletter,
      'appUpdates': appUpdates,
      'quietHoursEnabled': quietHoursEnabled,
      'newActivities': newActivities,
      'priceDrops': priceDrops,
      'recommendations': recommendations,
      'bookingReminders': bookingReminders,
      'bookingChanges': bookingChanges,
    };
    
    if (quietHoursStart != null) {
      data['quietHoursStart'] = '${quietHoursStart!.hour}:${quietHoursStart!.minute}';
    }
    
    if (quietHoursEnd != null) {
      data['quietHoursEnd'] = '${quietHoursEnd!.hour}:${quietHoursEnd!.minute}';
    }
    
    return data;
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    TimeOfDay? quietHoursStart;
    TimeOfDay? quietHoursEnd;
    
    if (json['quietHoursStart'] != null) {
      final parts = json['quietHoursStart'].split(':');
      quietHoursStart = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    
    if (json['quietHoursEnd'] != null) {
      final parts = json['quietHoursEnd'].split(':');
      quietHoursEnd = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      activityReminders: json['activityReminders'] ?? true,
      bookingConfirmations: json['bookingConfirmations'] ?? true,
      promotions: json['promotions'] ?? false,
      newsletter: json['newsletter'] ?? false,
      appUpdates: json['appUpdates'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      newActivities: json['newActivities'] ?? true,
      priceDrops: json['priceDrops'] ?? true,
      recommendations: json['recommendations'] ?? true,
      bookingReminders: json['bookingReminders'] ?? true,
      bookingChanges: json['bookingChanges'] ?? true,
    );
  }
}
