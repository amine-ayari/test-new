import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/reservation.dart';

abstract class ReservationState extends Equatable {
  const ReservationState();

  @override
  List<Object?> get props => [];
}

class ReservationInitial extends ReservationState {
  const ReservationInitial();
}

class ReservationLoading extends ReservationState {
  const ReservationLoading();
}

class UserReservationsLoaded extends ReservationState {
  final List<Reservation> reservations;

  const UserReservationsLoaded(this.reservations);

  @override
  List<Object?> get props => [reservations];
}

class ActivityReservationsLoaded extends ReservationState {
  final List<Reservation> reservations;

  const ActivityReservationsLoaded(this.reservations);

  @override
  List<Object?> get props => [reservations];
}

class ProviderReservationsLoaded extends ReservationState {
  final List<Reservation> reservations;

  const ProviderReservationsLoaded(this.reservations);

  @override
  List<Object?> get props => [reservations];
}

class ReservationCreated extends ReservationState {
  final Reservation reservation;

  const ReservationCreated(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class ReservationStatusUpdated extends ReservationState {
  final Reservation reservation;

  const ReservationStatusUpdated(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class ReservationCancelled extends ReservationState {
  final String reservationId;

  const ReservationCancelled(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

class ReservationError extends ReservationState {
  final String message;

  const ReservationError(this.message);

  @override
  List<Object?> get props => [message];
}
