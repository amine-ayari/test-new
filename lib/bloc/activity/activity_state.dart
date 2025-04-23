  import 'package:equatable/equatable.dart';
  import 'package:flutter_activity_app/models/activity.dart';
  import 'package:latlong2/latlong.dart';

  abstract class ActivityState extends Equatable {
    const ActivityState();

    @override
    List<Object?> get props => [];
  }

  class ActivityInitial extends ActivityState {
    const ActivityInitial();
  }

  class ActivityLoading extends ActivityState {
    const ActivityLoading();
  }

  // lib/bloc/activity/activity_state.dart (mise à jour)
  // Modifiez la classe ActivitiesLoaded pour inclure les distances

  class ActivitiesLoaded extends ActivityState {
    final List<Activity> activities;
    final List<Activity> filteredActivities;
    final List<String> categories;
    final LatLng? userLocation;
    
    const ActivitiesLoaded({
      required this.activities,
      required this.filteredActivities,
      required this.categories,
      this.userLocation,
    });
    
    @override
    List<Object?> get props => [activities, filteredActivities, categories, userLocation];
    
    ActivitiesLoaded copyWith({
      List<Activity>? activities,
      List<Activity>? filteredActivities,
      List<String>? categories,
      LatLng? userLocation,
    }) {
      return ActivitiesLoaded(
        activities: activities ?? this.activities,
        filteredActivities: filteredActivities ?? this.filteredActivities,
        categories: categories ?? this.categories,
        userLocation: userLocation ?? this.userLocation,
      );
    }
  }

  class ActivityDetailsLoaded extends ActivityState {
    final Activity activity;

    const ActivityDetailsLoaded(this.activity);

    @override
    List<Object?> get props => [activity];
  }

  class ActivityError extends ActivityState {
    final String message;

    const ActivityError(this.message);

    @override
    List<Object?> get props => [message];
  }
