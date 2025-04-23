import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/widgets/network_error_widget.dart';
import 'package:intl/intl.dart';

class ProviderReservationsScreen extends StatefulWidget {
  final String providerId;

  const ProviderReservationsScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderReservationsScreen> createState() => _ProviderReservationsScreenState();
}

class _ProviderReservationsScreenState extends State<ProviderReservationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReservationBloc _reservationBloc;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _reservationBloc = getIt<ReservationBloc>();
    _loadReservations();
    
    // Écouter les changements d'état pour recharger automatiquement
    _reservationBloc.stream.listen((state) {
      if (state is ReservationStatusUpdated) {
        // Recharger les réservations après une mise à jour de statut
        _loadReservations();
      }
    });
  }
  
  void _loadReservations() {
    _reservationBloc.add(LoadProviderReservations(widget.providerId));
  }
  
  Future<void> _refreshReservations() async {
    setState(() {
      _isRefreshing = true;
    });
    
    _loadReservations();
    
    // Simuler un délai pour montrer l'animation de rafraîchissement
    await Future.delayed(const Duration(milliseconds: 1500));
    
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return BlocProvider.value(
      value: _reservationBloc,
      child: Column(
        children: [
          // Tab bar (previously in AppBar.bottom)
          Container(
          // Utiliser la couleur primaire du thème actuel au lieu d'une couleur fixe
          color: theme.primaryColor,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: 'Pending',
                icon: Icon(
                  Icons.pending_actions,
                  color: _tabController.index == 0 ? Colors.white : Colors.white70,
                  size: 20,
                ),
              ),
              Tab(
                text: 'Confirmed',
                icon: Icon(
                  Icons.event_available,
                  color: _tabController.index == 1 ? Colors.white : Colors.white70,
                  size: 20,
                ),
              ),
              Tab(
                text: 'Past/Cancelled',
                icon: Icon(
                  Icons.history,
                  color: _tabController.index == 2 ? Colors.white : Colors.white70,
                  size: 20,
                ),
              ),
            ],
            // Utiliser des couleurs qui s'adaptent au thème
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
          // Content area
          Expanded(
            child: BlocBuilder<ReservationBloc, ReservationState>(
              builder: (context, state) {
                if (state is ReservationLoading && !_isRefreshing) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading reservations...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is ProviderReservationsLoaded) {
                  return _buildReservationTabs(state.reservations);
                } else if (state is ReservationError) {
                  return RefreshIndicator(
                    onRefresh: _refreshReservations,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: NetworkErrorWidget(
                            message: 'Could not load reservations',
                            onRetry: _loadReservations,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return RefreshIndicator(
                    onRefresh: _refreshReservations,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: const Center(child: Text('No reservations found')),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationTabs(List<Reservation> reservations) {
    final now = DateTime.now();
    
    final pendingReservations = reservations.where((r) => 
      r.status == ReservationStatus.pending
    ).toList();
    
    final confirmedReservations = reservations.where((r) => 
      r.status == ReservationStatus.confirmed && r.date.isAfter(now)
    ).toList();
    
    final pastOrCancelledReservations = reservations.where((r) => 
      r.date.isBefore(now) || 
      r.status == ReservationStatus.cancelled || 
      r.status == ReservationStatus.rejected ||
      r.status == ReservationStatus.completed
    ).toList();
    
    return TabBarView(
      controller: _tabController,
      children: [
        _buildReservationList(pendingReservations, 'pending'),
        _buildReservationList(confirmedReservations, 'confirmed'),
        _buildReservationList(pastOrCancelledReservations, 'past'),
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
                      type == 'pending' ? Icons.pending_actions : 
                      type == 'confirmed' ? Icons.event_available : Icons.history,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == 'pending' ? 'No pending reservations' : 
                      type == 'confirmed' ? 'No confirmed reservations' : 'No past or cancelled reservations',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Pull down to refresh',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final statusColor = reservation.status == ReservationStatus.confirmed ? Colors.green :
                        reservation.status == ReservationStatus.pending ? Colors.orange :
                        reservation.status == ReservationStatus.cancelled ? Colors.red :
                        reservation.status == ReservationStatus.rejected ? Colors.red :
                        Colors.blue;
    
    final statusText = reservation.status.toString().split('.').last.toUpperCase();
    
    // Récupérer le nom de l'activité
    final activityName = reservation.activityName ?? 'Unknown Activity';
    
    // Récupérer le nom du client
    final clientName = reservation.userName ?? 'Unknown Client';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Feedback tactile
          HapticFeedback.selectionClick();
          
          // Afficher les détails de la réservation
          _showReservationDetails(reservation, type);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode 
                  ? theme.cardColor.withOpacity(0.5) 
                  : theme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Client: $clientName',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Reservation #${reservation.id.substring(0, 8)}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
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
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
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
                      Text('${reservation.numberOfPeople} ${reservation.numberOfPeople > 1 ? 'people' : 'person'}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '\$${reservation.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(reservation.paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatPaymentStatus(reservation.paymentStatus),
                          style: TextStyle(
                            color: _getPaymentStatusColor(reservation.paymentStatus),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reservation.notes != null && reservation.notes!.isNotEmpty && reservation.notes != 'No notes available') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? Colors.grey[800]!.withOpacity(0.3) 
                          : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reservation.notes!,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (reservation.cancellationReason != null && 
                      reservation.cancellationReason!.isNotEmpty && 
                      reservation.cancellationReason != 'No cancellation reason') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reservation.cancellationReason!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (type == 'pending')
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateReservationStatus(
                          reservation,
                          ReservationStatus.rejected,
                        ),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateReservationStatus(
                          reservation,
                          ReservationStatus.confirmed,
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
      case 'upcoming':
        return Colors.orange;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'PAID';
      case 'pending':
        return 'PENDING';
      case 'upcoming':
        return 'UPCOMING';
      case 'refunded':
        return 'REFUNDED';
      default:
        return status.toUpperCase();
    }
  }

  void _showReservationDetails(Reservation reservation, String type) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final statusColor = reservation.status == ReservationStatus.confirmed ? Colors.green :
                        reservation.status == ReservationStatus.pending ? Colors.orange :
                        reservation.status == ReservationStatus.cancelled ? Colors.red :
                        reservation.status == ReservationStatus.rejected ? Colors.red :
                        Colors.blue;
    
    final statusText = reservation.status.toString().split('.').last.toUpperCase();
    
    // Récupérer le nom de l'activité
    final activityName = reservation.activityName ?? 'Unknown Activity';
    
    // Récupérer le nom du client
    final clientName = reservation.userName ?? 'Unknown Client';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reservation Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                
                // Activity Name
                _buildDetailItem(
                  icon: Icons.event,
                  title: 'Activity',
                  value: activityName,
                  isBold: true,
                ),
                
                // Client Name
                _buildDetailItem(
                  icon: Icons.person,
                  title: 'Client',
                  value: clientName,
                  isBold: true,
                ),
                
                // Reservation ID
                _buildDetailItem(
                  icon: Icons.confirmation_number,
                  title: 'Reservation ID',
                  value: '#${reservation.id}',
                ),
                
                // Date
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: DateFormat('EEEE, MMMM d, y').format(reservation.date),
                ),
                
                // Time
                _buildDetailItem(
                  icon: Icons.access_time,
                  title: 'Time',
                  value: reservation.timeSlot ?? 'No time slot available',
                ),
                
                // Number of People
                _buildDetailItem(
                  icon: Icons.people,
                  title: 'Number of People',
                  value: '${reservation.numberOfPeople} ${reservation.numberOfPeople > 1 ? 'people' : 'person'}',
                ),
                
                // Price
                _buildDetailItem(
                  icon: Icons.attach_money,
                  title: 'Total Price',
                  value: '\$${reservation.totalPrice.toStringAsFixed(2)}',
                  valueColor: Colors.green,
                ),
                
                // Payment Status
                _buildDetailItem(
                  icon: Icons.payment,
                  title: 'Payment Status',
                  value: _formatPaymentStatus(reservation.paymentStatus),
                  valueColor: _getPaymentStatusColor(reservation.paymentStatus),
                ),
                
                // Created At
                _buildDetailItem(
                  icon: Icons.access_time,
                  title: 'Booked On',
                  value: DateFormat('MMMM d, y - h:mm a').format(reservation.createdAt),
                ),
                
                // Notes
                if (reservation.notes != null && reservation.notes!.isNotEmpty && reservation.notes != 'No notes available')
                  _buildDetailItem(
                    icon: Icons.note,
                    title: 'Notes',
                    value: reservation.notes!,
                    isMultiline: true,
                  ),
                
                // Cancellation Reason
                if ((reservation.status == ReservationStatus.cancelled || 
                    reservation.status == ReservationStatus.rejected) &&
                    reservation.cancellationReason != null && 
                    reservation.cancellationReason!.isNotEmpty &&
                    reservation.cancellationReason != 'No cancellation reason')
                  _buildDetailItem(
                    icon: Icons.info,
                    title: 'Cancellation Reason',
                    value: reservation.cancellationReason!,
                    valueColor: Colors.red,
                    isMultiline: true,
                  ),
                
                const SizedBox(height: 20),
                
                // Actions
                if (type == 'pending')
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateReservationStatus(
                              reservation,
                              ReservationStatus.confirmed,
                            );
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirm Reservation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateReservationStatus(
                              reservation,
                              ReservationStatus.rejected,
                            );
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Reject Reservation'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: valueColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateReservationStatus(Reservation reservation, ReservationStatus status) {
    if (status == ReservationStatus.rejected) {
      _showRejectionDialog(reservation);
    } else {
      _reservationBloc.add(UpdateReservationStatus(reservation.id, status));
      
      // Afficher un snackbar pour confirmer la mise à jour
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation ${status == ReservationStatus.confirmed ? 'confirmed' : 'updated'} successfully'),
          backgroundColor: status == ReservationStatus.confirmed ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _showRejectionDialog(Reservation reservation) {
    final TextEditingController reasonController = TextEditingController();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to reject this reservation?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'Please provide a reason for rejection',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reservationBloc.add(UpdateReservationStatus(
                reservation.id,
                ReservationStatus.rejected,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : 'Rejected by provider',
              ));
              
              // Afficher un snackbar pour confirmer le rejet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservation rejected successfully'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
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
}
