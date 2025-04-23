// lib/services/location_service.dart
import 'package:latlong2/latlong.dart';

class LocationService {
  // Calculer la distance entre deux points
  double calculateDistance(LatLng point1, LatLng point2) {
    return const Distance().as(
      LengthUnit.Kilometer,
      point1,
      point2,
    );
  }
  
  // Formater la distance pour l'affichage
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      // Convertir en mètres
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else if (distanceInKm < 10) {
      // Afficher avec une décimale
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      // Arrondir au km
      return '${distanceInKm.round()} km';
    }
  }
}