import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/reservation.dart';

abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserReservations extends ReservationEvent {
  final String userId;

  const LoadUserReservations(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadActivityReservations extends ReservationEvent {
  final String activityId;

  const LoadActivityReservations(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class LoadProviderReservations extends ReservationEvent {
  final String providerId;

  const LoadProviderReservations(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class CreateReservation extends ReservationEvent {
  final Reservation reservation;

  const CreateReservation(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class UpdateReservationStatus extends ReservationEvent {
  final String reservationId;
  final ReservationStatus status;
  final String? reason;

  const UpdateReservationStatus(this.reservationId, this.status, {this.reason});

  @override
  List<Object?> get props => [reservationId, status, reason];
}

class CancelReservation extends ReservationEvent {
  final String reservationId;
  final String? reason;

  const CancelReservation(this.reservationId, {this.reason});

  @override
  List<Object?> get props => [reservationId, reason];
}
