import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_event.dart';
import 'package:flutter_activity_app/bloc/provider/provider_state.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/bloc/notification/notification_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/screens/provider/activity_form_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_activity_details_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_reservations_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_notification_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final String providerId;

  const ProviderDashboardScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  late ProviderBloc _providerBloc;
  late ReservationBloc _reservationBloc;
  late NotificationBloc _notificationBloc;
  
  @override
  void initState() {
    super.initState();
    _providerBloc = getIt<ProviderBloc>();
    _reservationBloc = getIt<ReservationBloc>();
    _notificationBloc = getIt<NotificationBloc>();
    
    _providerBloc.add(LoadProviderActivities(widget.providerId));
    _reservationBloc.add(LoadProviderReservations(widget.providerId));
    _notificationBloc.add(LoadNotifications(widget.providerId));
    
    // Connect to notification socket
    _notificationBloc.add(ConnectToNotificationSocket(
      userId: widget.providerId,
      userType: 'provider',
    ));
  }
  
  @override
  void dispose() {
    _notificationBloc.add(const DisconnectFromNotificationSocket());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _providerBloc),
        BlocProvider.value(value: _reservationBloc),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: Scaffold(
       /*  appBar: AppBar(
          title: const Text('Dashboard'),
          elevation: 0,
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                int unreadCount = 0;
                if (state is NotificationsLoaded) {
                  unreadCount = state.unreadCount;
                }
                
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderNotificationScreen(
                              providerId: widget.providerId,
                            ),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        */ body: RefreshIndicator(
          onRefresh: () async {
            _providerBloc.add(LoadProviderActivities(widget.providerId));
            _reservationBloc.add(LoadProviderReservations(widget.providerId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                _buildStatisticsCards(),
                const SizedBox(height: 24),
                _buildRevenueChart(),
                const SizedBox(height: 24),
                _buildRecentReservations(),
                const SizedBox(height: 24),
                _buildPopularActivities(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityFormScreen(providerId: widget.providerId),
              ),
            );
          },
          child: const Icon(Icons.add),
          tooltip: 'Add new activity',
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withBlue((AppTheme.primaryColor.b * 1.2).clamp(0, 255).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Here\'s what\'s happening with your activities today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'New Activity',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityFormScreen(providerId: widget.providerId),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.calendar_today,
                  label: 'Reservations',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderReservationsScreen(providerId: widget.providerId),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  onTap: () {
                    // Navigate to analytics screen
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, reservationState) {
        if (reservationState is ReservationLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (reservationState is ReservationError) {
          return Center(
            child: Text(
              'Erreur lors du chargement des réservations: ${reservationState.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        int totalReservations = 0;
        int pendingReservations = 0;
        double totalRevenue = 0;
        
        if (reservationState is ProviderReservationsLoaded) {
          totalReservations = reservationState.reservations.length;
          pendingReservations = reservationState.reservations
              .where((r) => r.status == ReservationStatus.pending)
              .length;
          totalRevenue = reservationState.reservations
              .where((r) => r.status == ReservationStatus.confirmed || r.status == ReservationStatus.completed)
              .fold(0, (sum, r) => sum + r.totalPrice);
        }
        
        return BlocBuilder<ProviderBloc, ProviderState>(
          builder: (context, providerState) {
            int totalActivities = 0;
            
            if (providerState is ProviderActivitiesLoaded) {
              totalActivities = providerState.activities.length;
            }
            
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Activities',
                    value: totalActivities.toString(),
                    icon: Icons.hiking,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Reservations',
                    value: totalReservations.toString(),
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending',
                    value: pendingReservations.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Revenue',
                    value: '\$${totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        if (state is ProviderReservationsLoaded) {
          // Amélioration du calcul des revenus mensuels
          final Map<int, double> monthlyRevenue = {};
          
          for (final reservation in state.reservations.where((r) => 
              r.status == ReservationStatus.confirmed || 
              r.status == ReservationStatus.completed)) {
            final month = reservation.date.month;
            monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + reservation.totalPrice;
          }
          
          final List<FlSpot> spots = List.generate(12, (index) => 
            FlSpot((index + 1).toDouble(), monthlyRevenue[index + 1] ?? 0)
          );
          
          // Calcul dynamique de la valeur maximale Y
          final maxRevenue = monthlyRevenue.values.isEmpty ? 
            5000.0 : 
            (monthlyRevenue.values.reduce((max, value) => max > value ? max : value) * 1.2);

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aperçu des Revenus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1000,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                if (value.toInt() % 2 == 0 && value.toInt() > 0 && value.toInt() <= 12) {
                                  return Text(months[value.toInt()]);
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) {
                                  return const Text('\$0');
                                } else if (value == 1000) {
                                  return const Text('\$1K');
                                } else if (value == 2000) {
                                  return const Text('\$2K');
                                } else if (value == 3000) {
                                  return const Text('\$3K');
                                } else if (value == 4000) {
                                  return const Text('\$4K');
                                } else if (value == 5000) {
                                  return const Text('\$5K');
                                }
                                return const Text('');
                              },
                              reservedSize: 40,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        minX: 1,
                        maxX: 12,
                        minY: 0,
                        maxY: maxRevenue,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryColor.withOpacity(0.1),
                            ),
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
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecentReservations() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        if (state is ProviderReservationsLoaded) {
          // Sort reservations by date (most recent first)
          final reservations = List<Reservation>.from(state.reservations)
            ..sort((a, b) => b.date.compareTo(a.date));
          
          // Take only the 5 most recent reservations
          final recentReservations = reservations.take(5).toList();
          
          return Card(
            elevation: 2,
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
                      const Text(
                        'Recent Reservations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderReservationsScreen(providerId: widget.providerId),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recentReservations.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No reservations yet'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentReservations.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final reservation = recentReservations[index];
                        return _buildReservationItem(reservation);
                      },
                    ),
                ],
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReservationItem(Reservation reservation) {
    final statusColor = reservation.status == ReservationStatus.confirmed ? Colors.green :
                        reservation.status == ReservationStatus.pending ? Colors.orange :
                        reservation.status == ReservationStatus.cancelled ? Colors.red :
                        reservation.status == ReservationStatus.rejected ? Colors.red :
                        Colors.blue;
    
    final statusText = reservation.status.toString().split('.').last.toUpperCase();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.calendar_today,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservation #${reservation.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(reservation.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
          const SizedBox(width: 12),
          Text(
            '\$${reservation.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularActivities() {
    return BlocBuilder<ProviderBloc, ProviderState>(
      builder: (context, state) {
        if (state is ProviderActivitiesLoaded) {
          // Sort activities by rating (highest first)
          final activities = List<Activity>.from(state.activities)
            ..sort((a, b) => b.rating.compareTo(a.rating));
          
          // Take only the 3 highest rated activities
          final popularActivities = activities.take(3).toList();
          
          return Card(
            elevation: 2,
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
                      const Text(
                        'Popular Activities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to activities screen
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (popularActivities.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No activities yet'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: popularActivities.length,
                      itemBuilder: (context, index) {
                        final activity = popularActivities[index];
                        return _buildPopularActivityItem(activity);
                      },
                    ),
                ],
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPopularActivityItem(Activity activity) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderActivityDetailsScreen(
              activity: activity,
              providerId: widget.providerId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                activity.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${activity.reviews})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '\$${activity.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
