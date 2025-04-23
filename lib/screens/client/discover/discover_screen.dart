// lib/screens/client/activity/discover_activity_screen.dart (mise à jour)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_activity_app/screens/client/reservation/book_activity_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_activity_app/bloc/activity/activity_state.dart';
import 'package:flutter_activity_app/bloc/location/location_bloc.dart';
import 'package:flutter_activity_app/bloc/location/location_event.dart';
import 'package:flutter_activity_app/bloc/location/location_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/screens/client/activity/activity_details_screen.dart';
import 'package:flutter_activity_app/services/location_service.dart';
import 'package:flutter_activity_app/widgets/network_error_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Événements pour le swipe
class SwipeLeftActivity extends ActivityEvent {
  final String activityId;
  const SwipeLeftActivity(this.activityId);
  
  @override
  List<Object?> get props => [activityId];
}

class SwipeRightActivity extends ActivityEvent {
  final String activityId;
  const SwipeRightActivity(this.activityId);
  
  @override
  List<Object?> get props => [activityId];
}

class DiscoverActivityScreen extends StatefulWidget {
  const DiscoverActivityScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverActivityScreen> createState() => _DiscoverActivityScreenState();
}

class _DiscoverActivityScreenState extends State<DiscoverActivityScreen> with SingleTickerProviderStateMixin {
  late ActivityBloc _activityBloc;
  late LocationBloc _locationBloc;
  final LocationService _locationService = LocationService();
  List<Activity> _activities = [];
  int _currentIndex = 0;
  
  // Pour l'animation de swipe
  late AnimationController _animationController;
  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;
  double _dragExtent = 0;
  bool _isSwipingLeft = false;
  bool _isSwipingRight = false;
  
  // Filtres
  double _maxDistance = 10.0; // km
  double _minPrice = 0.0;
  double _maxPrice = 1000.0;
  List<String> _selectedCategories = [];
  double _minRating = 0.0;
  
  // Pour les animations
  bool _showFilters = false;
  bool _showMatch = false;
  String _matchedActivityName = '';
  
  // Pour la carte
  bool _showLocationPicker = false;
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  
  @override
  void initState() {
    super.initState();
    _activityBloc = getIt<ActivityBloc>();
    _locationBloc = getIt<LocationBloc>();
    
    // Charger les activités
    _activityBloc.add(const LoadActivities());
    
    // Demander la localisation actuelle
    _locationBloc.add(const GetCurrentLocation());
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animationController.addListener(() {
      if (_animationController.isCompleted) {
        // Animation terminée, passer à l'activité suivante
        if (_isSwipingLeft || _isSwipingRight) {
          if (_isSwipingRight) {
            // Montrer l'animation de match
            _showMatchAnimation();
          } else {
            _nextActivity();
          }
          _resetDrag();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  void _showMatchAnimation() {
    if (_currentIndex < _activities.length) {
      setState(() {
        _showMatch = true;
        _matchedActivityName = _activities[_currentIndex].name;
      });
      
      // Cacher l'animation après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showMatch = false;
            _nextActivity();
          });
        }
      });
    }
  }
  
  void _resetDrag() {
    setState(() {
      _dragStart = Offset.zero;
      _dragPosition = Offset.zero;
      _dragExtent = 0;
      _isSwipingLeft = false;
      _isSwipingRight = false;
    });
  }
  
