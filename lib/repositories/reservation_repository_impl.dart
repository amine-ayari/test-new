import 'dart:convert';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/repositories/reservation_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ApiService _apiService;

  // Ensure ApiService is properly initialized and passed
  ReservationRepositoryImpl(this._apiService) {
    if (_apiService == null) {
      throw ArgumentError('ApiService cannot be null');
    }
  }

@override
Future<List<Reservation>> getUserReservations(String userId) async {
  try {
    print('Fetching reservations for user: $userId'); // Debugging log

    final response = await _apiService.getWithAuth('/reservations/user'); // Ensure correct endpoint
    print('Response received: $response'); // Check response type for debugging

    // Check if the response is a valid map and contains 'success' = true
    if (response != null && response['success'] == true) {
      // Change this line - use 'reservations' instead of 'data'
      if (response['reservations'] != null) {
        final List<dynamic> reservationsJson = response['reservations'];
        print('Number of reservations: ${reservationsJson.length}'); // Debugging log

        // Convert each JSON element into a Reservation object
        final reservations = reservationsJson.map((json) {
          try {
            return Reservation.fromJson(json);
          } catch (e) {
            print('Error parsing reservation: $e');
            print('Problematic JSON: $json');
            return null;
          }
        }).whereType<Reservation>().toList();

        print('Successfully parsed ${reservations.length} reservations');
        return reservations;
      } else {
        print('No reservations found in response');
        return [];
      }
    } else {
      final errorMessage = response != null ? response['message'] ?? 'Unknown error' : 'Null response';
      throw Exception('Failed to load reservations: $errorMessage');
    }
  } catch (e) {
    print('Error in getUserReservations: $e');
    throw Exception('Error fetching reservations: $e');
  }
}
  @override
  Future<List<Reservation>> getActivityReservations(String activityId) async {
    try {
      final response = await _apiService.get('/reservations/activity/$activityId');
      return (response as List).map((json) => Reservation.fromJson(json)).toList();
    } catch (e) {
      print('Error in getActivityReservations: $e');
      throw Exception('Error fetching activity reservations: $e');
    }
  }


 @override
Future<List<Reservation>> getProviderReservations() async {
  try {
    print('Fetching provider reservations'); // Debugging log

    final response = await _apiService.getWithAuth('/reservations/provider');
    print('Response received: $response'); // Check response type for debugging

    if (response != null && response['success'] == true) {
      // Change this line - use 'reservations' instead of 'data'
      if (response['reservations'] != null) {
        final List<dynamic> reservationsJson = response['reservations'];
        print('Number of reservations: ${reservationsJson.length}'); // Debugging log

        final reservations = reservationsJson.map((json) {
          try {
            return Reservation.fromJson(json);
          } catch (e) {
            print('Error parsing reservation: $e');
            print('Problematic JSON: $json');
            return null;
          }
        }).whereType<Reservation>().toList();

        print('Successfully parsed ${reservations.length} reservations');
        return reservations;
      } else {
        print('No reservations found in response');
        return [];
      }
    } else {
      final errorMessage = response != null ? response['message'] ?? 'Unknown error' : 'Null response';
      throw Exception('Failed to load provider reservations: $errorMessage');
    }
  } catch (e) {
    print('Error in getProviderReservations: $e');
    throw Exception('Error fetching provider reservations: $e');
  }
}
  @override
  Future<Reservation> createReservation(Reservation reservation) async {
    try {
      final response = await _apiService.postWithAuth('/reservations', reservation.toJson());
      return Reservation.fromJson(response);
    } catch (e) {
      print('Error in createReservation: $e');
      throw Exception('Error creating reservation: $e');
    }
  }

  @override
  Future<Reservation> updateReservationStatus(String id, ReservationStatus status, {String? reason}) async {
    try {
      final response = await _apiService.put('/providers/reservations/$id/status', {
        'status': status.toString().split('.').last,
        'reason': reason,
      });
      return Reservation.fromJson(response);
    } catch (e) {
      print('Error in updateReservationStatus: $e');
      throw Exception('Error updating reservation status: $e');
    }
  }

  @override
  Future<void> cancelReservation(String id, {String? reason}) async {
    try {
      await _apiService.put('/reservations/$id/cancel', {
        'message': reason,
      });
    } catch (e) {
      print('Error in cancelReservation: $e');
      throw Exception('Error canceling reservation: $e');
    }
  }
}
