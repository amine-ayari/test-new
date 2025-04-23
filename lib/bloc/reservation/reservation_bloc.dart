import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/repositories/reservation_repository.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationRepository _reservationRepository;

  ReservationBloc(this._reservationRepository) : super(const ReservationInitial()) {
    on<LoadUserReservations>(_onLoadUserReservations);
    on<LoadActivityReservations>(_onLoadActivityReservations);
    on<LoadProviderReservations>(_onLoadProviderReservations);
    on<CreateReservation>(_onCreateReservation);
    on<UpdateReservationStatus>(_onUpdateReservationStatus);
    on<CancelReservation>(_onCancelReservation);
  }

  Future<void> _onLoadUserReservations(
    LoadUserReservations event,
    Emitter<ReservationState> emit,
  ) async {
    emit(const ReservationLoading());
    try {
      final reservations = await _reservationRepository.getUserReservations(event.userId);
      emit(UserReservationsLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onLoadActivityReservations(
    LoadActivityReservations event,
    Emitter<ReservationState> emit,
  ) async {
    emit(const ReservationLoading());
    try {
      final reservations = await _reservationRepository.getActivityReservations(event.activityId);
      emit(ActivityReservationsLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onLoadProviderReservations(
    LoadProviderReservations event,
    Emitter<ReservationState> emit,
  ) async {
    emit(const ReservationLoading());
    try {
      final reservations = await _reservationRepository.getProviderReservations();
      emit(ProviderReservationsLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onCreateReservation(
    CreateReservation event,
    Emitter<ReservationState> emit,
  ) async {
    emit(const ReservationLoading());
    try {
      final reservation = await _reservationRepository.createReservation(event.reservation);
      emit(ReservationCreated(reservation));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onUpdateReservationStatus(
    UpdateReservationStatus event,
    Emitter<ReservationState> emit,
  ) async {
    emit(const ReservationLoading());
    try {
      final reservation = await _reservationRepository.updateReservationStatus(
        event.reservationId,
        event.status,
        reason: event.reason,
      );
      emit(ReservationStatusUpdated(reservation));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onCancelReservation(
    CancelReservation event,
    Emitter<ReservationState> emit,
  ) async {
    emit(const ReservationLoading());
    try {
      await _reservationRepository.cancelReservation(
        event.reservationId,
        reason: event.reason,
      );
      emit(ReservationCancelled(event.reservationId));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }
}
