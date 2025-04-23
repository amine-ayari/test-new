import 'package:flutter/material.dart';
import 'package:flutter_activity_app/screens/client/profile/notification_settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/bloc/notification/notification_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/screens/client/reservation/user_reservations_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    Key? key, 
    required this.userId,
  }) : super(key: key);
  final String userId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late NotificationBloc _notificationBloc;
  late TabController _tabController;
  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Toutes', 'icon': Icons.notifications_outlined},
    {'title': 'Réservations', 'icon': Icons.calendar_today_outlined},
    {'title': 'Messages', 'icon': Icons.message_outlined},
    {'title': 'Système', 'icon': Icons.info_outline},
  ];
  bool _isLoading = false;
  bool _isRefreshing = false;
  int _unreadCount = 0;
  
  // Contrôleur pour la recherche
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  
  // Contrôleur pour les animations de liste
  late AnimationController _listAnimationController;
  
  @override
  void initState() {
    super.initState();
    _notificationBloc = getIt<NotificationBloc>();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      setState(() {});
    });
    
    // Chargement des notifications
    _loadNotifications();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _listAnimationController.reset();
      _listAnimationController.forward();
    }
  }

  void _loadNotifications() {
    setState(() {
      _isLoading = true;
    });
    _notificationBloc.add(LoadNotifications(widget.userId));
  }

  void _refreshNotifications() {
    setState(() {
      _isRefreshing = true;
    });
    _notificationBloc.add(LoadNotifications(widget.userId));
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        // Donner le focus au champ de recherche après le setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_searchFocusNode);
        });
      } else {
        _searchController.clear();
        FocusScope.of(context).unfocus();
      }
    });
  }

  List<AppNotification> _filterNotifications(List<AppNotification> notifications, String query) {
    if (query.isEmpty) return notifications;
    
    return notifications.where((notification) {
      return notification.title.toLowerCase().contains(query.toLowerCase()) ||
             notification.message.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    
    return BlocProvider.value(
      value: _notificationBloc,
      child: GestureDetector(
        onTap: () {
          // Fermer le clavier et la recherche si on tape en dehors
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching 
              ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  ),
                  style: const TextStyle(fontSize: 16),
                  textInputAction: TextInputAction.search,
                )
              : const Text('Notifications'),
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: Colors.black,
            centerTitle: false,
            leading: _isSearching 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleSearch,
                )
              : null,
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _toggleSearch,
                  tooltip: 'Rechercher',
                ),
              if (!_isSearching)
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    if (state is NotificationsLoaded && state.notifications.isNotEmpty) {
                      return PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'mark_all_read') {
                            _notificationBloc.add(MarkAllNotificationsAsRead(widget.userId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Toutes les notifications ont été marquées comme lues'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else if (value == 'clear_all') {
                            _showClearAllConfirmationDialog(context);
                          } else if (value == 'settings') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationSettingsScreen(),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'mark_all_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read, size: 20),
                                SizedBox(width: 12),
                                Text('Tout marquer comme lu'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear_all',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep, size: 20),
                                SizedBox(width: 12),
                                Text('Effacer tout'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(Icons.settings, size: 20),
                                SizedBox(width: 12),
                                Text('Paramètres'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Compteur de notifications non lues et TabBar
              Material(
                color: theme.scaffoldBackgroundColor,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Compteur de notifications non lues
                      BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) {
                          if (state is NotificationsLoaded) {
                            _unreadCount = state.notifications.where((n) => !n.isRead).length;
                            if (_unreadCount > 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$_unreadCount non lues',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          return const SizedBox(height: 4);
                        },
                      ),
                      // TabBar
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 3,
                        indicatorColor: theme.colorScheme.primary,
                        tabs: _tabs.map((tab) => Tab(
                          text: isSmallScreen ? null : tab['title'],
                          icon: Icon(tab['icon'], size: 20),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              // Contenu principal
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _refreshNotifications();
                    await Future.delayed(const Duration(milliseconds: 1500));
                    setState(() {
                      _isRefreshing = false;
                    });
                  },
                  child: BlocConsumer<NotificationBloc, NotificationState>(
                    listener: (context, state) {
                      if (state is NotificationsLoaded) {
                        setState(() {
                          _isLoading = false;
                          _isRefreshing = false;
                        });
                        _listAnimationController.forward();
                      } else if (state is NotificationError) {
                        setState(() {
                          _isLoading = false;
                          _isRefreshing = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${state.message}'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (_isLoading) {
                        return _buildLoadingState();
                      } else if (state is NotificationsLoaded) {
                        final filteredNotifications = _filterNotifications(
                          state.notifications, 
                          _searchController.text
                        );
                        
                        if (filteredNotifications.isEmpty && _searchController.text.isNotEmpty) {
                          return _buildNoSearchResultsState();
                        }
                        
                        if (state.notifications.isEmpty) {
                          return _buildEmptyState();
                        }
                        
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // Toutes les notifications
                            _buildNotificationsList(filteredNotifications),
                            // Notifications de réservation
                            _buildNotificationsList(filteredNotifications.where((n) => 
                              n.type == NotificationType.reservation || 
                              n.type == NotificationType.reservation_status_update ||
                              (n.type is String && (n.type == 'reservation' || n.type == 'reservation_status_update'))
                            ).toList()),
                            // Notifications de message
                            _buildNotificationsList(filteredNotifications.where((n) => 
                              n.type == NotificationType.message ||
                              (n.type is String && n.type == 'message')
                            ).toList()),
                            // Notifications système
                            _buildNotificationsList(filteredNotifications.where((n) => 
                              n.type == NotificationType.system ||
                              (n.type is String && n.type == 'system')
                            ).toList()),
                          ],
                        );
                      } else if (state is NotificationError) {
                        return _buildErrorState(state.message);
                      }
                      return _buildLoadingState();
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.notifications.any((n) => !n.isRead)) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    _notificationBloc.add(MarkAllNotificationsAsRead(widget.userId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Toutes les notifications ont été marquées comme lues'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Tout marquer comme lu'),
                  backgroundColor: theme.colorScheme.primary,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aucune notification',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Vous n\'avez pas encore de notifications. Elles apparaîtront ici lorsque vous en recevrez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _refreshNotifications,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 70,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Aucune notification ne correspond à "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear),
            label: const Text('Effacer la recherche'),
            style: OutlinedButton.styleFrom(
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

  Widget _buildEmptyTabState(String tabName) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _tabs[_tabController.index]['icon'],
                    size: 60,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune notification ${tabName.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Vous n\'avez pas encore de notifications dans cette catégorie',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Oups ! Une erreur est survenue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyTabState(_tabs[_tabController.index]['title']);
    }

    // Grouper les notifications par date
    final Map<String, List<AppNotification>> groupedNotifications = {};
    
    for (final notification in notifications) {
      final date = _formatNotificationDate(notification.createdAt);
      if (!groupedNotifications.containsKey(date)) {
        groupedNotifications[date] = [];
      }
      groupedNotifications[date]!.add(notification);
    }

    // Trier les dates (aujourd'hui, hier, etc.)
    final sortedDates = groupedNotifications.keys.toList()
      ..sort((a, b) {
        if (a == 'Aujourd\'hui') return -1;
        if (b == 'Aujourd\'hui') return 1;
        if (a == 'Hier') return -1;
        if (b == 'Hier') return 1;
        return a.compareTo(b);
      });

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dateNotifications = groupedNotifications[date]!;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              date,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...List.generate(dateNotifications.length, (notificationIndex) {
                      return AnimationConfiguration.staggeredList(
                        position: notificationIndex,
                        duration: const Duration(milliseconds: 375),
                        delay: Duration(milliseconds: 50 * notificationIndex),
                        child: SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildNotificationItem(dateNotifications[notificationIndex]),
                          ),
                        ),
                      );
                    }),
                    if (index < sortedDates.length - 1)
                      const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNotificationDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (notificationDate == today) {
      return 'Aujourd\'hui';
    } else if (notificationDate == yesterday) {
      return 'Hier';
    } else if (now.difference(notificationDate).inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(dateTime);
    } else {
      return DateFormat('d MMMM yyyy', 'fr_FR').format(dateTime);
    }
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final theme = Theme.of(context);
    
    // Déterminer l'icône et la couleur en fonction du type de notification
    IconData icon;
    Color color;
    
    if (notification.type is String) {
      final typeString = notification.type as String;
      switch (typeString) {
        case 'reservation':
        case 'reservation_status_update':
          icon = Icons.calendar_today;
          color = Colors.blue;
          break;
        case 'message':
          icon = Icons.message;
          color = Colors.green;
          break;
        case 'payment':
          icon = Icons.payment;
          color = Colors.purple;
          break;
        case 'system':
          icon = Icons.info;
          color = Colors.orange;
          break;
        default:
          icon = Icons.notifications;
          color = Colors.grey;
          break;
      }
    } else if (notification.type is NotificationType) {
      final type = notification.type as NotificationType;
      switch (type) {
        case NotificationType.reservation:
        case NotificationType.reservation_status_update:
          icon = Icons.calendar_today;
          color = Colors.blue;
          break;
        case NotificationType.message:
          icon = Icons.message;
          color = Colors.green;
          break;
        case NotificationType.payment:
          icon = Icons.payment;
          color = Colors.purple;
          break;
        case NotificationType.system:
          icon = Icons.info;
          color = Colors.orange;
          break;
      }
    } else {
      icon = Icons.notifications;
      color = Colors.grey;
    }
    
    return Slidable(
      key: Key(notification.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(
          onDismissed: () {
            _notificationBloc.add(DeleteNotification(notification.id));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notification supprimée'),
                action: SnackBarAction(
                  label: 'Annuler',
                  onPressed: () {
                    // Recharger les notifications pour "annuler" la suppression
                    _loadNotifications();
                  },
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          confirmDismiss: () async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Supprimer la notification'),
                  content: const Text('Êtes-vous sûr de vouloir supprimer cette notification ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Supprimer'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                );
              },
            ) ?? false;
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              if (!notification.isRead) {
                _notificationBloc.add(MarkNotificationAsRead(notification.id));
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.mark_email_read,
            label: 'Lire',
          ),
          SlidableAction(
            onPressed: (context) {
              _notificationBloc.add(DeleteNotification(notification.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notification supprimée'),
                  action: SnackBarAction(
                    label: 'Annuler',
                    onPressed: () {
                      _loadNotifications();
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: notification.isRead
              ? BorderSide.none
              : BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5),
        ),
        elevation: notification.isRead ? 1 : 3,
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              _notificationBloc.add(MarkNotificationAsRead(notification.id));
            }
            
            // Gérer le tap sur la notification en fonction du type
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'notification_icon_${notification.id}',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: notification.isRead 
                          ? [] 
                          : [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: notification.isRead 
                                  ? Colors.grey.withOpacity(0.1) 
                                  : theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatNotificationTime(notification.createdAt),
                              style: TextStyle(
                                color: notification.isRead 
                                    ? Colors.grey[600] 
                                    : theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.3,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notification.data != null && notification.data!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (notification.isReservationUpdate)
                              _buildActionChip(
                                icon: Icons.visibility,
                                label: 'Voir la réservation',
                                color: Colors.blue,
                                onTap: () => _navigateToReservation(notification),
                              ),
                            _buildActionChip(
                              icon: notification.isRead ? Icons.check : Icons.mark_email_read,
                              label: notification.isRead ? 'Lu' : 'Marquer comme lu',
                              color: notification.isRead ? Colors.grey : theme.colorScheme.primary,
                              onTap: () {
                                if (!notification.isRead) {
                                  _notificationBloc.add(MarkNotificationAsRead(notification.id));
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'À l\'instant';
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Gérer différents types de notifications
    if (notification.isReservationUpdate) {
      _navigateToReservation(notification);
    } else if (notification.type == NotificationType.message || 
              (notification.type is String && notification.type == 'message')) {
      // Naviguer vers les détails du message
      _showNotImplementedSnackbar('Affichage des messages');
    } else if (notification.type == NotificationType.payment || 
              (notification.type is String && notification.type == 'payment')) {
      // Naviguer vers les détails du paiement
      _showNotImplementedSnackbar('Affichage des paiements');
    } else {
      // Afficher les détails de la notification dans une boîte de dialogue
      _showNotificationDetails(notification);
    }
  }

  void _navigateToReservation(AppNotification notification) {
    if (notification.data != null && notification.data!.containsKey('reservationId')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserReservationsScreen(
            userId: widget.userId,
            //highlightedReservationId: notification.data!['reservationId'],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserReservationsScreen(userId: widget.userId),
        ),
      );
    }
  }

  void _showNotificationDetails(AppNotification notification) {
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée de glissement
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // En-tête avec icône
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'notification_Icon1_${notification.id}',
                          child: _buildNotificationTypeIcon(notification),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reçu le ${DateFormat('dd/MM/yyyy à HH:mm').format(notification.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Contenu de la notification
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (notification.data != null && notification.data!.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations supplémentaires',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...notification.data!.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value.toString(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ],
                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _notificationBloc.add(DeleteNotification(notification.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification supprimée'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Supprimer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              if (!notification.isRead) {
                                _notificationBloc.add(MarkNotificationAsRead(notification.id));
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('OK'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTypeIcon(AppNotification notification) {
    IconData icon;
    Color color;
    
    if (notification.type is String) {
      final typeString = notification.type as String;
      switch (typeString) {
        case 'reservation':
        case 'reservation_status_update':
          icon = Icons.calendar_today;
          color = Colors.blue;
          break;
        case 'message':
          icon = Icons.message;
          color = Colors.green;
          break;
        case 'payment':
          icon = Icons.payment;
          color = Colors.purple;
          break;
        case 'system':
          icon = Icons.info;
          color = Colors.orange;
          break;
        default:
          icon = Icons.notifications;
          color = Colors.grey;
          break;
      }
    } else if (notification.type is NotificationType) {
      final type = notification.type as NotificationType;
      switch (type) {
        case NotificationType.reservation:
        case NotificationType.reservation_status_update:
          icon = Icons.calendar_today;
          color = Colors.blue;
          break;
        case NotificationType.message:
          icon = Icons.message;
          color = Colors.green;
          break;
        case NotificationType.payment:
          icon = Icons.payment;
          color = Colors.purple;
          break;
        case NotificationType.system:
          icon = Icons.info;
          color = Colors.orange;
          break;
      }
    } else {
      icon = Icons.notifications;
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 30,
      ),
    );
  }

  void _showNotImplementedSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature non implémenté dans cette démo'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showClearAllConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les notifications'),
        content: const Text('Êtes-vous sûr de vouloir effacer toutes les notifications ? Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationBloc.add(ClearAllNotifications(widget.userId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les notifications ont été supprimées'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer tout'),
          ),
        ],
      ),
    );
  }
}
