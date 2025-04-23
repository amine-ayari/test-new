// TODO Implement this library.import 'package:equatable/equatable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/participant.dart';

abstract class ParticipantEvent extends Equatable {
  const ParticipantEvent();

  @override
  List<Object?> get props => [];
}

class LoadParticipants extends ParticipantEvent {
  final String activityId;

  const LoadParticipants(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class JoinActivity extends ParticipantEvent {
  final String activityId;
  final String userId;

  const JoinActivity(this.activityId, this.userId);

  @override
  List<Object?> get props => [activityId, userId];
}

class LeaveActivity extends ParticipantEvent {
  final String activityId;
  final String userId;

  const LeaveActivity(this.activityId, this.userId);

  @override
  List<Object?> get props => [activityId, userId];
}

class UpdateParticipantStatus extends ParticipantEvent {
  final String participantId;
  final ParticipantStatus status;

  const UpdateParticipantStatus(this.participantId, this.status);

  @override
  List<Object?> get props => [participantId, status];
}