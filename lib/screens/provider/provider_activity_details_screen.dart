import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_event.dart';
import 'package:flutter_activity_app/bloc/provider/provider_state.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/screens/provider/activity_form_screen.dart';
import 'package:flutter_activity_app/screens/provider/availability_management_screen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ProviderActivityDetailsScreen extends StatefulWidget {
  final Activity activity;
  final String providerId;

  const ProviderActivityDetailsScreen({
    Key? key,
    required this.activity,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderActivityDetailsScreen> createState() => _ProviderActivityDetailsScreenState();
}

class _ProviderActivityDetailsScreenState extends State<ProviderActivityDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProviderBloc _providerBloc;
  late ReservationBloc _reservationBloc;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _providerBloc = getIt<ProviderBloc>();
    _reservationBloc = getIt<ReservationBloc>();
    
    _reservationBloc.add(LoadActivityReservations(widget.activity.id!));
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _providerBloc),
        BlocProvider.value(value: _reservationBloc),
      ],
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.activity.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.activity.image,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityFormScreen(
                            providerId: widget.providerId,
                            activity: widget.activity,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Edit Activity',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmationDialog();
                      } else if (value == 'availability') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvailabilityManagementScreen(
                              activity: widget.activity,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'availability',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text('Manage Availability'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Activity', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Calendar'),
                      Tab(text: 'Reservations'),
                    ],
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildCalendarTab(),
              _buildReservationsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildDescriptionSection(),
          const SizedBox(height: 24),
          _buildDetailsSection(),
          const SizedBox(height: 24),
          _buildTagsSection(),
          const SizedBox(height: 24),
          _buildStatsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$${widget.activity.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    widget.activity.duration,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capacity',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${widget.activity.reviews} people',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.activity.description,
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          icon: Icons.category,
          title: 'Category',
          value: widget.activity.category,
        ),
        const Divider(),
        _buildDetailItem(
          icon: Icons.location_on,
          title: 'Location',
          value: widget.activity.location,
        ),
        const Divider(),
        _buildDetailItem(
          icon: Icons.star,
          title: 'Rating',
          value: '${widget.activity.rating} (${widget.activity.reviews} reviews)',
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.activity.tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        int totalReservations = 0;
        int confirmedReservations = 0;
        int pendingReservations = 0;
        double totalRevenue = 0;
        
        if (state is ActivityReservationsLoaded) {
          totalReservations = state.reservations.length;
          confirmedReservations = state.reservations
              .where((r) => r.status == ReservationStatus.confirmed || r.status == ReservationStatus.completed)
              .length;
          pendingReservations = state.reservations
              .where((r) => r.status == ReservationStatus.pending)
              .length;
          totalRevenue = state.reservations
              .where((r) => r.status == ReservationStatus.confirmed || r.status == ReservationStatus.completed)
              .fold(0, (sum, r) => sum + r.totalPrice);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            title: 'Total Reservations',
                            value: totalReservations.toString(),
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            title: 'Confirmed',
                            value: confirmedReservations.toString(),
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            title: 'Pending',
                            value: pendingReservations.toString(),
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            title: 'Total Revenue',
                            value: '\$${totalRevenue.toStringAsFixed(2)}',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCalendarTab() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        // Create a map of dates to reservation counts
        final Map<DateTime, int> reservationCounts = {};
        
        if (state is ActivityReservationsLoaded) {
          for (final reservation in state.reservations) {
            final date = DateTime(
              reservation.date.year,
              reservation.date.month,
              reservation.date.day,
            );
            
            reservationCounts[date] = (reservationCounts[date] ?? 0) + 1;
          }
        }
        
        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final count = reservationCounts[DateTime(date.year, date.month, date.day)] ?? 0;
                  if (count > 0) {
                    return Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedDay != null) _buildSelectedDayReservations(),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDayReservations() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        if (state is ActivityReservationsLoaded) {
          final selectedDayReservations = state.reservations.where((reservation) {
            return isSameDay(reservation.date, _selectedDay!);
          }).toList();
          
          if (selectedDayReservations.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reservations for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Reservations for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedDayReservations.length,
                    itemBuilder: (context, index) {
                      final reservation = selectedDayReservations[index];
                      return _buildReservationCard(reservation);
                    },
                  ),
                ),
              ],
            ),
          );
        }
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildReservationsTab() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        if (state is ActivityReservationsLoaded) {
          if (state.reservations.isEmpty) {
            return Center(
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
                    'No reservations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When customers book your activity, reservations will appear here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          // Group reservations by status
          final pendingReservations = state.reservations
              .where((r) => r.status == ReservationStatus.pending)
              .toList();
          
          final confirmedReservations = state.reservations
              .where((r) => r.status == ReservationStatus.confirmed)
              .toList();
          
          final pastReservations = state.reservations
              .where((r) => 
                r.status == ReservationStatus.completed || 
                r.status == ReservationStatus.cancelled || 
                r.status == ReservationStatus.rejected
              )
              .toList();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendingReservations.isNotEmpty) ...[
                const Text(
                  'Pending Reservations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...pendingReservations.map((r) => _buildReservationCard(r)),
                const SizedBox(height: 24),
              ],
              
              if (confirmedReservations.isNotEmpty) ...[
                const Text(
                  'Confirmed Reservations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...confirmedReservations.map((r) => _buildReservationCard(r)),
                const SizedBox(height: 24),
              ],
              
              if (pastReservations.isNotEmpty) ...[
                const Text(
                  'Past Reservations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...pastReservations.map((r) => _buildReservationCard(r)),
              ],
            ],
          );
        }
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final statusColor = reservation.status == ReservationStatus.confirmed ? Colors.green :
                        reservation.status == ReservationStatus.pending ? Colors.orange :
                        reservation.status == ReservationStatus.cancelled ? Colors.red :
                        reservation.status == ReservationStatus.rejected ? Colors.red :
                        Colors.blue;
    
    final statusText = reservation.status.toString().split('.').last.toUpperCase();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation #${reservation.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(reservation.timeSlot),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${reservation.numberOfPeople} ${reservation.numberOfPeople > 1 ? 'people' : 'person'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('\$${reservation.totalPrice.toStringAsFixed(2)}'),
              ],
            ),
            if (reservation.notes != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notes: ${reservation.notes}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
            if (reservation.cancellationReason != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${reservation.cancellationReason}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
            if (reservation.status == ReservationStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectionDialog(reservation.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmReservation(reservation.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmReservation(String reservationId) {
    _reservationBloc.add(UpdateReservationStatus(
      reservationId,
      ReservationStatus.confirmed,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reservation confirmed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRejectionDialog(String reservationId) {
    final TextEditingController reasonController = TextEditingController();
    
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _providerBloc.add(DeleteActivity(widget.activity.id!));
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity deleted'),
                  backgroundColor: Colors.red,
                ),
              );
              
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
