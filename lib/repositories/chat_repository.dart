// lib/repositories/chat_repository.dart
import 'dart:convert';
import 'package:flutter_activity_app/config/app_config.dart';

import 'package:flutter_activity_app/repositories/auth_repository.dart';

import 'package:flutter_activity_app/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/activity.dart';

class ChatRepository {
  final http.Client _httpClient = http.Client();
  final AuthRepository _authRepository;
  final _uuid = const Uuid();

  ChatRepository(this._authRepository);

  // Send message to chatbot
  Future<ChatMessage> sendMessage(String content) async {
    final tokens = await ApiService.getAccessToken();
    if (tokens == null) {
      throw Exception('Not authenticated');
    }

    final accessToken = await ApiService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await _httpClient.post(
      Uri.parse('${AppConfig.apiBaseUrl}/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if response contains recommended activities
      if (data['type'] == 'activity' && data['activities'] != null) {
        final List<Activity> activities =
            (data['activities'] as List)
                .map((activityJson) => Activity.fromJson(activityJson))
                .toList();

        return ChatMessage(
          id: _uuid.v4(),
          content: data['content'],
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.activity,
          activities: activities,
        );
      }

      return ChatMessage(
        id: _uuid.v4(),
        content: data['content'],
        isUser: false,
        timestamp: DateTime.now(),
      );
    } else {
      throw Exception('Failed to send message');
    }
  }

  // Get chat history
  Future<List<ChatMessage>> getChatHistory() async {
    final accessToken = await ApiService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    final response = await _httpClient.get(
      Uri.parse('${AppConfig.apiBaseUrl}/chat/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chat history');
    }
  }

  Future<ChatMessage> simulateResponse(String userMessage) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));

  // Create user message
  final userMessageObj = ChatMessage(
    id: _uuid.v4(),
    content: userMessage,
    isUser: true,
    timestamp: DateTime.now(),
  );

  // Analyze user message for appropriate response
  String botResponse;
  MessageType messageType = MessageType.text;
  List<Activity>? activities;

  final lowerCaseMessage = userMessage.toLowerCase();

  // If the message contains a greeting
  if (lowerCaseMessage.contains('hello') ||
      lowerCaseMessage.contains('hi') ||
      lowerCaseMessage.contains('hey')) {
    botResponse = 'Hello! How can I help you today?';
  } 
  // If the message asks for activities or suggestions
  else if (lowerCaseMessage.contains('activity') ||
           lowerCaseMessage.contains('do') ||
           lowerCaseMessage.contains('suggestion')) {
    botResponse = 'Here are some activities you might enjoy:';
    messageType = MessageType.activity;

    // Create simulated activities
    } 
  // If the message contains restaurant-related keywords
  else if (lowerCaseMessage.contains('restaurant') ||
           lowerCaseMessage.contains('eat') ||
           lowerCaseMessage.contains('food')) {
    botResponse = 'I recommend these restaurants nearby:';
    messageType = MessageType.activity;

   
      
  } else {
    botResponse = 'I\'m your virtual assistant. I can help you find activities, restaurants, or answer your questions about the area. Feel free to ask me anything!';
    activities = [];
  }

  // Create bot response with activities
  return ChatMessage(
    id: _uuid.v4(),
    content: botResponse,
    isUser: false,
    timestamp: DateTime.now().add(const Duration(seconds: 1)),
    type: messageType,
    activities: activities,
  );
}
}
