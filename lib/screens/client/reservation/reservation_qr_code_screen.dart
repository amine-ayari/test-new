import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ReservationQRCodeScreen extends StatelessWidget {
  final Reservation reservation;

  const ReservationQRCodeScreen({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = 'RES_${reservation.id}';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation QR Code'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        reservation.activity?.name ?? 'Activity Reservation',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(reservation.date),
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        reservation.timeSlot,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (context, error) {
                            return const Center(
                              child: Text(
                                'Something went wrong!',
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Reservation #${reservation.id.substring(0, 8)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusChip(theme),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        'People',
                        '${reservation.numberOfPeople} ${reservation.numberOfPeople > 1 ? 'persons' : 'person'}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        'Total Price',
                        '€${reservation.totalPrice.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Present this QR code to the activity provider for check-in',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _shareQRCode(context, qrData),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _copyReservationId(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy ID'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _shareQRCode(BuildContext context, String qrData) async {
    try {
      // Create QR code image
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      
      final imageSize = 200.0;
      final imageBuffer = await qrPainter.toImageData(imageSize);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(imageBuffer!.buffer.asUint8List());
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My reservation for ${reservation.activity?.name ?? "Activity"} on ${DateFormat('MMM d, y').format(reservation.date)} at ${reservation.timeSlot}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing QR code: $e')),
      );
    }
  }

  void _copyReservationId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: reservation.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation ID copied to clipboard')),
    );
  }
}
// TODO Implement this library.