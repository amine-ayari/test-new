import 'package:equatable/equatable.dart';

class Participant extends Equatable {
  final String id;
  final String userId;
  final String activityId;
  final String name;
  final String avatarUrl;
  final DateTime joinDate;
  final ParticipantStatus status;
  final bool isHost;

  const Participant({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.name,
    required this.avatarUrl,
    required this.joinDate,
    this.status = ParticipantStatus.confirmed,
    this.isHost = false,
  });

  @override
  List<Object?> get props => [
    id, userId, activityId, name, avatarUrl, joinDate, status, isHost
  ];

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      activityId: json['activityId'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      joinDate: json['joinDate'] != null 
          ? DateTime.parse(json['joinDate']) 
          : DateTime.now(),
      status: _parseStatus(json['status']),
      isHost: json['isHost'] ?? false,
    );
  }

  static ParticipantStatus _parseStatus(String? statusStr) {
    switch (statusStr?.toLowerCase()) {
      case 'pending':
        return ParticipantStatus.pending;
      case 'cancelled':
        return ParticipantStatus.cancelled;
      case 'confirmed':
      default:
        return ParticipantStatus.confirmed;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'name': name,
      'avatarUrl': avatarUrl,
      'joinDate': joinDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'isHost': isHost,
    };
  }

  Participant copyWith({
    String? id,
    String? userId,
    String? activityId,
    String? name,
    String? avatarUrl,
    DateTime? joinDate,
    ParticipantStatus? status,
    bool? isHost,
  }) {
    return Participant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      isHost: isHost ?? this.isHost,
    );
  }
}

enum ParticipantStatus {
  pending,
  confirmed,
  cancelled
}