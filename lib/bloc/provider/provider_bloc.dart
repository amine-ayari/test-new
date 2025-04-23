import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_event.dart';
import 'package:flutter_activity_app/bloc/provider/provider_state.dart';
import 'package:flutter_activity_app/repositories/provider_repository.dart';

class ProviderBloc extends Bloc<ProviderEvent, ProviderState> {
  final ProviderRepository _providerRepository;

  ProviderBloc(this._providerRepository) : super(const ProviderInitial()) {
    on<LoadProviderActivities>(_onLoadProviderActivities);
    on<CreateActivity>(_onCreateActivity);
    on<UpdateActivity>(_onUpdateActivity);
    on<DeleteActivity>(_onDeleteActivity);
    on<UpdateAvailability>(_onUpdateAvailability);
  }

  Future<void> _onLoadProviderActivities(
    LoadProviderActivities event,
    Emitter<ProviderState> emit,
  ) async {
    emit(const ProviderLoading());
    try {
      final activities = await _providerRepository.getProviderActivities(event.providerId);
      emit(ProviderActivitiesLoaded(activities));
    } catch (e) {
      emit(ProviderError(e.toString()));
    }
  }

  Future<void> _onCreateActivity(
    CreateActivity event,
    Emitter<ProviderState> emit,
  ) async {
    emit(const ProviderLoading());
    try {
      final activity = await _providerRepository.createActivity(event.activity);
      emit(ActivityCreated(activity));
    } catch (e) {
      emit(ProviderError(e.toString()));
    }
  }

  Future<void> _onUpdateActivity(
    UpdateActivity event,
    Emitter<ProviderState> emit,
  ) async {
    emit(const ProviderLoading());
    try {
      final activity = await _providerRepository.updateActivity(event.activity);
      emit(ActivityUpdated(activity));
    } catch (e) {
      emit(ProviderError(e.toString()));
    }
  }

  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ProviderState> emit,
  ) async {
    emit(const ProviderLoading());
    try {
      await _providerRepository.deleteActivity(event.activityId);
      emit(ActivityDeleted(event.activityId));
    } catch (e) {
      emit(ProviderError(e.toString()));
    }
  }

  Future<void> _onUpdateAvailability(
    UpdateAvailability event,
    Emitter<ProviderState> emit,
  ) async {
    emit(const ProviderLoading());
    try {
      await _providerRepository.updateAvailability(
        event.activityId,
        event.dates,
        event.times,
      );
      emit(AvailabilityUpdated(event.activityId, event.dates, event.times));
    } catch (e) {
      emit(ProviderError(e.toString()));
    }
  }
}
