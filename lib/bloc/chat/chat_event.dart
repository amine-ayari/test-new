// lib/blocs/chat/chat_event.dart
import 'package:equatable/equatable.dart';
import '../../models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatMessageSent extends ChatEvent {
  final String content;

  const ChatMessageSent(this.content);

  @override
  List<Object> get props => [content];
}

class ChatHistoryRequested extends ChatEvent {}

class ChatMessageReceived extends ChatEvent {
  final ChatMessage message;

  const ChatMessageReceived(this.message);

  @override
  List<Object> get props => [message];
}