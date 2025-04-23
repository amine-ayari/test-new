import 'package:flutter/material.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:intl/intl.dart';

class ReservationDetailsCard extends StatelessWidget {
  final Reservation reservation;
  final bool showActions;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;

  const ReservationDetailsCard({
    Key? key,
    required this.reservation,
    this.showActions = false,
    this.onCheckIn,
    this.onCancel,
    this.onConfirm,
    this.onReject,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activityName = reservation.activity?.name ?? 'Activity Details';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation #${reservation.id.substring(0, 8)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(theme),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Activity',
              activityName,
              Icons.hiking,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Date',
              DateFormat('EEEE, MMMM d, y').format(reservation.date),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Time',
              reservation.timeSlot,
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'People',
              '${reservation.numberOfPeople} ${reservation.numberOfPeople > 1 ? 'persons' : 'person'}',
              Icons.people,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Total Price',
              '€${reservation.totalPrice.toStringAsFixed(2)}',
              Icons.euro,
            ),
            if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Notes',
                reservation.notes!,
                Icons.note,
              ),
            ],
            if (reservation.cancellationReason != null && reservation.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Cancellation Reason',
                reservation.cancellationReason!,
                Icons.cancel,
                isError: true,
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color chipColor;
    String statusText;

    switch (reservation.status) {
      case ReservationStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case ReservationStatus.confirmed:
        chipColor = Colors.blue;
        statusText = 'Confirmed';
        break;
      case ReservationStatus.completed:
        chipColor = Colors.green;
        statusText = 'Completed';
        break;
      case ReservationStatus.cancelled:
        chipColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case ReservationStatus.rejected:
        chipColor = Colors.red.shade800;
        statusText = 'Rejected';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    {bool isError = false}
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isError 
                ? Colors.red.withOpacity(0.1) 
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isError 
                ? Colors.red 
                : Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isError ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final List<Widget> buttons = [];
    
    // Check which actions are available based on reservation status
    if (reservation.isConfirmed && onCheckIn != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCheckIn,
            icon: const Icon(Icons.check_circle),
            label: const Text('Check In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    if (reservation.canConfirm && onConfirm != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    if (reservation.canComplete && onComplete != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.task_alt),
            label: const Text('Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    if (reservation.canReject && onReject != null) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.block),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade800,
              side: BorderSide(color: Colors.red.shade800),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    if (reservation.canCancel && onCancel != null) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    // If no buttons, return empty container
    if (buttons.isEmpty) {
      return Container();
    }
    
    // If only one button, return it
    if (buttons.length == 1) {
      return buttons.first;
    }
    
    // If two buttons, return them in a row
    return Row(
      children: [
        buttons[0],
        const SizedBox(width: 12),
        buttons[1],
      ],
    );
  }
}