  void _nextActivity() {
    if (_currentIndex < _activities.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Plus d'activités à afficher
      _activityBloc.add(const LoadActivities()); // Recharger pour obtenir plus d'activités
    }
  }
  
  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
    });
  }
  
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition = details.localPosition;
      _dragExtent = _dragPosition.dx - _dragStart.dx;
      
      // Déterminer la direction du swipe
      _isSwipingLeft = _dragExtent < -50;
      _isSwipingRight = _dragExtent > 50;
    });
  }
  
  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    
    if (_isSwipingLeft || velocity < -1000) {
      // Swipe à gauche (rejeter)
      _animationController.forward(from: 0);
      if (_currentIndex < _activities.length) {
        _activityBloc.add(SwipeLeftActivity(_activities[_currentIndex].id!));
      }
    } else if (_isSwipingRight || velocity > 1000) {
      // Swipe à droite (aimer)
      _animationController.forward(from: 0);
      if (_currentIndex < _activities.length) {
        _activityBloc.add(ToggleFavorite(_activities[_currentIndex].id!));
        _activityBloc.add(SwipeRightActivity(_activities[_currentIndex].id!));
      }
    } else {
      // Pas assez de mouvement pour un swipe, retour à la position initiale
      setState(() {
        _dragPosition = _dragStart;
        _dragExtent = 0;
        _isSwipingLeft = false;
        _isSwipingRight = false;
      });
    }
  }
  
  void _showFilterBottomSheet() {
    setState(() {
      _showFilters = true;
    });
  }
  
  void _hideFilterBottomSheet() {
    setState(() {
      _showFilters = false;
    });
  }
  
  void _showLocationPickerDialog() {
    setState(() {
      _showLocationPicker = true;
      
      // Initialiser la position sélectionnée avec la position actuelle de l'utilisateur
      if (_locationBloc.state is LocationLoaded) {
        _selectedLocation = (_locationBloc.state as LocationLoaded).location;
        
        // Centrer la carte sur la position actuelle
        _mapController.move(_selectedLocation!, 13);
      }
    });
  }
  
  void _hideLocationPickerDialog() {
    setState(() {
      _showLocationPicker = false;
      _selectedLocation = null;
    });
  }
  
  void _confirmCustomLocation() {
    if (_selectedLocation != null) {
      _locationBloc.add(SetCustomLocation(_selectedLocation!));
      
      // Mettre à jour les activités avec la nouvelle position
      _activityBloc.add(UpdateActivitiesWithDistance(_selectedLocation!));
    }
    _hideLocationPickerDialog();
  }
  
  void _applyFilters() {
    _hideFilterBottomSheet();
    
    // Obtenir la position actuelle de l'utilisateur
    LatLng? userLocation;
    if (_locationBloc.state is LocationLoaded) {
      userLocation = (_locationBloc.state as LocationLoaded).location;
    }
    
    _activityBloc.add(FilterActivities(
      category: _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      tags: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      maxDistance: userLocation != null ? _maxDistance : null,
      userLocation: userLocation,
    ));
  }

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _activityBloc),
      BlocProvider.value(value: _locationBloc),
    ],
    child: Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.background,
                  theme.colorScheme.background.withOpacity(0.95),
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discover',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          // Location button
                          BlocBuilder<LocationBloc, LocationState>(
                            builder: (context, state) {
                              return IconButton(
                                icon: Icon(
                                  state is LocationLoaded && state.isCustomLocation
                                      ? Icons.location_on
                                      : Icons.location_searching,
                                  color: state is LocationLoaded
                                      ? theme.colorScheme.primary
                                      : theme.disabledColor,
                                  size: 28,
                                ),
                                onPressed: _showLocationPickerDialog,
                                tooltip: 'Set your location',
                              );
                            },
                          ),
                          // Filter button
                          IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            onPressed: _showFilterBottomSheet,
                            tooltip: 'Filters',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Location indicator
                BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, state) {
                    if (state is LocationLoaded) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              state.isCustomLocation
                                  ? Icons.edit_location_alt
                                  : Icons.my_location,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.isCustomLocation
                                  ? 'Custom location'
                                  : 'Your current location',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (state is LocationError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_disabled,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.isPermissionDenied
                                    ? 'Location disabled. Some features are limited.'
                                    : 'Location error. Please try again.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _locationBloc.add(const GetCurrentLocation()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is LocationLoading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Getting your location...',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                // Main content
                Expanded(
                  child: BlocConsumer<ActivityBloc, ActivityState>(
                    listener: (context, state) {
                      if (state is ActivitiesLoaded) {
                        setState(() {
                          _activities = state.filteredActivities;
                          _currentIndex = 0; // Reset index when loading new activities
                        });
                        
                        // Update activities with user's location
                        if (state.userLocation == null && _locationBloc.state is LocationLoaded) {
                          final userLocation = (_locationBloc.state as LocationLoaded).location;
                          _activityBloc.add(UpdateActivitiesWithDistance(userLocation));
                        }
                      }
                    },
                    builder: (context, state) {
                      if (state is ActivityLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Searching for activities...',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        );
                      } else if (state is ActivitiesLoaded && _activities.isNotEmpty) {
                        return _buildSwipeableCards(state.userLocation);
                      } else if (state is ActivityError) {
                        return NetworkErrorWidget(
                          message: 'Unable to load activities',
                          onRetry: () {
                            _activityBloc.add(const LoadActivities());
                          },
                        );
                      } else {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No activities found',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try modifying your filters.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showFilterBottomSheet,
                                icon: const Icon(Icons.tune),
                                label: const Text('Modify filters'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
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
          ),
          
          // Filter panel
          if (_showFilters)
            _buildFilterPanel(),
          
          // Location picker
          if (_showLocationPicker)
            _buildLocationPicker(),
          
          // Match animation
          if (_showMatch)
            _buildMatchAnimation(),
        ],
      ),
    ),
  );
}

  Widget _buildFilterPanel() {
  final theme = Theme.of(context);
  
  return GestureDetector(
    onTap: _hideFilterBottomSheet,
    child: Container(
      color: Colors.black54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          0,
          _showFilters ? 0 : MediaQuery.of(context).size.height,
          0,
        ),
        child: GestureDetector(
          onTap: () {}, // Prevent tap propagation
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            margin: const EdgeInsets.only(top: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _hideFilterBottomSheet,
                      ),
                    ],
                  ),
                ),
                
                // Filter content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Distance
                      _buildFilterSection(
                        title: 'Max Distance',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Slider(
                              value: _maxDistance,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              activeColor: theme.colorScheme.primary,
                              label: '${_maxDistance.round()} km',
                              onChanged: (value) {
                                setState(() {
                                  _maxDistance = value;
                                });
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('1 km', style: theme.textTheme.bodySmall),
                                  Text('${_maxDistance.round()} km', 
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text('50 km', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Price
                      _buildFilterSection(
                        title: 'Price Range',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RangeSlider(
                              values: RangeValues(_minPrice, _maxPrice),
                              min: 0,
                              max: 1000,
                              divisions: 20,
                              activeColor: theme.colorScheme.primary,
                              labels: RangeLabels(
                                '${_minPrice.round()} €',
                                '${_maxPrice.round()} €',
                              ),
                              onChanged: (values) {
                                setState(() {
                                  _minPrice = values.start;
                                  _maxPrice = values.end;
                                });
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('0 €', style: theme.textTheme.bodySmall),
                                  Text('${_minPrice.round()} € - ${_maxPrice.round()} €', 
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text('1000 €', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Rating
                      _buildFilterSection(
                        title: 'Min Rating',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Slider(
                              value: _minRating,
                              min: 0,
                              max: 5,
                              divisions: 10,
                              activeColor: theme.colorScheme.primary,
                              label: _minRating.toStringAsFixed(1),
                              onChanged: (value) {
                                setState(() {
                                  _minRating = value;
                                });
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('0', style: theme.textTheme.bodySmall),
                                  Row(
                                    children: [
                                      Text(_minRating.toStringAsFixed(1), 
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.star, color: Colors.amber, size: 16),
                                    ],
                                  ),
                                  Text('5', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Categories
                      _buildFilterSection(
                        title: 'Categories',
                        child: BlocBuilder<ActivityBloc, ActivityState>(
                          builder: (context, state) {
                            if (state is ActivitiesLoaded) {
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: state.categories.map((category) {
                                  final isSelected = _selectedCategories.contains(category);
                                  return FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedCategories.add(category);
                                        } else {
                                          _selectedCategories.remove(category);
                                        }
                                      });
                                    },
                                    backgroundColor: theme.cardColor,
                                    selectedColor: theme.colorScheme.primary.withOpacity(0.15),
                                    checkmarkColor: theme.colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _maxDistance = 10.0;
                              _minPrice = 0.0;
                              _maxPrice = 1000.0;
                              _selectedCategories = [];
                              _minRating = 0.0;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),);
  }

  
  Widget _buildFilterSection({required String title, required Widget child}) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        child,
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
  
  Widget _buildLocationPicker() {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _hideLocationPickerDialog,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Empêcher la propagation du tap
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set your location',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _hideLocationPickerDialog,
                        ),
                      ],
                    ),
                  ),
                  
                  // Instructions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Tap on the map to select your location',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  
                  // Carte
                  Expanded(
                    child: BlocBuilder<LocationBloc, LocationState>(
                      builder: (context, state) {
                        LatLng initialPosition;
                        
                        if (state is LocationLoaded) {
                          initialPosition = state.location;
                        } else {
                          // Position par défaut (Paris)
                          initialPosition = const LatLng(48.8566, 2.3522);
                        }
                        
                        return ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: initialPosition,
                              initialZoom: 13,
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _selectedLocation = point;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.flutter_activity_app',
                              ),
                              // Marqueur de position actuelle
                              if (state is LocationLoaded)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: state.location,
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.my_location,
                                        color: theme.colorScheme.primary,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              // Marqueur de position sélectionnée
                              if (_selectedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Boutons d'action
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _locationBloc.add(const GetCurrentLocation());
                              _hideLocationPickerDialog();
                            },
                            icon: const Icon(Icons.my_location),
                            label: const Text('Use my location'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedLocation != null ? _confirmCustomLocation : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
          ),
        ),
      ),
    );
  }
  
  Widget _buildMatchAnimation() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              'C\'est un match !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _matchedActivityName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Added to your favorites',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
Widget _buildSwipeableCards(LatLng? userLocation) {
  if (_currentIndex >= _activities.length) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'You have seen all activities',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _activityBloc.add(const LoadActivities());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Discover more activities'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final activity = _activities[_currentIndex];
  final screenSize = MediaQuery.of(context).size;

  // Calculate the rotation and position based on the drag
  final rotationAngle = _dragExtent / screenSize.width * 0.3;
  final position = Offset(_dragExtent, 0);

  // Calculate swipe indicator opacity
  final leftSwipeOpacity = _dragExtent < 0 ? min((_dragExtent.abs() / 100), 1.0) : 0.0;
  final rightSwipeOpacity = _dragExtent > 0 ? min((_dragExtent / 100), 1.0) : 0.0;

  // Calculate the distance if the user's location is available
  String distanceText = '';
  if (userLocation != null && activity.latitude != null && activity.longitude != null) {
    final distance = _locationService.calculateDistance(
      userLocation,
      LatLng(activity.latitude!, activity.longitude!),
    );
    distanceText = _locationService.formatDistance(distance);
  }

  return Stack(
    children: [
      // Main activity card
      Center(
        child: GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookActivityScreen(activityId: activity.id!),
              ),
            );
          },
          child: Transform.translate(
            offset: position,
            child: Transform.rotate(
              angle: rotationAngle,
              child: Container(
                width: screenSize.width * 0.9,
                height: screenSize.height * 0.65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Activity image
                      Hero(
                        tag: 'activity_image_${activity.id!}-image',
                        child: Image.network(
                          activity.image,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Gradient for text
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),

                      // Activity information
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      activity.location,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (distanceText.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.directions,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            distanceText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${activity.rating} (${activity.reviews})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${activity.price.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  activity.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                activity.description.length > 100
                                    ? '${activity.description.substring(0, 100)}...'
                                    : activity.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Swipe left (reject) indicator
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Opacity(
                          opacity: leftSwipeOpacity,
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'SKIP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Swipe right (like) indicator
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Opacity(
                          opacity: rightSwipeOpacity,
                          child: Transform.rotate(
                            angle: 0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'LIKE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // Action buttons at the bottom
      Positioned(
        bottom: 40,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Reject button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'reject',
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _dragExtent = -screenSize.width;
                    _isSwipingLeft = true;
                  });
                  _activityBloc.add(SwipeLeftActivity(activity.id!));
                  _animationController.forward(from: 0);
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ),

            // Info button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'info',
                backgroundColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityDetailsScreen(activityId: activity.id!),
                    ),
                  );
                },
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
            ),

            // Like button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'like',
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _dragExtent = screenSize.width;
                    _isSwipingRight = true;
                  });
                  _activityBloc.add(ToggleFavorite(activity.id!));
                  _activityBloc.add(SwipeRightActivity(activity.id!));
                  _animationController.forward(from: 0);
                },
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.green,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
}