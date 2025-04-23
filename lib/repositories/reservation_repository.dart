import 'package:flutter_activity_app/models/reservation.dart';

abstract class ReservationRepository {
  Future<List<Reservation>> getUserReservations(String userId);
  Future<List<Reservation>> getActivityReservations(String activityId);
  Future<List<Reservation>> getProviderReservations();
  Future<Reservation> createReservation(Reservation reservation);
  Future<Reservation> updateReservationStatus(String id, ReservationStatus status, {String? reason});
  Future<void> cancelReservation(String id, {String? reason});
}
