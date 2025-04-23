// lib/blocs/chat/chat_bloc.dart
import 'package:flutter_activity_app/models/chat_message.dart';
import 'package:flutter_activity_app/repositories/chat_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';


import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final _uuid = const Uuid();

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<ChatMessageSent>(_onChatMessageSent);
    on<ChatHistoryRequested>(_onChatHistoryRequested);
    on<ChatMessageReceived>(_onChatMessageReceived);
    
  }

  Future<void> _onChatMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    // Create user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: event.content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Update state with user message
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(
        messages: [...currentState.messages, userMessage],
        isProcessing: true,
      ));
    } else {
      emit(ChatLoaded(
        messages: [userMessage],
        isProcessing: true,
      ));
    }

    try {
      // Get bot response
      final botResponse = await _chatRepository.simulateResponse(event.content);

      // Update state with bot response
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(
          messages: [...currentState.messages, botResponse],
          isProcessing: false,
        ));
      }
    } catch (e) {
      // In case of error, add error message
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Sorry, I couldn\'t process your request. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(
          messages: [...currentState.messages, errorMessage],
          isProcessing: false,
        ));
      } else {
        emit(ChatFailure(e.toString()));
      }
    }
  }

  Future<void> _onChatHistoryRequested(
    ChatHistoryRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final messages = await _chatRepository.getChatHistory();
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      // If error fetching history, start with welcome message
      final welcomeMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Hello! I\'m your virtual assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      );
      emit(ChatLoaded(messages: [welcomeMessage]));
    }
  }

  void _onChatMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(
        messages: [...currentState.messages, event.message],
      ));
    } else {
      emit(ChatLoaded(messages: [event.message]));
    }
  }
}