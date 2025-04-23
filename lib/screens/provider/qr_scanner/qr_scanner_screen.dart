import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_app/screens/provider/qr_scanner/reservation_details_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/reservation.dart';


class QRScannerScreen extends StatefulWidget {
  final String providerId;

  const QRScannerScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;
  bool _isFlashOn = false;
  String? _scannedCode;
  late ReservationBloc _reservationBloc;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _reservationBloc = getIt<ReservationBloc>();
    
    // Setup animation for scanning effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && _isScanning) {
        setState(() {
          _isScanning = false;
          _scannedCode = barcode.rawValue;
        });
        
        // Provide haptic feedback
        _vibrateOnScan();
        
        // Process the scanned code
        _processScannedCode(_scannedCode!);
        
        // Stop scanning
        _scannerController.stop();
        break;
      }
    }
  }

  Future<void> _vibrateOnScan() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  void _processScannedCode(String code) {
    // Check if the code is a valid reservation ID
    if (code.startsWith('RES_')) {
      // It's a reservation ID, load the reservation details
      _reservationBloc.add(LoadActivityReservations(code.substring(4)));
    } else if (code.startsWith('USR_')) {
      // It's a user ID, load all reservations for this user with this provider
      _reservationBloc.add(LoadUserReservations(code.substring(4)));
    } else {
      // Invalid QR code
      _showErrorDialog('Invalid QR Code', 'The scanned code is not a valid reservation or user code.');
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _scannedCode = null;
    });
    _scannerController.start();
  }

  void _toggleFlash() async {
    await _scannerController.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reservationBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Client QR Code'),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
              tooltip: 'Toggle Flash',
            ),
          ],
        ),
        body: BlocListener<ReservationBloc, ReservationState>(
          listener: (context, state) {
            if (state is ReservationError) {
              _showErrorDialog('Error', state.message);
            }
          },
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Scanner
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),
                    
                    // Scanning overlay
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: MediaQuery.of(context).size.height * 0.2 + 
                                (_animationController.value * MediaQuery.of(context).size.height * 0.3),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    
                    // Scanner frame
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Top-left corner
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.2 - 20,
                            left: MediaQuery.of(context).size.width * 0.1 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                  left: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Top-right corner
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.2 - 20,
                            right: MediaQuery.of(context).size.width * 0.1 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                  right: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-left corner
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.5 - 20,
                            left: MediaQuery.of(context).size.width * 0.1 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                  left: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-right corner
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.5 - 20,
                            right: MediaQuery.of(context).size.width * 0.1 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                  right: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Loading overlay when not scanning
                    if (!_isScanning)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: BlocBuilder<ReservationBloc, ReservationState>(
                    builder: (context, state) {
                      if (state is ActivityReservationsLoaded && state.reservations.isNotEmpty) {
                        // Show the first reservation (should be only one for a specific ID)
                        return _buildReservationDetails(state.reservations.first);
                      } else if (state is UserReservationsLoaded) {
                        return _buildUserReservationsList(state.reservations);
                      } else if (state is ReservationLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading reservation details...'),
                            ],
                          ),
                        );
                      } else {
                        return _buildScanInstructions();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: !_isScanning
            ? FloatingActionButton(
                onPressed: _resetScanner,
                child: const Icon(Icons.refresh),
              )
            : null,
      ),
    );
  }

  Widget _buildScanInstructions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.qr_code_scanner,
          size: 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan a client\'s QR code to verify their reservation',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Position the QR code within the frame',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildReservationDetails(Reservation reservation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reservation Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ReservationDetailsCard(
                  reservation: reservation,
                  showActions: true,
                  onCheckIn: reservation.isConfirmed ? () {
                    _reservationBloc.add(UpdateReservationStatus(
                      reservation.id, 
                      ReservationStatus.completed
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Client checked in successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Future.delayed(const Duration(seconds: 2), _resetScanner);
                  } : null,
                  onConfirm: reservation.canConfirm ? () {
                    _reservationBloc.add(UpdateReservationStatus(
                      reservation.id, 
                      ReservationStatus.confirmed
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reservation confirmed!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    Future.delayed(const Duration(seconds: 2), _resetScanner);
                  } : null,
                  onReject: reservation.canReject ? () {
                    _showRejectDialog(reservation.id);
                  } : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRejectDialog(String reservationId) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this reservation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _reservationBloc.add(UpdateReservationStatus(
                reservationId, 
                ReservationStatus.rejected,
                reason: reasonController.text,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservation rejected'),
                  backgroundColor: Colors.red,
                ),
              );
              Future.delayed(const Duration(seconds: 2), _resetScanner);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserReservationsList(List<Reservation> reservations) {
    if (reservations.isEmpty) {
      return const Center(
        child: Text(
          'No reservations found for this client',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${reservations.length} Reservations Found',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    reservation.activity?.name ?? 'Reservation #${reservation.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Date: ${reservation.date.toString().substring(0, 10)} - ${reservation.timeSlot}',
                  ),
                  trailing: reservation.isCompleted
                      ? const Chip(
                          label: Text('Completed'),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : reservation.isConfirmed
                          ? ElevatedButton(
                              onPressed: () {
                                _reservationBloc.add(UpdateReservationStatus(
                                  reservation.id, 
                                  ReservationStatus.completed
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Client checked in successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Check In'),
                            )
                          : Chip(
                              label: Text(reservation.status.toString().split('.').last),
                              backgroundColor: _getStatusColor(reservation.status),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                  onTap: () {
                    // Show full reservation details
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) => SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ReservationDetailsCard(
                              reservation: reservation,
                              showActions: true,
                              onCheckIn: reservation.isConfirmed ? () {
                                Navigator.pop(context);
                                _reservationBloc.add(UpdateReservationStatus(
                                  reservation.id, 
                                  ReservationStatus.completed
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Client checked in successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } : null,
                              onConfirm: reservation.canConfirm ? () {
                                Navigator.pop(context);
                                _reservationBloc.add(UpdateReservationStatus(
                                  reservation.id, 
                                  ReservationStatus.confirmed
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reservation confirmed!'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } : null,
                              onReject: reservation.canReject ? () {
                                Navigator.pop(context);
                                _showRejectDialog(reservation.id);
                              } : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.blue;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
      case ReservationStatus.rejected:
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }
}
