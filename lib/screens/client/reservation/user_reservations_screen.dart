import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/widgets/network_error_widget.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class UserReservationsScreen extends StatefulWidget {
  final String userId;

  const UserReservationsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserReservationsScreen> createState() => _UserReservationsScreenState();
}

class _UserReservationsScreenState extends State<UserReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReservationBloc _reservationBloc;
  // Liste locale des réservations pour mise à jour immédiate
  List<Reservation> _localReservations = [];
  bool _isRefreshing = false;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _reservationBloc = getIt<ReservationBloc>();
    _loadReservations();
  }

  void _loadReservations() {
    _reservationBloc.add(LoadUserReservations(widget.userId));
  }

  Future<void> _refreshReservations() async {
    setState(() {
      _isRefreshing = true;
    });

    _loadReservations();

    // Simuler un délai pour montrer l'animation de rafraîchissement
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});

      // Feedback tactile lors du changement d'onglet
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reservationBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Reservations'),
          elevation: 0,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshReservations,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: BlocConsumer<ReservationBloc, ReservationState>(
                listener: (context, state) {
                  // Mettre à jour la liste locale lorsque les réservations sont chargées
                  if (state is UserReservationsLoaded) {
                    setState(() {
                      _localReservations = List.from(state.reservations);
                    });
                  }

                  // Mettre à jour la liste locale lorsqu'une réservation est annulée
                  if (state is ReservationCancelled) {
                    setState(() {
                      _localReservations
                          .removeWhere((r) => r.id == state.reservationId);
                    });

                    // Afficher un snackbar pour confirmer l'annulation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Reservation cancelled successfully'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {},
                        ),
                      ),
                    );
                  }

                  // Gérer l'état de paiement réussi
                  if (state is PaymentSuccessful) {
                    setState(() {
                      _isProcessingPayment = false;
                      // Mettre à jour le statut de paiement dans la liste locale
                      _localReservations = _localReservations.map((r) {
                        if (r.id == state.reservationId) {
                          return r.copyWith(paymentStatus: 'paid');
                        }
                        return r;
                      }).toList();
                    });

                    // Afficher un snackbar pour confirmer le paiement
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Payment successful!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'View Invoice',
                          textColor: Colors.white,
                          onPressed: () {
                            final reservation = _localReservations.firstWhere(
                              (r) => r.id == state.reservationId,
                              orElse: () => _localReservations.first,
                            );
                            _showInvoice(reservation);
                          },
                        ),
                      ),
                    );
                  }

                  // Gérer l'état d'échec de paiement
                  if (state is PaymentFailed) {
                    setState(() {
                      _isProcessingPayment = false;
                    });

                    // Afficher un snackbar pour l'échec du paiement
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment failed: ${state.error}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ReservationLoading &&
                      _localReservations.isEmpty &&
                      !_isRefreshing) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading your reservations...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (_localReservations.isNotEmpty) {
                    // Utiliser la liste locale pour l'affichage
                    return _buildReservationTabs(_localReservations);
                  } else if (state is ReservationError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshReservations,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return _buildEmptyState();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: [
          Tab(
            text: 'All',
            icon: Icon(
              Icons.list_alt,
              color: _tabController.index == 0
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
          ),
          Tab(
            text: 'Upcoming',
            icon: Icon(
              Icons.event_available,
              color: _tabController.index == 1
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
          ),
          Tab(
            text: 'Past',
            icon: Icon(
              Icons.history,
              color: _tabController.index == 2
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
          ),
          Tab(
            text: 'Cancelled',
            icon: Icon(
              Icons.cancel,
              color: _tabController.index == 3
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshReservations,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No reservations found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Your reservation history will appear here. Pull down to refresh.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Find Activities'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationTabs(List<Reservation> reservations) {
    final now = DateTime.now();

    final upcomingReservations = reservations
        .where((r) =>
            r.date.isAfter(now) &&
            (r.status == ReservationStatus.pending ||
                r.status == ReservationStatus.confirmed))
        .toList();

    final pastReservations = reservations
        .where((r) =>
            r.date.isBefore(now) &&
            (r.status == ReservationStatus.confirmed ||
                r.status == ReservationStatus.completed))
        .toList();

    final cancelledReservations = reservations
        .where((r) =>
            r.status == ReservationStatus.cancelled ||
            r.status == ReservationStatus.rejected)
        .toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildReservationList(reservations, 'all'),
        _buildReservationList(upcomingReservations, 'upcoming'),
        _buildReservationList(pastReservations, 'past'),
        _buildReservationList(cancelledReservations, 'cancelled'),
      ],
    );
  }

  Widget _buildReservationList(List<Reservation> reservations, String type) {
    if (reservations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshReservations,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == 'all'
                          ? Icons.list_alt
                          : type == 'upcoming'
                              ? Icons.event_available
                              : type == 'past'
                                  ? Icons.history
                                  : Icons.cancel,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == 'all'
                          ? 'No reservations found'
                          : type == 'upcoming'
                              ? 'No upcoming reservations'
                              : type == 'past'
                                  ? 'No past reservations'
                                  : 'No cancelled reservations',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        type == 'all'
                            ? 'Make your first reservation!'
                            : type == 'upcoming'
                                ? 'Book an activity to see upcoming reservations'
                                : type == 'past'
                                    ? 'Your completed activities will appear here'
                                    : 'Cancelled reservations will appear here',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildReservationCard(reservation, type);
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation, String type) {
    final statusColor = reservation.status == ReservationStatus.confirmed
        ? Colors.green
        : reservation.status == ReservationStatus.pending
            ? Colors.orange
            : reservation.status == ReservationStatus.cancelled
                ? Colors.red
                : reservation.status == ReservationStatus.rejected
                    ? Colors.red
                    : Colors.blue;

    final statusText =
        reservation.status.toString().split('.').last.toUpperCase();

    // Récupérer le nom de l'activité
    final activityName = reservation.activityName ?? 'Unknown Activity';

    // Vérifier si la réservation est confirmée et non payée
    final isConfirmedNotPaid =
        reservation.status == ReservationStatus.confirmed &&
            reservation.paymentStatus != 'paid';

    // Vérifier si la réservation est payée
    final isPaid = reservation.paymentStatus == 'paid';

    return Dismissible(
      key: Key(reservation.id),
      direction: (type == 'all' || type == 'upcoming') && reservation.canCancel
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel,
              color: Colors.white,
            ),
            SizedBox(height: 4),
            Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && reservation.canCancel) {
          return await _showCancellationDialog(reservation);
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme. primaryLightColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      activityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      // Badge de paiement si payé
                      if (isPaid)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'PAID',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Badge de statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Reservation #${reservation.id.substring(0, 6)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(reservation.date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        reservation.timeSlot ?? 'No time slot available',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${reservation.numberOfPeople} ${reservation.numberOfPeople > 1 ? 'people' : 'person'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '\$${reservation.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Afficher le statut de paiement
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reservation.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Afficher les notes seulement si elles existent
                  if (reservation.notes != null &&
                      reservation.notes.isNotEmpty &&
                      reservation.notes != 'No notes available')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.note,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reservation.notes,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Afficher la raison d'annulation seulement si elle existe et que la réservation est annulée
                  if ((reservation.status == ReservationStatus.cancelled ||
                          reservation.status == ReservationStatus.rejected) &&
                      reservation.cancellationReason != null &&
                      reservation.cancellationReason.isNotEmpty &&
                      reservation.cancellationReason !=
                          'No cancellation reason')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reservation.cancellationReason,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Afficher le QR code si la réservation est payée
                  if (isPaid)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Column(
                          children: [
                            const Text(
                              'Ticket QR Code',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: 'RESERVATION:${reservation.id}',
                                version: QrVersions.auto,
                                size: 120.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showInvoice(reservation),
                                  icon: const Icon(Icons.receipt),
                                  label: const Text('View Invoice'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: BorderSide(
                                        color: AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Boutons d'action en bas de la carte
            if ((type == 'all' || type == 'upcoming'))
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey, width: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Bouton de paiement pour les réservations confirmées non payées
                    if (isConfirmedNotPaid)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessingPayment
                              ? null
                              : () => _showPaymentDialog(reservation),
                          icon: _isProcessingPayment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.payment),
                          label: Text(_isProcessingPayment
                              ? 'Processing...'
                              : 'Pay Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            disabledBackgroundColor:
                                AppTheme.primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ),

                    // Bouton d'annulation si la réservation peut être annulée
                    if (reservation.canCancel)
                      Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(left: isConfirmedNotPaid ? 8 : 0),
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showCancellationDialog(reservation),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showCancellationDialog(Reservation reservation) async {
    final TextEditingController reasonController = TextEditingController();
    bool shouldCancel = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this reservation?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Please provide a reason for cancellation',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              shouldCancel = false;
            },
            child: const Text('No, Keep It'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              shouldCancel = true;

              // Mettre à jour localement avant d'envoyer au backend
              setState(() {
                // Option 1: Supprimer la réservation de la liste locale
                _localReservations.removeWhere((r) => r.id == reservation.id);
              });

              // Envoyer l'événement au bloc
              _reservationBloc.add(CancelReservation(
                reservation.id,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              ));
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Yes, Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    return shouldCancel;
  }

  // Nouvelle méthode pour afficher la boîte de dialogue de paiement
  Future<void> _showPaymentDialog(Reservation reservation) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete your payment to confirm your reservation.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Activity:'),
                        Text(
                          reservation.activityName ?? 'Unknown Activity',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date:'),
                        Text(
                          DateFormat('MMM d, y').format(reservation.date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('People:'),
                        Text(
                          '${reservation.numberOfPeople}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${reservation.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Simuler un formulaire de paiement
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Credit Card'),
                    const Spacer(),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isProcessingPayment = false;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Simuler un traitement de paiement
                Future.delayed(const Duration(seconds: 2), () {
                  // Mettre à jour localement
                  setState(() {
                    _localReservations = _localReservations.map((r) {
                      if (r.id == reservation.id) {
                        return r.copyWith(paymentStatus: 'paid');
                      }
                      return r;
                    }).toList();
                    _isProcessingPayment = false;
                  });

                  // Envoyer l'événement au bloc
                  _reservationBloc.add(ProcessPayment(reservation.id));

                  // Afficher la facture
                  _showInvoice(reservation);
                });
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  // Nouvelle méthode pour afficher la facture
  Future<void> _showInvoice(Reservation reservation) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Invoice'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INVOICE',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Invoice #${reservation.id.substring(0, 6)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Date: ${DateFormat('MMM d, y').format(DateTime.now())}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Activity Provider:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Activity App Inc.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Text('123 Activity Street'),
                              const Text('Adventure City, AC 12345'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'John Doe',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('customer@example.com'),
                              const Text('+1 234 567 8900'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'RESERVATION DETAILS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                        },
                        border: TableBorder.symmetric(
                          inside:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Description',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Qty',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Price',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reservation.activityName ?? 'Activity',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Date: ${DateFormat('MMM d, y').format(reservation.date)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (reservation.timeSlot != null)
                                      Text(
                                        'Time: ${reservation.timeSlot}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${reservation.numberOfPeople}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '\$${(reservation.totalPrice / reservation.numberOfPeople).toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '\$${reservation.totalPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Subtotal:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '\$${reservation.totalPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Tax (0%):',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  '\$0.00',
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'TOTAL:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '\$${reservation.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Ticket QR Code',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          QrImageView(
                            data: 'RESERVATION:${reservation.id}',
                            version: QrVersions.auto,
                            size: 150.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reservation ID: ${reservation.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Thank you for your business!',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateAndSharePDF(reservation);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour générer et partager le PDF de la facture
  Future<void> _generateAndSharePDF(Reservation reservation) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice #${reservation.id.substring(0, 6)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('MMM d, y').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(height: 24),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Activity Provider:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Activity App Inc.',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('123 Activity Street'),
                        pw.Text('Adventure City, AC 12345'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Customer:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'John Doe',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('customer@example.com'),
                        pw.Text('+1 234 567 8900'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'RESERVATION DETAILS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          'Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              reservation.activityName ?? 'Activity',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'Date: ${DateFormat('MMM d, y').format(reservation.date)}',
                              style: const pw.TextStyle(
                                fontSize: 10,
                              ),
                            ),
                            if (reservation.timeSlot != null)
                              pw.Text(
                                'Time: ${reservation.timeSlot}',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          '${reservation.numberOfPeople}',
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          '\$${(reservation.totalPrice / reservation.numberOfPeople).toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          '\$${reservation.totalPrice.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Subtotal:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Text(
                            '\$${reservation.totalPrice.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Tax (0%):',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Text(
                            '\$0.00',
                            textAlign: pw.TextAlign.right,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'TOTAL:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(width: 16),
                            pw.Text(
                              '\$${reservation.totalPrice.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'We appreciate your business!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.blue, // Example of changing text color
                    fontSize: 14, // Example of changing font size
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Enregistrer le PDF
    final output = await getTemporaryDirectory();
    final file =
        File('${output.path}/invoice_${reservation.id.substring(0, 6)}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Partager le PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice for your reservation',
      subject: 'Reservation Invoice #${reservation.id.substring(0, 6)}',
    );
  }
}

// Ajouter ces événements au bloc de réservation
class ProcessPayment extends ReservationEvent {
  final String reservationId;

  const ProcessPayment(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

// Ajouter ces états au bloc de réservation
class PaymentSuccessful extends ReservationState {
  final String reservationId;

  const PaymentSuccessful(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

class PaymentFailed extends ReservationState {
  final String reservationId;
  final String error;

  const PaymentFailed(this.reservationId, this.error);

  @override
  List<Object?> get props => [reservationId, error];
}
