import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/participant/participant_event.dart';
import 'package:flutter_activity_app/bloc/participant/participant_state.dart';
import 'package:flutter_activity_app/repositories/participant_repository.dart';
import 'package:flutter_activity_app/models/participant.dart';

class ParticipantBloc extends Bloc<ParticipantEvent, ParticipantState> {
  final ParticipantRepository _participantRepository;

  ParticipantBloc(this._participantRepository) : super(const ParticipantInitial()) {
    on<LoadParticipants>(_onLoadParticipants);
    on<JoinActivity>(_onJoinActivity);
    on<LeaveActivity>(_onLeaveActivity);
    on<UpdateParticipantStatus>(_onUpdateParticipantStatus);
  }

  Future<void> _onLoadParticipants(
    LoadParticipants event,
    Emitter<ParticipantState> emit,
  ) async {
    emit(const ParticipantLoading());
    try {
      final participants = await _participantRepository.getParticipantsForActivity(event.activityId);
      
      // Count confirmed and pending participants
      final confirmedCount = participants.where((p) => p.status == ParticipantStatus.confirmed).length;
      final pendingCount = participants.where((p) => p.status == ParticipantStatus.pending).length;
      
      emit(ParticipantsLoaded(
        participants: participants,
        confirmedCount: confirmedCount,
        pendingCount: pendingCount,
      ));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onJoinActivity(
    JoinActivity event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      final participant = await _participantRepository.joinActivity(event.activityId, event.userId);
      emit(ParticipantJoined(participant));
      
      // Reload participants to update the list
      add(LoadParticipants(event.activityId));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onLeaveActivity(
    LeaveActivity event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      await _participantRepository.leaveActivity(event.activityId, event.userId);
      emit(ParticipantLeft(event.activityId, event.userId));
      
      // Reload participants to update the list
      add(LoadParticipants(event.activityId));
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }

  Future<void> _onUpdateParticipantStatus(
    UpdateParticipantStatus event,
    Emitter<ParticipantState> emit,
  ) async {
    try {
      await _participantRepository.updateParticipantStatus(event.participantId, event.status);
      emit(ParticipantStatusUpdated(event.participantId, event.status));
      
      // If we're in the loaded state, we need to update the participant in the list
      if (state is ParticipantsLoaded) {
        final currentState = state as ParticipantsLoaded;
        final updatedParticipants = currentState.participants.map((participant) {
          if (participant.id == event.participantId) {
            return participant.copyWith(status: event.status);
          }
          return participant;
        }).toList();
        
        // Recalculate counts
        final confirmedCount = updatedParticipants.where((p) => p.status == ParticipantStatus.confirmed).length;
        final pendingCount = updatedParticipants.where((p) => p.status == ParticipantStatus.pending).length;
        
        emit(currentState.copyWith(
          participants: updatedParticipants,
          confirmedCount: confirmedCount,
          pendingCount: pendingCount,
        ));
      }
    } catch (e) {
      emit(ParticipantError(e.toString()));
    }
  }
}