import 'package:flutter/material.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withBlue(
                    (AppTheme.primaryColor.blue * 1.2).clamp(0, 255).toInt(),
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUser ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: isUser 
                ? AppTheme.primaryColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUser ? Icons.check_circle_outline : Icons.access_time_rounded,
                size: 12,
                color: isUser ? Colors.white.withOpacity(0.7) : Colors.black38,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(timestamp),
                style: TextStyle(
                  color: isUser ? Colors.white.withOpacity(0.7) : Colors.black38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
