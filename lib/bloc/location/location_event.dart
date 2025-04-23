// lib/bloc/location/location_event.dart
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class GetCurrentLocation extends LocationEvent {
  const GetCurrentLocation();
}

class UpdateLocation extends LocationEvent {
  final LatLng location;
  
  const UpdateLocation(this.location);
  
  @override
  List<Object?> get props => [location];
}

class LocationPermissionDenied extends LocationEvent {
  const LocationPermissionDenied();
}

class SetCustomLocation extends LocationEvent {
  final LatLng location;
  
  const SetCustomLocation(this.location);
  
  @override
  List<Object?> get props => [location];
}