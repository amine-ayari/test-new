// lib/bloc/location/location_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_activity_app/bloc/location/location_event.dart';
import 'package:flutter_activity_app/bloc/location/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  StreamSubscription<Position>? _positionStreamSubscription;
  
  LocationBloc() : super(const LocationInitial()) {
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<UpdateLocation>(_onUpdateLocation);
    on<LocationPermissionDenied>(_onLocationPermissionDenied);
    on<SetCustomLocation>(_onSetCustomLocation);
  }
  
  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    
    try {
      // Vérifier les permissions de localisation
      final permission = await _checkLocationPermission();
      
      if (permission == LocationPermission.denied) {
        // Demander la permission
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          add(const LocationPermissionDenied());
          return;
        } else if (requestPermission == LocationPermission.deniedForever) {
          emit(const LocationError(
            message: 'Les permissions de localisation sont définitivement refusées. Veuillez les activer dans les paramètres.',
            isPermissionDenied: true,
          ));
          return;
        }
      } else if (permission == LocationPermission.deniedForever) {
        emit(const LocationError(
          message: 'Les permissions de localisation sont définitivement refusées. Veuillez les activer dans les paramètres.',
          isPermissionDenied: true,
        ));
        return;
      }
      
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final location = LatLng(position.latitude, position.longitude);
      emit(LocationLoaded(location: location));
      
      // Commencer à écouter les mises à jour de position
      _startLocationUpdates();
    } catch (e) {
      emit(LocationError(message: 'Erreur lors de la récupération de la position: $e'));
    }
  }
  
  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<LocationState> emit,
  ) async {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      emit(currentState.copyWith(location: event.location));
    } else {
      emit(LocationLoaded(location: event.location));
    }
  }
  
  Future<void> _onLocationPermissionDenied(
    LocationPermissionDenied event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationError(
      message: 'Les permissions de localisation sont nécessaires pour cette fonctionnalité.',
      isPermissionDenied: true,
    ));
  }
  
  Future<void> _onSetCustomLocation(
    SetCustomLocation event,
    Emitter<LocationState> emit,
  ) async {
    // Arrêter les mises à jour de position automatiques
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    emit(LocationLoaded(
      location: event.location,
      isCustomLocation: true,
    ));
  }
  
  Future<LocationPermission> _checkLocationPermission() async {
    // Vérifier si les services de localisation sont activés
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.deniedForever;
    }
    
    return await Geolocator.checkPermission();
  }
  
  void _startLocationUpdates() {
    _positionStreamSubscription?.cancel();
    
    // Écouter les mises à jour de position
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      ),
    ).listen((Position position) {
      add(UpdateLocation(LatLng(position.latitude, position.longitude)));
    });
  }
  
  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
  }
}