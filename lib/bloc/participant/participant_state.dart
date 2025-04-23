import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/participant.dart';

abstract class ParticipantState extends Equatable {
  const ParticipantState();

  @override
  List<Object?> get props => [];
}

class ParticipantInitial extends ParticipantState {
  const ParticipantInitial();
}

class ParticipantLoading extends ParticipantState {
  const ParticipantLoading();
}

class ParticipantsLoaded extends ParticipantState {
  final List<Participant> participants;
  final int confirmedCount;
  final int pendingCount;

  const ParticipantsLoaded({
    required this.participants,
    required this.confirmedCount,
    required this.pendingCount,
  });

  @override
  List<Object?> get props => [participants, confirmedCount, pendingCount];

  ParticipantsLoaded copyWith({
    List<Participant>? participants,
    int? confirmedCount,
    int? pendingCount,
  }) {
    return ParticipantsLoaded(
      participants: participants ?? this.participants,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}

class ParticipantJoined extends ParticipantState {
  final Participant participant;

  const ParticipantJoined(this.participant);

  @override
  List<Object?> get props => [participant];
}

class ParticipantLeft extends ParticipantState {
  final String activityId;
  final String userId;

  const ParticipantLeft(this.activityId, this.userId);

  @override
  List<Object?> get props => [activityId, userId];
}

class ParticipantStatusUpdated extends ParticipantState {
  final String participantId;
  final ParticipantStatus status;

  const ParticipantStatusUpdated(this.participantId, this.status);

  @override
  List<Object?> get props => [participantId, status];
}

class ParticipantError extends ParticipantState {
  final String message;

  const ParticipantError(this.message);

  @override
  List<Object?> get props => [message];
}