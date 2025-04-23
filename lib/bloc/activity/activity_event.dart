import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:latlong2/latlong.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivities extends ActivityEvent {
  const LoadActivities();
}

// lib/bloc/activity/activity_event.dart (mise à jour)
// Modifiez l'événement FilterActivities pour inclure les paramètres de distance

class FilterActivities extends ActivityEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String>? tags;
  final double? maxDistance;
  final LatLng? userLocation;
  
  const FilterActivities({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.tags,
    this.maxDistance,
    this.userLocation,
  });
  
  @override
  List<Object?> get props => [category, minPrice, maxPrice, minRating, tags, maxDistance, userLocation];
}

class ToggleFavorite extends ActivityEvent {
  final String activityId;

  const ToggleFavorite(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class SearchActivities extends ActivityEvent {
  final String query;

  const SearchActivities(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadActivityDetails extends ActivityEvent {
  final String activityId;

  const LoadActivityDetails(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

// Événements pour le swipe
class SwipeLeftActivity extends ActivityEvent {
  final String activityId;
  const SwipeLeftActivity(this.activityId);
  
  @override
  List<Object?> get props => [activityId];
}

class SwipeRightActivity extends ActivityEvent {
  final String activityId;
  const SwipeRightActivity(this.activityId);
  
  @override
  List<Object?> get props => [activityId];
}
class UpdateActivitiesWithDistance extends ActivityEvent {
  final LatLng userLocation;
  
  const UpdateActivitiesWithDistance(this.userLocation);
  
  @override
  List<Object?> get props => [userLocation];
}