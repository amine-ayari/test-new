// lib/bloc/location/location_state.dart
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationLoaded extends LocationState {
  final LatLng location;
  final bool isCustomLocation;
  
  const LocationLoaded({
    required this.location,
    this.isCustomLocation = false,
  });
  
  @override
  List<Object?> get props => [location, isCustomLocation];
  
  LocationLoaded copyWith({
    LatLng? location,
    bool? isCustomLocation,
  }) {
    return LocationLoaded(
      location: location ?? this.location,
      isCustomLocation: isCustomLocation ?? this.isCustomLocation,
    );
  }
}

class LocationError extends LocationState {
  final String message;
  final bool isPermissionDenied;
  
  const LocationError({
    required this.message,
    this.isPermissionDenied = false,
  });
  
  @override
  List<Object?> get props => [message, isPermissionDenied];
}