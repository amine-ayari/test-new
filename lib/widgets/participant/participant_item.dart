
// TODO Implement this library.



import 'package:flutter/material.dart';
import 'package:flutter_activity_app/models/participant.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class ParticipantItem extends StatelessWidget {
  final Participant participant;
  final bool isCurrentUser;

  const ParticipantItem({
    Key? key,
    required this.participant,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(participant.avatarUrl),
            radius: 24,
          ),
          if (participant.isHost)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.black : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            participant.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Vous',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
          if (participant.isHost) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Hôte',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'A rejoint ${timeago.format(participant.joinDate, locale: 'fr')}',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          if (participant.status == ParticipantStatus.pending)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'En attente de confirmation',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCurrentUser)
            IconButton(
              icon: const Icon(Icons.message_outlined, size: 20),
              onPressed: () {
                // Message participant
              },
              color: AppTheme.primaryColor,
            ),
          if (!isCurrentUser)
            IconButton(
              icon: const Icon(Icons.person_add_outlined, size: 20),
              onPressed: () {
                // Add as friend
              },
              color: Colors.blue,
            ),
        ],
      ),
    );
  }
}