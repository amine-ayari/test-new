import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/screens/client/chatbot/widgets/activity_card.dart';
import 'package:flutter_activity_app/screens/client/chatbot/widgets/chat_bubble.dart';
import 'package:flutter_activity_app/screens/client/chatbot/widgets/custom_button.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/chat/chat_bloc.dart';
import 'package:flutter_activity_app/bloc/chat/chat_event.dart';
import 'package:flutter_activity_app/bloc/chat/chat_state.dart';
import 'package:flutter_activity_app/models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  bool _showSuggestions = true;
  bool _isComposing = false;
  final List<String> _suggestions = [
    'Find adventure activities',
    'Recommend food experiences',
    'Activities under \$50',
    'Family-friendly activities'
  ];

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatHistoryRequested());

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeController.forward();
    _slideController.forward();

    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Send message
  void _sendMessage([String? text]) {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isNotEmpty) {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Animate send button
      _scaleController.forward().then((_) => _scaleController.reverse());

      context.read<ChatBloc>().add(ChatMessageSent(messageText));
      _messageController.clear();
      setState(() {
        _isComposing = false;
        _showSuggestions = false;
      });

      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _useSuggestion(String suggestion) {
    _sendMessage(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Hero(
              tag: 'assistant_avatar',
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assistant_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Activity Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Clear Chat'),
                  content: const Text(
                      'Are you sure you want to clear the chat history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        /*  context.read<ChatBloc>().add(ChatCleared()); */
                        Navigator.pop(context);
                        setState(() {
                          _showSuggestions = true;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildHelpSheet(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppTheme.primaryColor.withOpacity(0.05),
            ],
            stops: const [0.7, 1.0],
          ),
          image: DecorationImage(
            image: const AssetImage('assets/images/chat_bg_pattern.png'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Column(
          children: [
            // Messages area
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is ChatLoaded) {
                    // Scroll to bottom when new messages arrive
                    Future.delayed(
                        const Duration(milliseconds: 100), _scrollToBottom);
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return _buildLoadingView();
                  } else if (state is ChatLoaded) {
                    if (state.messages.isEmpty) {
                      return _buildEmptyChatView();
                    }

                    return FadeTransition(
                      opacity: _fadeController,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            state.messages.length + (_showSuggestions ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show suggestions at the end if enabled
                          if (_showSuggestions &&
                              index == state.messages.length) {
                            return _buildSuggestionChips();
                          }

                          final message = state.messages[index];
                          return _buildMessageItem(message, index);
                        },
                      ),
                    );
                  } else if (state is ChatFailure) {
                    return _buildErrorView(state.message);
                  } else {
                    return _buildEmptyChatView();
                  }
                },
              ),
            ),

            // Typing indicator
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoaded && state.isProcessing) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildTypingIndicator(),
                              const SizedBox(width: 8),
                              Text(
                                'Assistant is thinking...',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text field
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isComposing 
                                ? AppTheme.primaryColor.withOpacity(0.5) 
                                : Colors.grey.shade200,
                            width: _isComposing ? 1.5 : 1,
                          ),
                          boxShadow: _isComposing ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: AnimatedOpacity(
                              opacity: _isComposing ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.edit_rounded,
                                color: AppTheme.primaryColor.withOpacity(0.7),
                                size: 18,
                              ),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.mic_rounded,
                                    color: AppTheme.primaryColor.withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Voice input coming soon!'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).size.height * 0.1,
                                          left: 16,
                                          right: 16,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                AnimatedOpacity(
                                  opacity: _isComposing ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.attach_file_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Attachments coming soon!'),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.only(
                                            bottom: MediaQuery.of(context).size.height * 0.1,
                                            left: 16,
                                            right: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 5,
                          onChanged: (value) {
                            setState(() {
                              _isComposing = value.trim().isNotEmpty;
                            });
                          },
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Send button with animation
                    AnimatedBuilder(
                      animation: _scaleController,
                      builder: (context, child) {
                        final scale = 1.0 + _scaleController.value * 0.2;
                        return Transform.scale(
                          scale: scale,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _isComposing 
                                      ? AppTheme.primaryColor 
                                      : AppTheme.primaryColor.withOpacity(0.7),
                                  _isComposing
                                      ? AppTheme.primaryColor.withBlue(
                                          (AppTheme.primaryColor.blue * 1.2)
                                              .clamp(0, 255)
                                              .toInt(),
                                        )
                                      : AppTheme.primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(_isComposing ? 0.4 : 0.2),
                                  blurRadius: _isComposing ? 12 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: _sendMessage,
                                child: Center(
                                  child: Icon(
                                    _isComposing ? Icons.send_rounded : Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build loading view
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading conversation...',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will just take a moment',
            style: TextStyle(
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Build empty chat view
  Widget _buildEmptyChatView() {
    return Center(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.easeOut,
        )),
        child: FadeTransition(
          opacity: _fadeController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chat_rounded,
                          size: 60,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'Your Activity Assistant',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'I can help you discover activities, provide recommendations, and answer your questions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSuggestionChips(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build error view
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppTheme.errorColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: () {
                context.read<ChatBloc>().add(ChatHistoryRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build suggestion chips
  Widget _buildSuggestionChips() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutQuart,
      )),
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Try asking:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _suggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: ActionChip(
                          label: Text(
                            suggestion,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          avatar: const Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _useSuggestion(suggestion);
                          },
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Build message item
  Widget _buildMessageItem(ChatMessage message, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutQuart,
      )),
      child: FadeTransition(
        opacity: _fadeController,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: message.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Message bubble
              Row(
                mainAxisAlignment: message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar for bot messages
                  if (!message.isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8, top: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.assistant_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                  ],

                  // Message content
                  Flexible(
                    child: ChatBubble(
                      message: message.content,
                      isUser: message.isUser,
                      timestamp: message.timestamp,
                    ),
                  ),

                  // Avatar for user messages
                  if (message.isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),

              // Activities carousel
              if (message.type == MessageType.activity &&
                  message.activities != null &&
                  message.activities!.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: message.activities!.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        curve: Curves.easeOutQuint,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: 12,
                                  left: index == 0 ? 40 : 0,
                                ),
                                child: ActivityCard(
                                  activity: message.activities![index],
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    // Navigate to activity details
                                    Navigator.pushNamed(
                                      context,
                                      '/details',
                                      arguments: message.activities![index],
                                    );
                                  },
                                  onFavoriteToggle: (isFavorite) {
                                    HapticFeedback.lightImpact();
                                    // Handle favorite toggle
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isFavorite
                                              ? 'Added to favorites'
                                              : 'Removed from favorites',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).size.height * 0.1,
                                          left: 16,
                                          right: 16,
                                        ),
                                        action: SnackBarAction(
                                          label: 'View',
                                          onPressed: () {
                                            // Navigate to favorites
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Build typing indicator
  Widget _buildTypingIndicator() {
    return SizedBox(
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (index) => _buildPulsingDot(index),
        ),
      ),
    );
  }

  Widget _buildPulsingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 8 * value,
          width: 8 * value,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
      child: const SizedBox(),
    );
  }

  // Build help bottom sheet
  Widget _buildHelpSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'How can I help you?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHelpItem(
                      icon: Icons.search_rounded,
                      title: 'Find Activities',
                      description:
                          'Ask me to find activities based on your interests, location, or budget.',
                      examples: [
                        'Find adventure activities',
                        'Show me food experiences',
                        'Activities under \$50'
                      ],
                    ),
                    _buildHelpItem(
                      icon: Icons.recommend_rounded,
                      title: 'Get Recommendations',
                      description:
                          'I can recommend activities based on your preferences and past bookings.',
                      examples: [
                        'Recommend activities for me',
                        'What should I do this weekend?',
                        'Popular activities nearby'
                      ],
                    ),
                    _buildHelpItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Activity Details',
                      description:
                          'Ask about specific details of any activity.',
                      examples: [
                        'Tell me more about Mountain Hiking',
                        'Is this activity family-friendly?',
                        'What\'s included in this experience?'
                      ],
                    ),
                    _buildHelpItem(
                      icon: Icons.calendar_today_rounded,
                      title: 'Booking Help',
                      description:
                          'I can help you with booking activities and managing your reservations.',
                      examples: [
                        'Book this activity',
                        'Change my reservation',
                        'Cancel my booking'
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Got it',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build help item
  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
    required List<String> examples,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Examples:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: examples.map((example) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                      _sendMessage(example);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              example,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
