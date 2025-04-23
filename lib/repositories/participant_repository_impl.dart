import 'package:flutter_activity_app/models/participant.dart';
import 'package:flutter_activity_app/repositories/participant_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:flutter_activity_app/models/user.dart';

class ParticipantRepositoryImpl implements ParticipantRepository {
  final ApiService _apiService;

  ParticipantRepositoryImpl(this._apiService);

  @override
  Future<List<Participant>> getParticipantsForActivity(String activityId) async {
    try {
      final response = await _apiService.get('/activities/$activityId/participants');
      return (response as List).map((json) => Participant.fromJson(json)).toList();
    } catch (e) {
      // For demo purposes, return mock data if API fails
      return _getMockParticipants(activityId);
    }
  }

  @override
  Future<Participant> joinActivity(String activityId, String userId) async {
    try {
      final response = await _apiService.postWithAuth(
        '/activities/$activityId/join',
        {'userId': userId},
      );
      return Participant.fromJson(response);
    } catch (e) {
      // For demo purposes, return a mock participant
      return _createMockParticipant(activityId, userId);
    }
  }

  @override
  Future<void> leaveActivity(String activityId, String userId) async {
    try {
      await _apiService.postWithAuth(
        '/activities/$activityId/leave',
        {'userId': userId},
      );
    } catch (e) {
      // Handle error silently for demo
      print('Error leaving activity: $e');
    }
  }

  @override
  Future<void> updateParticipantStatus(String participantId, ParticipantStatus status) async {
    try {
      await _apiService.put(
        '/participants/$participantId/status',
        {'status': status.toString().split('.').last},
      );
    } catch (e) {
      // Handle error silently for demo
      print('Error updating participant status: $e');
    }
  }

  // Mock data for demo purposes
  List<Participant> _getMockParticipants(String activityId) {
    return [
      Participant(
        id: '1',
        userId: '1',
        activityId: activityId,
        name: 'Sophie Martin',
        avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        joinDate: DateTime.now().subtract(const Duration(days: 5)),
        status: ParticipantStatus.confirmed,
      ),
      Participant(
        id: '2',
        userId: '2',
        activityId: activityId,
        name: 'Thomas Dubois',
        avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        joinDate: DateTime.now().subtract(const Duration(days: 3)),
        status: ParticipantStatus.confirmed,
      ),
      Participant(
        id: '3',
        userId: '3',
        activityId: activityId,
        name: 'Emma Bernard',
        avatarUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
        joinDate: DateTime.now().subtract(const Duration(days: 1)),
        status: ParticipantStatus.pending,
      ),
      Participant(
        id: '4',
        userId: '4',
        activityId: activityId,
        name: 'Lucas Petit',
        avatarUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
        joinDate: DateTime.now().subtract(const Duration(hours: 12)),
        status: ParticipantStatus.pending,
      ),
    ];
  }

  Participant _createMockParticipant(String activityId, String userId) {
    return Participant(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      activityId: activityId,
      name: 'Current User',
      avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      joinDate: DateTime.now(),
      status: ParticipantStatus.pending,
    );
  }
}