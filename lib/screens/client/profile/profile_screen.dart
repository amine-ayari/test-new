import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/screens/client/favorites/favorites_screen.dart';
import 'package:flutter_activity_app/screens/client/profile/change_password_screen.dart';
import 'package:flutter_activity_app/screens/client/profile/notification_settings_screen.dart';
import 'package:flutter_activity_app/screens/client/profile/settings/help_support_screen.dart';
import 'package:flutter_activity_app/screens/client/reservation/user_reservations_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/auth/auth_state.dart';
import 'package:flutter_activity_app/bloc/user/user_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_event.dart';
import 'package:flutter_activity_app/bloc/user/user_state.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/providers/theme_provider.dart';
import 'package:flutter_activity_app/screens/auth/login_screen.dart';
import 'package:flutter_activity_app/screens/client/profile/edit_profile_screen.dart';

import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AuthBloc _authBloc;
  late UserBloc _userBloc;
  late ReservationBloc _reservationBloc;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  
  // Data for dynamic content
  List<Activity> _favoriteActivities = [];
  List<Reservation> _userReservations = [];
  bool _isLoadingFavorites = false;
  bool _isLoadingReservations = false;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _userBloc = getIt<UserBloc>();
    _reservationBloc = getIt<ReservationBloc>();
    _tabController = TabController(length: 2, vsync: this);
      

    
    // Listen to scroll to change AppBar appearance
    _scrollController.addListener(_onScroll);
    
    // Load dynamic data
    _loadFavoriteActivities();
    _loadUserReservations();
  }
  
  void _loadFavoriteActivities() {
    setState(() {
      _isLoadingFavorites = true;
    });
    
    _userBloc.add(LoadFavoriteActivities(widget.user.id));
  }
  
  void _loadUserReservations() {
    setState(() {
      _isLoadingReservations = true;
    });
    
    _reservationBloc.add(LoadUserReservations(widget.user.id));
  }
  
  void _onScroll() {
    if (_scrollController.offset > 180 && !_showTitle) {
      setState(() {
        _showTitle = true;
      });
    } else if (_scrollController.offset <= 180 && _showTitle) {
      setState(() {
        _showTitle = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _userBloc),
        BlocProvider.value(value: _reservationBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Unauthenticated) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
          BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              if (state is FavoritesLoaded) {
                setState(() {
                  _favoriteActivities = state.favorites;
                  _isLoadingFavorites = false;
                });
              } else if (state is UserError) {
                setState(() {
                  _loadingError = state.message;
                  _isLoadingFavorites = false;
                });
              }
            },
          ),
          BlocListener<ReservationBloc, ReservationState>(
            listener: (context, state) {
              if (state is UserReservationsLoaded) {
                setState(() {
                  _userReservations = state.reservations;
                  _isLoadingReservations = false;
                });
              } else if (state is ReservationError) {
                setState(() {
                  _loadingError = state.message;
                  _isLoadingReservations = false;
                });
              }
            },
          ),
        ],
        child: Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 220, // Slightly increased for better visual
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDarkMode 
                    ? theme.scaffoldBackgroundColor 
                    : AppTheme.primaryColor,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: _showTitle 
                      ? Text(
                          widget.user.name,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                    background: _buildProfileHeader(isDarkMode),
                    collapseMode: CollapseMode.parallax,
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit, 
                          color: isDarkMode ? Colors.white : Colors.white,
                          size: 18,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: widget.user),
                          ),
                        ).then((_) {
                          // Refresh screen after profile edit
                          setState(() {});
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings, 
                          color: isDarkMode ? Colors.white : Colors.white,
                          size: 18,
                        ),
                      ),
                      onPressed: () {
                        _showSettingsBottomSheet(context, isDarkMode);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.primaryColor,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'PROFILE'),
                        Tab(text: 'ACTIVITY'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(isDarkMode),
                _buildActivityTab(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background with overlay pattern
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryLightColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Pattern overlay
              Opacity(
                opacity: 0.1,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/pattern.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Gradient overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Profile content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 160,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile image with animated border
                Hero(
                  tag: 'profile-header-${widget.user.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: widget.user.profileImage != null
                          ? NetworkImage(widget.user.profileImage!)
                          : null,
                      child: widget.user.profileImage == null
                          ? Text(
                              widget.user.name.isNotEmpty
                                  ? widget.user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                ).animate()
                  .scale(delay: 100.ms, duration: 500.ms)
                  .then()
                  .shimmer(delay: 600.ms, duration: 1200.ms),
                
                const SizedBox(width: 20),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Color.fromARGB(150, 0, 0, 0),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2.0,
                              color: Color.fromARGB(100, 0, 0, 0),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                      
                      const SizedBox(height: 12),
                      
                      // Member since with icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Member since ${widget.user.birthDate != null ? _formatDate(widget.user.birthDate!) : 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadFavoriteActivities();
        _loadUserReservations();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityStats(),
            const SizedBox(height: 24),
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _buildProfileInfo(isDarkMode),
            const SizedBox(height: 24),
            _buildSectionTitle('Preferences'),
            const SizedBox(height: 12),
            _buildPreferencesCard(isDarkMode),
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadFavoriteActivities();
        _loadUserReservations();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Recent Bookings'),
            const SizedBox(height: 12),
            _buildRecentBookings(isDarkMode),
            const SizedBox(height: 24),
            _buildSectionTitle('Favorite Activities'),
            const SizedBox(height: 12),
            _buildFavoriteActivities(isDarkMode),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildActivityStats() {
    // Get dynamic counts
    final favoritesCount = _favoriteActivities.length;
    final bookingsCount = _userReservations.length;
    final completedCount = _userReservations.where((r) => 
      r.status == ReservationStatus.completed).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
              icon: Icons.calendar_today, 
              value: bookingsCount.toString(), 
              label: 'Bookings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserReservationsScreen(userId: widget.user.id),
                  ),
                );
              },
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.favorite, 
            value: favoritesCount.toString(),
            label: 'Favorites',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(user: widget.user),
                ),
              );
            },
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.history, 
            value: completedCount.toString(), 
            label: 'Completed',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserReservationsScreen(userId: widget.user.id),
                ),
              );
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatItem({
    required IconData icon, 
    required String value, 
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
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

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildProfileInfo(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isDarkMode
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[800]!,
                    Colors.grey[850]!,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                icon: Icons.phone,
                title: 'Phone',
                value: widget.user.phoneNumber ?? 'Not provided',
                isDarkMode: isDarkMode,
                isContact: true,
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.location_on,
                title: 'Address',
                value: widget.user.address ?? 'Not provided',
                isDarkMode: isDarkMode,
                showMap: widget.user.address != null,
              ),
              if (widget.user.birthDate != null) ...[
                const Divider(),
                _buildInfoRow(
                  icon: Icons.cake,
                  title: 'Birth Date',
                  value: _formatDate(widget.user.birthDate!),
                  isDarkMode: isDarkMode,
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 300.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPreferencesCard(bool isDarkMode) {
    final hasPreferences = _favoriteActivities.isNotEmpty;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isDarkMode
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[800]!,
                    Colors.grey[850]!,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                icon: Icons.favorite,
                title: 'Interests',
                value: hasPreferences 
                  ? '${_favoriteActivities.length} favorite activities'
                  : 'No interests specified',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavoritesScreen(user: widget.user),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.language,
                title: 'Language',
                value: 'English', // Default language
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildInfoRow(
                icon: Icons.notifications,
                title: 'Notification Preferences',
                value: 'Email, Push Notifications',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 350.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildRecentBookings(bool isDarkMode) {
    if (_isLoadingReservations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_userReservations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        message: 'No bookings yet',
        subMessage: 'Your booking history will appear here',
      );
    }
    
    // Sort reservations by date (most recent first)
    final sortedReservations = List<Reservation>.from(_userReservations)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Take only the most recent 3 reservations
    final recentReservations = sortedReservations.take(3).toList();
    
    return Column(
      children: [
        ...recentReservations.map((reservation) => _buildBookingCard(reservation, isDarkMode)).toList(),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserReservationsScreen(userId: widget.user.id),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text('View All Reservations'),
        ),
      ],
    );
  }
  
  Widget _buildBookingCard(Reservation reservation, bool isDarkMode) {
    final statusColor = reservation.status == ReservationStatus.confirmed 
        ? Colors.green 
        : reservation.status == ReservationStatus.pending 
            ? Colors.orange 
            : reservation.status == ReservationStatus.completed
                ? AppTheme.primaryColor
                : Colors.red;
            
    final statusText = reservation.status.toString().split('.').last.toUpperCase();
    
    // Get activity image (placeholder for now)
    final activityImage = 'https://res.cloudinary.com/dpl8pr4y7/image/upload/v1745336268/ufab63vrlt62wskfy8km.jpg';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to reservation details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserReservationsScreen(userId: widget.user.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image with status indicator
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      image: DecorationImage(
                        image: AssetImage(activityImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.activityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y').format(reservation.date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          reservation.timeSlot ?? 'No time slot',
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
  
  Widget _buildFavoriteActivities(bool isDarkMode) {
    if (_isLoadingFavorites) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_favoriteActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite,
        message: 'No favorites yet',
        subMessage: 'Your favorite activities will appear here',
      );
    }
    
    // Take only the first 4 favorites for the grid
    final displayFavorites = _favoriteActivities.take(4).toList();
    
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: displayFavorites.length,
          itemBuilder: (context, index) {
            final favorite = displayFavorites[index];
            return _buildFavoriteCard(favorite, isDarkMode, index);
          },
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FavoritesScreen(user: widget.user),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text('View All Favorites'),
        ),
      ],
    );
  }
  
  Widget _buildFavoriteCard(Activity activity, bool isDarkMode, int index) {
    // Get activity image (placeholder for now)
    final activityImage = activity.image ?? 'https://res.cloudinary.com/dpl8pr4y7/image/upload/v1745336268/ufab63vrlt62wskfy8km.jpg';
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to activity details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'favorite-${activity.id}',
                    child: Image.network(
                      activityImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay for better text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
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
                  ),
                  // Favorite icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms + (index * 100).ms);
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isDarkMode = false,
    bool isContact = false,
    bool showMap = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isContact ? FontWeight.w500 : FontWeight.normal,
                      color: isContact ? AppTheme.primaryColor : null,
                    ),
                  ),
                  if (showMap)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () {
                          // Open map with the address
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View on Map',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isContact)
              IconButton(
                icon: Icon(
                  icon == Icons.phone ? Icons.call_outlined : Icons.mail_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  // Handle contact action (call, email)
                },
              ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return _buildSettingsSwitchTile(
                          icon: Icons.dark_mode,
                          title: 'Dark Mode',
                          subtitle: 'Toggle between light and dark theme',
                          isDarkMode: isDarkMode,
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            if (value) {
                              themeProvider.setDarkTheme();
                            } else {
                              themeProvider.setLightTheme();
                            }
                          },
                          color: AppTheme.accentColor,
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Change application language',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LanguageSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.lock,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.favorite,
                      title: 'Favorite Activities',
                      subtitle: 'View and manage your favorites',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FavoritesScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get assistance and support',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to privacy policy screen
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLogoutButtonSmall(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? color.withOpacity(0.2)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chevron_right,
            color: AppTheme.primaryColor,
            size: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 500.ms);
  }

  Widget _buildLogoutButtonSmall() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          _showLogoutConfirmationDialog();
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Logout', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _authBloc.add(const LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Class for persistent tab header
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

// Mock screen for language settings
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Settings'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select your preferred language',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildLanguageTile(
                  context,
                  language: 'English',
                  isSelected: true,
                  flag: 'assets/images/flags/us.png',
                  isDarkMode: isDarkMode,
                ),
                _buildLanguageTile(
                  context,
                  language: 'Français',
                  isSelected: false,
                  flag: 'assets/images/flags/fr.png',
                  isDarkMode: isDarkMode,
                ),
                _buildLanguageTile(
                  context,
                  language: 'Español',
                  isSelected: false,
                  flag: 'assets/images/flags/es.png',
                  isDarkMode: isDarkMode,
                ),
                _buildLanguageTile(
                  context,
                  language: 'Deutsch',
                  isSelected: false,
                  flag: 'assets/images/flags/de.png',
                  isDarkMode: isDarkMode,
                ),
                _buildLanguageTile(
                  context,
                  language: 'Italiano',
                  isSelected: false,
                  flag: 'assets/images/flags/it.png',
                  isDarkMode: isDarkMode,
                ),
                _buildLanguageTile(
                  context,
                  language: 'Português',
                  isSelected: false,
                  flag: 'assets/images/flags/pt.png',
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageTile(
    BuildContext context, {
    required String language,
    required bool isSelected,
    required String flag,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage(flag),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Text(
        language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            )
          : null,
      onTap: () {
        // Set language
        Navigator.pop(context);
      },
    );
  }
}
