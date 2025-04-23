// TODO Implement this library.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/participant/participant_bloc.dart';
import 'package:flutter_activity_app/bloc/participant/participant_event.dart';
import 'package:flutter_activity_app/bloc/participant/participant_state.dart';
import 'package:flutter_activity_app/models/participant.dart';
import 'package:flutter_activity_app/widgets/participant/participant_item.dart';
import 'package:flutter_activity_app/config/app_theme.dart';

class ParticipantList extends StatelessWidget {
  final String activityId;
  final String currentUserId;
  final int? capacity;

  const ParticipantList({
    Key? key,
    required this.activityId,
    required this.currentUserId,
    this.capacity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticipantBloc, ParticipantState>(
      builder: (context, state) {
        if (state is ParticipantLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is ParticipantsLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildParticipantHeader(context, state),
              const SizedBox(height: 16),
              if (state.participants.isEmpty)
                _buildEmptyParticipants(context)
              else
                _buildParticipantsList(context, state.participants),
            ],
          );
        } else if (state is ParticipantError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildParticipantHeader(BuildContext context, ParticipantsLoaded state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUserParticipating = state.participants.any((p) => p.userId == currentUserId);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants (${state.confirmedCount})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            if (capacity != null)
              Text(
                '$capacity places au total',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
          ],
        ),
        if (!isUserParticipating)
          ElevatedButton.icon(
            onPressed: () {
              context.read<ParticipantBloc>().add(JoinActivity(activityId, currentUserId));
            },
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Rejoindre'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () {
              context.read<ParticipantBloc>().add(LeaveActivity(activityId, currentUserId));
            },
            icon: const Icon(Icons.exit_to_app_outlined, size: 16),
            label: const Text('Quitter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyParticipants(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun participant pour le moment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à rejoindre cette activité !',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ParticipantBloc>().add(JoinActivity(activityId, currentUserId));
            },
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Rejoindre l\'activité'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(BuildContext context, List<Participant> participants) {
    // Sort participants: hosts first, then confirmed, then pending
    final sortedParticipants = [...participants];
    sortedParticipants.sort((a, b) {
      if (a.isHost && !b.isHost) return -1;
      if (!a.isHost && b.isHost) return 1;
      if (a.status == ParticipantStatus.confirmed && b.status != ParticipantStatus.confirmed) return -1;
      if (a.status != ParticipantStatus.confirmed && b.status == ParticipantStatus.confirmed) return 1;
      return a.joinDate.compareTo(b.joinDate);
    });
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedParticipants.length,
      itemBuilder: (context, index) {
        final participant = sortedParticipants[index];
        return ParticipantItem(
          participant: participant,
          isCurrentUser: participant.userId == currentUserId,
        );
      },
    );
  }
}