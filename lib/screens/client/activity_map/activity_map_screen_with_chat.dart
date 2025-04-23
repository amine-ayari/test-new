import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_activity_app/bloc/activity/activity_state.dart';
import 'package:flutter_activity_app/bloc/review/review_bloc.dart';
import 'package:flutter_activity_app/bloc/review/review_event.dart';
import 'package:flutter_activity_app/bloc/participant/participant_bloc.dart';
import 'package:flutter_activity_app/bloc/participant/participant_event.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/screens/client/chatbot/widgets/custom_button.dart';
import 'package:flutter_activity_app/widgets/review/review_list.dart';
import 'package:flutter_activity_app/widgets/review/review_form.dart';
import 'package:flutter_activity_app/widgets/participant/participant_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

class ActivityMapScreenWithChat extends StatefulWidget {
  const ActivityMapScreenWithChat({Key? key}) : super(key: key);

  @override
  State<ActivityMapScreenWithChat> createState() =>
      _ActivityMapScreenWithChatState();
}

class _ActivityMapScreenWithChatState extends State<ActivityMapScreenWithChat>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationError = false;
  String _errorMessage = '';
  Activity? _selectedActivity;
  late AnimationController _pulseController;
  late AnimationController _fabController;
  late AnimationController _rotateController;
  late AnimationController _bounceController;
  bool _isDarkMode = false;

  // Pour le filtrage des activités
  String _selectedFilter = 'Tous';
  final List<String> _filters = [
    'Tous',
    'Adventure',
    'Food',
    'Culture',
    'Sports',
    'Relaxation'
  ];

  // Default center position (will be updated with user location)
  LatLng _center = const LatLng(48.8566, 2.3522); // Paris as default

  // Pour l'animation de zoom
  double _currentZoom = 13.0;

  // For activity details tabs
  int _selectedTabIndex = 0;
  
  // Mock current user
  final User _currentUser = User(
    id: 'current-user-id',
    email: 'user@example.com',
    name: 'John Doe',
    role: UserRole.client,
    createdAt: DateTime.now(),
    profileImage: 'https://randomuser.me/api/portraits/men/32.jpg',
  );

  late ActivityBloc _activityBloc;
  late ReviewBloc _reviewBloc;
  late ParticipantBloc _participantBloc;

  @override
  void initState() {
    super.initState();

    // Initialize blocs
    _activityBloc = getIt<ActivityBloc>();
    _reviewBloc = getIt<ReviewBloc>();
    _participantBloc = getIt<ParticipantBloc>();
    
    _activityBloc.add(const LoadActivities());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _getCurrentLocation();

  /*   // Check system theme
    final brightness = MediaQuery.of(context).platformBrightness;
    _isDarkMode = brightness == Brightness.light; */
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check system theme
    final brightness = MediaQuery.of(context).platformBrightness;
    _isDarkMode = brightness == Brightness.light;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fabController.dispose();
    _rotateController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // Get current location with permission handling
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationError = false;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = true;
            _errorMessage = 'Les permissions de localisation sont refusées';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = true;
          _errorMessage =
              'Les permissions de localisation sont définitivement refusées';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;
        _center = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Animate to user location
      _animateToPosition(_center, 15.0);

      // Mettre à jour les activités avec la position de l'utilisateur
      _activityBloc.add(UpdateActivitiesWithDistance(
          LatLng(position.latitude, position.longitude)));
    } catch (e) {
      setState(() {
        _locationError = true;
        _errorMessage =
            'Impossible d\'obtenir la localisation: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Animation pour se déplacer vers une position
  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        ),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _animateToPosition(LatLng position, double zoom) {
    _currentZoom = zoom;
    animatedMapMove(position, zoom);
  }

  // Calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
  }

  // Format distance in km or m
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceInMeters.round()} m';
    }
  }

  // Ouvrir le chat avec l'assistant
  void _openChatWithAssistant() {
    HapticFeedback.mediumImpact();

    // Animation du bouton
    _fabController.forward().then((_) => _fabController.reverse());

    // Naviguer vers l'écran de chat
    Navigator.pushNamed(context, '/chat');
  }

  // Filtrer les activités par catégorie
  void _filterActivities(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    if (filter == 'Tous') {
      _activityBloc.add(const FilterActivities());
    } else {
      _activityBloc.add(FilterActivities(
          category: filter,
          userLocation: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : null));
    }

    // Feedback tactile
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    // Check system theme
    final brightness = MediaQuery.of(context).platformBrightness;
    _isDarkMode = brightness == Brightness.light;
    
    final ThemeData theme = _isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: AppTheme.primaryColor,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimaryColor,
              elevation: 0,
            ),
          );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _activityBloc),
        BlocProvider.value(value: _reviewBloc),
        BlocProvider.value(value: _participantBloc),
      ],
      child: Theme(
        data: theme,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildImprovedAppBar(),
          body: BlocConsumer<ActivityBloc, ActivityState>(
            listener: (context, state) {
              if (state is ActivityError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  // Map
                  _buildMap(state),

                  // Loading indicator
                  if (_isLoading || state is ActivityLoading)
                    Container(
                      color: _isDarkMode
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.7),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chargement en cours...',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Error message
                  if (_locationError) _buildErrorOverlay(),

                  // Selected activity info
                  if (_selectedActivity != null) _buildActivityInfoPanel(),

                  // Activity list button
                  Positioned(
                    top: 96, // En dessous de l'AppBar
                    left: 16,
                    child: _buildActivityListButton(state),
                  ),

                  // Filtres
                  Positioned(
                    top: 96, // En dessous de l'AppBar
                    right: 16,
                    child: _buildFilterButton(),
                  ),

                  // Zoom controls
                  Positioned(
                    bottom: _selectedActivity != null ? 320 : 100,
                    right: 16,
                    child: _buildZoomControls(),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _fabController,
            builder: (context, child) {
              final scale = 1.0 + _fabController.value * 0.2;
              return Transform.scale(
                scale: scale,
                child: FloatingActionButton(
                  onPressed: _openChatWithAssistant,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.chat_rounded),
                  elevation: 4,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Improved App Bar
  PreferredSizeWidget _buildImprovedAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Explorer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: _isDarkMode
          ? const Color(0xFF1E1E1E).withOpacity(0.9)
          : Colors.white.withOpacity(0.9),
      foregroundColor:
          _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.my_location_rounded),
          onPressed: () {
            if (_currentPosition != null) {
              HapticFeedback.mediumImpact();
              _animateToPosition(
                  LatLng(_currentPosition!.latitude,
                      _currentPosition!.longitude),
                  15.0);
            } else {
              _getCurrentLocation();
            }
          },
          tooltip: 'Ma position',
        ),
        IconButton(
          icon: AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: child,
              );
            },
            child: const Icon(Icons.refresh_rounded),
          ),
          onPressed: _getCurrentLocation,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildMap(ActivityState state) {
    List<Activity> activities = [];
    LatLng? userLocation;

    if (state is ActivitiesLoaded) {
      activities = state.filteredActivities;
      userLocation = state.userLocation;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 13.0,
        onTap: (_, __) {
          setState(() {
            _selectedActivity = null;
          });
        },
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            _currentZoom = position.zoom!;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _isDarkMode
              ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.flutter_activity_app',
          subdomains: const ['a', 'b', 'c'],
        ),

        // Activity markers
        MarkerLayer(
          markers: [
            // User location marker
            if (_currentPosition != null)
              Marker(
                width: 60.0,
                height: 60.0,
                point: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse effect
                        Container(
                          width: 60.0 * (0.5 + _pulseController.value * 0.5),
                          height: 60.0 * (0.5 + _pulseController.value * 0.5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(
                                0.3 * (1 - _pulseController.value)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 20.0,
                          height: 20.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Activity markers
            ...activities.map((activity) {
              final isSelected = _selectedActivity == activity;

              // Calculer la distance si la position est disponible
              String distanceText = '';
              if (_currentPosition != null) {
                final distanceInMeters = _calculateDistance(
                    LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    LatLng(activity.latitude, activity.longitude));
                distanceText = _formatDistance(distanceInMeters);
              }

              return Marker(
                width: 60.0,
                height: 70.0,
                point: LatLng(activity.latitude, activity.longitude),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedActivity = activity;
                      _selectedTabIndex = 0; // Reset to first tab
                    });

                    // Load reviews and participants for the selected activity
                    _reviewBloc.add(LoadReviews(activity.id!));
                    _participantBloc.add(LoadParticipants(activity.id!));

                    // Centrer la carte sur l'activité sélectionnée
                    _animateToPosition(
                        LatLng(activity.latitude, activity.longitude), 15.0);
                  },
                  child: AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) {
                      // Animation de rebond uniquement pour le marqueur sélectionné
                      final bounce = isSelected
                          ? (0.05 *
                              math.sin(2 * math.pi * _bounceController.value))
                          : 0.0;

                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                            begin: isSelected ? 0.8 : 1.0,
                            end: isSelected ? 1.2 : 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset:
                                Offset(0, isSelected ? -5 - (bounce * 10) : 0),
                            child: Transform.scale(
                              scale: value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Badge de distance (uniquement pour les éléments sélectionnés)
                                  if (isSelected && distanceText.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: _isDarkMode
                                            ? Colors.black.withOpacity(0.7)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.directions_walk_rounded,
                                            size: 12,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            distanceText,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Icône de l'activité
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : (_isDarkMode
                                              ? const Color(0xFF2A2A2A)
                                              : Colors.white),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                                  .withOpacity(0.4)
                                              : Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getActivityIcon(activity.category),
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                  ),

                                  // Nom de l'activité (uniquement pour les éléments sélectionnés)
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: _isDarkMode
                                            ? Colors.black.withOpacity(0.7)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        activity.name,
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: _isDarkMode
          ? Colors.black.withOpacity(0.9)
          : Colors.white.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Accès à la localisation requis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    _isDarkMode ? Colors.white70 : AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Ouvrir les paramètres',
              icon: Icons.settings_rounded,
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _getCurrentLocation,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityInfoPanel() {
    final activity = _selectedActivity!;
    String distance = '';

    if (_currentPosition != null) {
      final distanceInMeters = _calculateDistance(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(activity.latitude, activity.longitude));
      distance = _formatDistance(distanceInMeters);
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 300 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getActivityIcon(activity.category),
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(activity.category)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        activity.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getTypeColor(activity.category),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (distance.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.directions_walk_rounded,
                                              size: 16,
                                              color: AppTheme.primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              distance,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  activity.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: _isDarkMode
                                          ? Colors.white70
                                          : AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        activity.location,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isDarkMode
                                              ? Colors.white70
                                              : AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedActivity = null;
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.black26
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.black12 : Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(
                            color: _isDarkMode ? Colors.white10 : Colors.grey.shade200,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: _isDarkMode ? Colors.white10 : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(0, 'À propos', Icons.info_outline),
                          _buildTabButton(1, 'Participants', Icons.people_outline),
                          _buildTabButton(2, 'Avis', Icons.star_outline),
                        ],
                      ),
                    ),

                    // Tab content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _selectedTabIndex == 0
                          ? _buildAboutTab(activity)
                          : _selectedTabIndex == 1
                              ? _buildParticipantsTab(activity)
                              : _buildReviewsTab(activity),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Voir les détails',
                              icon: Icons.info_outline_rounded,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/details',
                                  arguments: activity,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.directions_rounded,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                _openDirections(activity);
                              },
                              tooltip: 'Itinéraire',
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bouton pour discuter de cette activité
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.chat_rounded,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () {
                                _askAboutActivity(activity);
                              },
                              tooltip: 'Discuter de cette activité',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppTheme.primaryColor
                    : _isDarkMode
                        ? Colors.white70
                        : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : _isDarkMode
                          ? Colors.white70
                          : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(Activity activity) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isDarkMode
                  ? Colors.white
                  : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            activity.description,
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode
                  ? Colors.white70
                  : AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Additional info
          _buildInfoItem(Icons.access_time_rounded, 'Durée', activity.duration),
          _buildInfoItem(Icons.group_rounded, 'Taille du groupe', activity.capacity != null ? '${activity.capacity} personnes' : '5-10 personnes'),
          _buildInfoItem(Icons.euro_rounded, 'Prix', '${activity.price}€ par personne'),
          _buildInfoItem(Icons.calendar_today_rounded, 'Disponibilité', 'Tous les jours'),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(Activity activity) {
    if (activity.id == null) {
      return const Center(
        child: Text('Impossible de charger les participants'),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ParticipantList(
        activityId: activity.id!,
        currentUserId: _currentUser.id,
        capacity: activity.capacity,
      ),
    );
  }

  Widget _buildReviewsTab(Activity activity) {
    if (activity.id == null) {
      return const Center(
        child: Text('Impossible de charger les avis'),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ReviewList(
        activityId: activity.id!,
        currentUserId: _currentUser.id,
        onAddReviewPressed: () {
          _showAddReviewBottomSheet(activity);
        },
      ),
    );
  }

  void _showAddReviewBottomSheet(Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.rate_review_outlined,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ajouter un avis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              activity.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Review form
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: ReviewForm(
                      activityId: activity.id!,
                      currentUser: _currentUser,
                      onReviewSubmitted: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Avis ajouté avec succès !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthode pour poser des questions sur une activité spécifique
  void _askAboutActivity(Activity activity) {
    HapticFeedback.mediumImpact();

    // Show bottom sheet with activity details, participants and reviews
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getActivityIcon(activity.category),
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              'Informations détaillées',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Tabs
                DefaultTabController(
                  length: 3,
                  child: Expanded(
                    child: Column(
                      children: [
                        TabBar(
                          tabs: const [
                            Tab(text: 'Détails'),
                            Tab(text: 'Participants'),
                            Tab(text: 'Avis'),
                          ],
                          labelColor: AppTheme.primaryColor,
                          unselectedLabelColor: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
                          indicatorColor: AppTheme.primaryColor,
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Details tab
                              ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(20),
                                children: [
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    activity.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isDarkMode ? Colors.white70 : AppTheme.textSecondaryColor,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInfoItem(Icons.access_time_rounded, 'Durée', activity.duration),
                                  _buildInfoItem(Icons.group_rounded, 'Taille du groupe', activity.capacity != null ? '${activity.capacity} personnes' : '5-10 personnes'),
                                  _buildInfoItem(Icons.euro_rounded, 'Prix', '${activity.price}€ par personne'),
                                  _buildInfoItem(Icons.calendar_today_rounded, 'Disponibilité', 'Tous les jours'),
                                  const SizedBox(height: 20),
                                  CustomButton(
                                    text: 'Discuter avec l\'assistant',
                                    icon: Icons.chat_rounded,
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/chat',
                                        arguments: 'Parle-moi de l\'activité "${activity.name}" à ${activity.location}. Est-ce que tu recommandes?');
                                    },
                                  ),
                                ],
                              ),
                              
                              // Participants tab
                              if (activity.id != null)
                                ParticipantList(
                                  activityId: activity.id!,
                                  currentUserId: _currentUser.id,
                                  capacity: activity.capacity,
                                ),
                              
                              // Reviews tab
                              if (activity.id != null)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ReviewList(
                                    activityId: activity.id!,
                                    currentUserId: _currentUser.id,
                                    onAddReviewPressed: () {
                                      Navigator.pop(context);
                                      _showAddReviewBottomSheet(activity);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityListButton(ActivityState state) {
    int activitiesCount = 0;

    if (state is ActivitiesLoaded) {
      activitiesCount = state.filteredActivities.length;
    }

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showActivitiesList();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$activitiesCount Activités',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showFilterOptions();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedFilter,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Zoom in
              Material(
                color: Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: InkWell(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _animateToPosition(_mapController.center, _currentZoom + 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.add,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: _isDarkMode ? Colors.white10 : Colors.grey.shade200,
              ),

              // Zoom out
              Material(
                color: Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: InkWell(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _animateToPosition(_mapController.center, _currentZoom - 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.remove,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Filtrer par catégorie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ),

            // Filter options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      Navigator.pop(context);
                      _filterActivities(filter);
                    },
                    backgroundColor:
                        _isDarkMode ? Colors.black26 : Colors.grey.shade100,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (_isDarkMode
                              ? Colors.white70
                              : AppTheme.textPrimaryColor),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showActivitiesList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              List<Activity> activities = [];
              List<String> categories = [];

              if (state is ActivitiesLoaded) {
                activities = state.filteredActivities;
                categories = state.categories;
              }

              return Container(
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title and filter
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.map_rounded,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Activités à proximité',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _isDarkMode
                                            ? Colors.white
                                            : AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    Text(
                                      '${activities.length} activités trouvées',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _isDarkMode
                                            ? Colors.white70
                                            : AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Filter chips
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _filters.map((filter) {
                                final isSelected = _selectedFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      _filterActivities(filter);
                                    },
                                    backgroundColor: _isDarkMode
                                        ? Colors.black26
                                        : Colors.grey.shade100,
                                    selectedColor:
                                        AppTheme.primaryColor.withOpacity(0.2),
                                    checkmarkColor: AppTheme.primaryColor,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : (_isDarkMode
                                              ? Colors.white70
                                              : AppTheme.textPrimaryColor),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: activities.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: _isDarkMode
                                        ? Colors.white30
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune activité trouvée',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode
                                          ? Colors.white70
                                          : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Essayez un autre filtre',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isDarkMode
                                          ? Colors.white30
                                          : AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: activities.length,
                              itemBuilder: (context, index) {
                                final activity = activities[index];
                                String distance = '';

                                if (_currentPosition != null) {
                                  final distanceInMeters = _calculateDistance(
                                      LatLng(_currentPosition!.latitude,
                                          _currentPosition!.longitude),
                                      LatLng(activity.latitude,
                                          activity.longitude));
                                  distance = _formatDistance(distanceInMeters);
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  color: _isDarkMode
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _selectedActivity = activity;
                                        _selectedTabIndex = 0;
                                      });
                                      
                                      // Load reviews and participants
                                      if (activity.id != null) {
                                        _reviewBloc.add(LoadReviews(activity.id!));
                                        _participantBloc.add(LoadParticipants(activity.id!));
                                      }
                                      
                                      _animateToPosition(
                                          LatLng(activity.latitude,
                                              activity.longitude),
                                          15.0);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Icône de l'activité
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(
                                                      activity.category)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _getActivityIcon(
                                                      activity.category),
                                                  color: _getTypeColor(
                                                      activity.category),
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  activity.category,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getTypeColor(
                                                        activity.category),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Informations sur l'activité
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  activity.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isDarkMode
                                                        ? Colors.white
                                                        : AppTheme
                                                            .textPrimaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 14,
                                                      color: _isDarkMode
                                                          ? Colors.white70
                                                          : AppTheme
                                                              .textSecondaryColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        activity.location,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: _isDarkMode
                                                              ? Colors.white70
                                                              : AppTheme
                                                                  .textSecondaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  activity.description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _isDarkMode
                                                        ? Colors.white54
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Distance
                                          if (distance.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .directions_walk_rounded,
                                                        size: 14,
                                                        color: AppTheme
                                                            .primaryColor,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        distance,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: _isDarkMode
                                                        ? Colors.black26
                                                        : Colors.grey.shade100,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color:
                                                        AppTheme.primaryColor,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Open directions in map app
  void _openDirections(Activity activity) {
    HapticFeedback.mediumImpact();

    // Préparer les coordonnées de destination
    final lat = activity.latitude;
    final lng = activity.longitude;
    final label = Uri.encodeComponent(activity.name);

    // Créer les URLs pour différentes plateformes
    final googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$label';
    final appleMapsUrl = 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';

    // Déterminer quelle URL utiliser selon la plateforme
    final url = Theme.of(context).platform == TargetPlatform.iOS
        ? appleMapsUrl
        : googleMapsUrl;

    // Lancer l'URL
    _launchMapsUrl(url, activity.name);
  }

  // Méthode pour lancer l'URL
  Future<void> _launchMapsUrl(String url, String activityName) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.directions_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Itinéraire vers $activityName ouvert'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        // Afficher un message d'erreur si l'URL ne peut pas être lancée
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir l\'application de cartes'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Gérer les erreurs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Get icon based on activity category
  IconData _getActivityIcon(String category) {
    switch (category.toLowerCase()) {
      case 'adventure':
        return Icons.terrain_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'culture':
        return Icons.museum_rounded;
      case 'sports':
        return Icons.sports_rounded;
      case 'relaxation':
        return Icons.spa_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  // Get color based on activity category
  Color _getTypeColor(String category) {
    switch (category.toLowerCase()) {
      case 'adventure':
        return Colors.orange;
      case 'food':
        return Colors.red;
      case 'culture':
        return Colors.purple;
      case 'sports':
        return Colors.green;
      case 'relaxation':
        return Colors.blue;
      default:
        return AppTheme.primaryColor;
    }
  }
}