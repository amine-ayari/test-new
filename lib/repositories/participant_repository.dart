// TODO Implement this library.import 'package:flutter_activity_app/models/participant.dart';

import 'package:flutter_activity_app/models/participant.dart';

import 'package:flutter_activity_app/models/participant.dart';

abstract class ParticipantRepository {
  Future<List<Participant>> getParticipantsForActivity(String activityId);
  Future<Participant> joinActivity(String activityId, String userId);
  Future<void> leaveActivity(String activityId, String userId);
  Future<void> updateParticipantStatus(String participantId, ParticipantStatus status);
}