// TODO Implement this library.
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_activity_app/bloc/activity/activity_state.dart';
import 'package:flutter_activity_app/repositories/activity_repository.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:latlong2/latlong.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _activityRepository;

  ActivityBloc(this._activityRepository) : super(const ActivityInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<FilterActivities>(_onFilterActivities);
    on<ToggleFavorite>(_onToggleFavorite);
    on<SearchActivities>(_onSearchActivities);
    on<LoadActivityDetails>(_onLoadActivityDetails);
    on<SwipeLeftActivity>(_onSwipeLeftActivity); // Ajouter cette ligne
    on<SwipeRightActivity>(_onSwipeRightActivity);
    
   
    on<UpdateActivitiesWithDistance>(_onUpdateActivitiesWithDistance);
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivityState> emit,
  ) async {
    emit(const ActivityLoading());
    try {
      final activities = await _activityRepository.getActivities();
      final categories = _extractUniqueCategories(activities);

      emit(ActivitiesLoaded(
        activities: activities,
        filteredActivities: activities,
        categories: categories,
      ));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

 // lib/bloc/activity/activity_bloc.dart (mise à jour)
// Modifiez la méthode _onFilterActivities pour prendre en compte la distance

Future<void> _onFilterActivities(
  FilterActivities event,
  Emitter<ActivityState> emit,
) async {
  if (state is ActivitiesLoaded) {
    final currentState = state as ActivitiesLoaded;
    
    List<Activity> filteredActivities = List.from(currentState.activities);
    
    // Filtrer par catégorie
    if (event.category != null) {
      filteredActivities = filteredActivities
          .where((activity) => activity.category == event.category)
          .toList();
    }
    
    // Filtrer par prix
    if (event.minPrice != null || event.maxPrice != null) {
      filteredActivities = filteredActivities
          .where((activity) => 
            (event.minPrice == null || activity.price >= event.minPrice!) &&
            (event.maxPrice == null || activity.price <= event.maxPrice!)
          )
          .toList();
    }
    
    // Filtrer par note
    if (event.minRating != null) {
      filteredActivities = filteredActivities
          .where((activity) => activity.rating >= event.minRating!)
          .toList();
    }
    
    // Filtrer par tags
    if (event.tags != null && event.tags!.isNotEmpty) {
      filteredActivities = filteredActivities
          .where((activity) => 
            activity.tags.any((tag) => event.tags!.contains(tag))
          )
          .toList();
    }
    
    // Filtrer par distance
    if (event.maxDistance != null && event.userLocation != null) {
      filteredActivities = filteredActivities
          .where((activity) {
            if (activity.latitude == null || activity.longitude == null) {
              return false;
            }
            
            final distance = const Distance().as(
              LengthUnit.Kilometer,
              event.userLocation!,
              LatLng(activity.latitude!, activity.longitude!),
            );
            
            return distance <= event.maxDistance!;
          })
          .toList();
    }
    
    emit(ActivitiesLoaded(
      activities: currentState.activities,
      filteredActivities: filteredActivities,
      categories: currentState.categories,
      userLocation: event.userLocation ?? currentState.userLocation,
    ));
  }
}
  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<ActivityState> emit,
  ) async {
    if (state is ActivitiesLoaded) {
      final currentState = state as ActivitiesLoaded;
      try {
        await _activityRepository.toggleFavorite(event.activityId);

        final updatedActivities = currentState.activities.map((activity) {
          if (activity.id == event.activityId) {
            return activity.copyWith(isFavorite: !activity.isFavorite);
          }
          return activity;
        }).toList();

        final updatedFilteredActivities =
            currentState.filteredActivities.map((activity) {
          if (activity.id == event.activityId) {
            return activity.copyWith(isFavorite: !activity.isFavorite);
          }
          return activity;
        }).toList();

        emit(currentState.copyWith(
          activities: updatedActivities,
          filteredActivities: updatedFilteredActivities,
        ));
      } catch (e) {
        // We don't emit an error state here to avoid disrupting the UI
        // The repository will handle the fallback to local storage
      }
    } else if (state is ActivityDetailsLoaded) {
      final currentState = state as ActivityDetailsLoaded;
      try {
        await _activityRepository.toggleFavorite(event.activityId);

        if (currentState.activity.id == event.activityId) {
          final updatedActivity = currentState.activity.copyWith(
            isFavorite: !currentState.activity.isFavorite,
          );
          emit(ActivityDetailsLoaded(updatedActivity));
        }
      } catch (e) {
        // We don't emit an error state here to avoid disrupting the UI
        // The repository will handle the fallback to local storage
      }
    }
  }

  Future<void> _onSearchActivities(
    SearchActivities event,
    Emitter<ActivityState> emit,
  ) async {
    if (state is ActivitiesLoaded) {
      final currentState = state as ActivitiesLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(
            currentState.copyWith(filteredActivities: currentState.activities));
        return;
      }

      final searchResults = currentState.activities.where((activity) {
        return activity.name.toLowerCase().contains(query) ||
            activity.description.toLowerCase().contains(query) ||
            activity.category.toLowerCase().contains(query) ||
            activity.location.toLowerCase().contains(query) ||
            activity.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();

      emit(currentState.copyWith(filteredActivities: searchResults));
    }
  }

  Future<void> _onLoadActivityDetails(
    LoadActivityDetails event,
    Emitter<ActivityState> emit,
  ) async {
    emit(const ActivityLoading());
    try {
      final activity =
          await _activityRepository.getActivityById(event.activityId);
      emit(ActivityDetailsLoaded(activity));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

  List<String> _extractUniqueCategories(List<Activity> activities) {
    final categories =
        activities.map((activity) => activity.category).toSet().toList();
    categories.sort();
    return categories;
  }

  List<Activity> _filterActivities(
    List<Activity> activities, {
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? tags,
  }) {
    return activities.where((activity) {
      // Filter by category
      if (category != null &&
          category.isNotEmpty &&
          activity.category != category) {
        return false;
      }

      // Filter by price range
      if (minPrice != null && activity.price < minPrice) {
        return false;
      }
      if (maxPrice != null && activity.price > maxPrice) {
        return false;
      }

      // Filter by rating
      if (minRating != null && activity.rating < minRating) {
        return false;
      }

      // Filter by tags
      if (tags != null && tags.isNotEmpty) {
        final hasMatchingTag = tags.any((tag) => activity.tags.contains(tag));
        if (!hasMatchingTag) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Ajouter ces méthodes à votre ActivityBloc
  Future<void> _onSwipeLeftActivity(
    SwipeLeftActivity event,
    Emitter<ActivityState> emit,
  ) async {
    // Logique pour quand l'utilisateur rejette une activité
    // Par exemple, vous pourriez vouloir enregistrer cette préférence
    // ou utiliser ces données pour améliorer les recommandations futures
    try {
      await _activityRepository.rejectActivity(event.activityId);
      // Pas besoin de changer l'état ici car l'UI gère déjà le passage à l'activité suivante
    } catch (e) {
      // Gérer silencieusement l'erreur
    }
  }

  Future<void> _onSwipeRightActivity(
    SwipeRightActivity event,
    Emitter<ActivityState> emit,
  ) async {
    // Logique pour quand l'utilisateur aime une activité
    try {
      await _activityRepository.likeActivity(event.activityId);
      // L'activité est déjà marquée comme favorite via ToggleFavorite
    } catch (e) {
      // Gérer silencieusement l'erreur
    }
  }

  Future<void> _onUpdateActivitiesWithDistance(
  UpdateActivitiesWithDistance event,
  Emitter<ActivityState> emit,
) async {
  if (state is ActivitiesLoaded) {
    final currentState = state as ActivitiesLoaded;
    
    // Mettre à jour l'état avec la nouvelle position utilisateur
    emit(currentState.copyWith(userLocation: event.userLocation));
  }
}


}
