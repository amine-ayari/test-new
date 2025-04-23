// lib/blocs/chat/chat_state.dart
import 'package:equatable/equatable.dart';
import '../../models/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isProcessing;

  const ChatLoaded({
    required this.messages,
    this.isProcessing = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object> get props => [messages, isProcessing];
}

class ChatFailure extends ChatState {
  final String message;

  const ChatFailure(this.message);

  @override
  List<Object> get props => [message];
}