import 'package:flutter/material.dart';
import 'package:flutter_activity_app/screens/client/activity_map/activity_map_screen_with_chat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_activity_app/bloc/activity/activity_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/screens/client/activity/activity_details_screen.dart';
import 'package:flutter_activity_app/widgets/network_error_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  late ActivityBloc _activityBloc;
  // Ajouter un Set pour stocker les IDs des activités favorites localement
  Set<String> _localFavorites = {};

  @override
  void initState() {
    super.initState();
    _activityBloc = getIt<ActivityBloc>();
    _activityBloc.add(const LoadActivities());
    // Charger les favoris depuis le stockage local
    _loadLocalFavorites();
  }

  // Méthode pour charger les favoris depuis SharedPreferences
  Future<void> _loadLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('localFavorites') ?? [];
    setState(() {
      _localFavorites = Set<String>.from(favorites);
    });
  }

  // Méthode pour sauvegarder les favoris dans SharedPreferences
  Future<void> _saveLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('localFavorites', _localFavorites.toList());
  }

  // Méthode pour vérifier si une activité est favorite
  bool _isActivityFavorite(Activity activity) {
    // Vérifier d'abord le statut dans le modèle
    if (activity.isFavorite) {
      // Si c'est un favori dans le modèle, l'ajouter à notre cache local
      if (!_localFavorites.contains(activity.id)) {
        _localFavorites.add(activity.id!);
        _saveLocalFavorites();
      }
      return true;
    }
    // Sinon, vérifier notre cache local
    return _localFavorites.contains(activity.id);
  }

  // Méthode pour mettre à jour le statut favori localement
  void _toggleLocalFavorite(String activityId) {
    setState(() {
      if (_localFavorites.contains(activityId)) {
        _localFavorites.remove(activityId);
      } else {
        _localFavorites.add(activityId);
      }
    });
    _saveLocalFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _activityBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activities'),
          elevation: 0,
          actions: [
            // Notifications avec badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.map_sharp),
                  onPressed: _openNotifications,
                  tooltip: 'ActivityMapScreenWithChat',
                ),
              ],
            ),
            // Messages avec badge
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryFilter(),
            Expanded(
              child: BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state) {
                  if (state is ActivityLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ActivitiesLoaded) {
                    // Mettre à jour notre cache local avec les données du backend
                    for (var activity in state.activities) {
                      if (activity.isFavorite && activity.id != null) {
                        _localFavorites.add(activity.id!);
                      }
                    }
                    _saveLocalFavorites();
                    
                    return _buildActivityList(
                        context, state.filteredActivities);
                  } else if (state is ActivityError) {
                    return NetworkErrorWidget(
                      message: 'Could not load activities',
                      onRetry: () {
                        _activityBloc.add(const LoadActivities());
                      },
                    );
                  } else {
                    return const Center(child: Text('No activities found'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[800] 
                : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        if (state is ActivitiesLoaded) {
                          context
                              .read<ActivityBloc>()
                              .add(const SearchActivities(''));
                        }
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              context.read<ActivityBloc>().add(SearchActivities(value));
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        if (state is ActivitiesLoaded) {
          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(context, null, 'All'),
                ...state.categories.map((category) =>
                    _buildCategoryChip(context, category, category)),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, String? category, String label) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          context
              .read<ActivityBloc>()
              .add(FilterActivities(category: _selectedCategory));
        },
        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
        selectedColor: theme.primaryColor.withOpacity(0.2),
        checkmarkColor: theme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? theme.primaryColor : isDarkMode ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<Activity> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Text('No activities found matching your criteria'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ActivityBloc>().add(const LoadActivities());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(context, activity);
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Vérifier si l'activité est favorite en utilisant notre méthode locale
    final isFavorite = _isActivityFavorite(activity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ActivityDetailsScreen(activityId: activity.id!),
            ),
          ).then((_) {
            // Rafraîchir l'état des favoris au retour de l'écran de détails
            setState(() {});
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  activity.image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.red : isDarkMode ? Colors.grey[300] : Colors.grey,
                      ),
                      onPressed: () {
                        // Mettre à jour l'état local immédiatement
                        _toggleLocalFavorite(activity.id!);
                        // Envoyer l'événement au bloc pour mettre à jour le backend
                        context
                            .read<ActivityBloc>()
                            .add(ToggleFavorite(activity.id!));
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    child: Text(
                      activity.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${activity.rating} (${activity.reviews.length})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '\$${activity.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const ActivityMapScreenWithChat()),
    );
  }
}