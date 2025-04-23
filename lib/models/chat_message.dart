// TODO Implement this library.
// lib/models/chat_message.dart
import 'package:equatable/equatable.dart';
import 'activity.dart';

enum MessageType { text, activity, location }

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final List<Activity>? activities;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.activities,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageType? type,
    List<Activity>? activities,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      activities: activities ?? this.activities,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'activities': activities?.map((a) => a.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      activities: json['activities'] != null
          ? (json['activities'] as List)
              .map((a) => Activity.fromJson(a))
              .toList()
          : null,
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        isUser,
        timestamp,
        type,
        activities,
        metadata,
      ];
}