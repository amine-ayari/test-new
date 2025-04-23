import 'package:flutter/material.dart';
import 'package:flutter_activity_app/screens/provider/activity_form_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_activity_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_event.dart';
import 'package:flutter_activity_app/bloc/provider/provider_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/widgets/network_error_widget.dart';

class ProviderActivitiesScreen extends StatefulWidget {
  final String providerId;

  const ProviderActivitiesScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderActivitiesScreen> createState() => _ProviderActivitiesScreenState();
}

class _ProviderActivitiesScreenState extends State<ProviderActivitiesScreen> with WidgetsBindingObserver {
  late ProviderBloc _providerBloc;
  bool _isFirstLoad = true;
  
  @override
  void initState() {
    super.initState();
    _providerBloc = getIt<ProviderBloc>();
    
    // Ajouter l'observateur pour détecter quand l'écran devient visible
    WidgetsBinding.instance.addObserver(this);
    
    // Charger les activités au démarrage
    _loadActivities();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les activités quand les dépendances changent
    if (!_isFirstLoad) {
      _loadActivities();
    }
    _isFirstLoad = false;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recharger les activités quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _loadActivities();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _loadActivities() {
    print("Chargement des activités pour le provider: ${widget.providerId}");
    _providerBloc.add(LoadProviderActivities(widget.providerId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _providerBloc,
      child: Scaffold(
        body: BlocBuilder<ProviderBloc, ProviderState>(
          builder: (context, state) {
            print("État actuel du bloc: $state");
            
            if (state is ProviderLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProviderActivitiesLoaded) {
              print("Activités chargées: ${state.activities.length}");
              return _buildActivitiesList(state.activities);
            } else if (state is ProviderError) {
              return NetworkErrorWidget(
                message: 'Impossible de charger les activités',
                onRetry: () {
                  _loadActivities();
                },
              );
            } else if (state is ActivityCreated || state is ActivityUpdated || state is ActivityDeleted) {
              // Forcer le rechargement immédiat après une modification
              print("Activité modifiée, rechargement forcé");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadActivities();
              });
              return const Center(child: CircularProgressIndicator());
            } else {
              return const Center(child: Text('Aucune activité trouvée'));
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityFormScreen(providerId: widget.providerId),
              ),
            ).then((_) {
              // Forcer le rechargement à chaque retour de l'écran de formulaire
              print("Retour du formulaire d'activité, rechargement forcé");
              _loadActivities();
            });
          },
          child: const Icon(Icons.add),
          tooltip: 'Ajouter une activité',
        ),
      ),
    );
  }

  Widget _buildActivitiesList(List<Activity> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hiking,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune activité pour le moment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Appuyez sur le bouton + pour créer votre première activité',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadActivities();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
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
              builder: (context) => ProviderActivityDetailsScreen(
                activity: activity,
                providerId: widget.providerId,
              ),
            ),
          ).then((_) {
            // Forcer le rechargement à chaque retour de l'écran de détails
            _loadActivities();
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
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
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
                            '${activity.rating} (${activity.reviews is List ? activity.reviews.length : activity.reviews})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '${activity.price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Bouton de suppression
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifier'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityFormScreen(
                                providerId: widget.providerId,
                                activity: activity,
                              ),
                            ),
                          ).then((_) {
                            _loadActivities();
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Supprimer'),
                        onPressed: () {
                          _showDeleteConfirmation(activity);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
  
  void _showDeleteConfirmation(Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'activité'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${activity.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _providerBloc.add(DeleteActivity(activity.id.toString()));
              
              // Afficher un message de confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Activité supprimée avec succès'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  ),
                ),
              );
              
              // Forcer le rechargement immédiat
              _loadActivities();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
