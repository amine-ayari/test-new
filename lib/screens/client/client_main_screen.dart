import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/bloc/notification/notification_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/screens/client/discover/discover_screen.dart';
import 'package:flutter_activity_app/screens/client/activity/activities_screen.dart';
import 'package:flutter_activity_app/screens/client/profile/profile_screen.dart';
import 'package:flutter_activity_app/screens/client/reservation/user_reservations_screen.dart';
import 'package:flutter_activity_app/screens/client/favorites/favorites_screen.dart';
import 'package:flutter_activity_app/screens/client/notifications/notifications_screen.dart';
import 'package:flutter_activity_app/screens/client/messages/messages_screen.dart';
import 'package:flutter_activity_app/screens/client/chatbot/chatbot_screen.dart';
import 'package:flutter_activity_app/widgets/notification_overlay.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class ClientMainScreen extends StatefulWidget {
  final User user;

  const ClientMainScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late AuthBloc _authBloc;
  late NotificationBloc _notificationBloc;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Compteurs pour les notifications, messages, etc.
  int _notificationCount = 0;
  final int _messageCount = 5;
  final int _favoriteCount = 2;

  // État du chatbot
  bool _isChatbotOpen = false;
  bool _isChatbotVisible = true;
  bool _isChatbotMinimized = false;

  // Position du bouton flottant
  Offset _fabPosition =
      const Offset(20, 80); // position par défaut (right, bottom)
  bool _isDragging = false;
  bool _isOverDeleteZone = false;

  // Taille de l'écran
  late Size _screenSize;

  // Menu pour rouvrir le chatbot
  bool _showChatbotMenu = false;

  // Animation pour l'app bar
  bool _isScrolled = false;
  
  // Clé globale pour accéder au contexte de l'écran principal
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authBloc = getIt<AuthBloc>();
    _notificationBloc = getIt<NotificationBloc>();
    

    print(
        '🚀 Initialisation de ClientMainScreen pour l\'utilisateur: ${widget.user.id}');

    // Initialiser les notifications locales
    _initializeLocalNotifications();
    
    // Demander les autorisations de notification
    _requestNotificationPermissions();

    // Connecter au socket de notification
    _notificationBloc.add(ConnectToNotificationSocket(
      userId: widget.user.id,
      userType: 'client',
    ));

    // Charger les notifications existantes
    _notificationBloc.add(LoadNotifications(widget.user.id));
   
    _screens = [
      const DiscoverActivityScreen(),
      const ActivitiesScreen(),
      UserReservationsScreen(userId: widget.user.id),
      ProfileScreen(user: widget.user),
    ];

    _pageController = PageController(initialPage: _currentIndex);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _fabAnimationController.forward();
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer le tap sur la notification
        print('Notification tapped: ${response.payload}');
        
        // Extraire l'ID de notification du payload
        final notificationId = response.payload;
        if (notificationId != null) {
          // Marquer comme lu
          _notificationBloc.add(MarkNotificationAsRead(notificationId));
          
          // Naviguer vers l'écran des notifications
          _openNotifications();
        }
      },
    );
  }

  Future<void> _requestNotificationPermissions() async {
    // Demander les autorisations pour Android 13+ (API 33+)
    final status = await Permission.notification.request();
    print('📱 Statut des autorisations de notification: $status');
    
    if (status.isGranted) {
      print('✅ Autorisations de notification accordées');
    } else if (status.isDenied) {
      print('❌ Autorisations de notification refusées');
      // Afficher un message à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Les notifications sont désactivées. Certaines fonctionnalités peuvent ne pas fonctionner correctement.'),
            action: SnackBarAction(
              label: 'Paramètres',
              onPressed: () {
                openAppSettings();
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    // Déterminer l'icône et le canal en fonction du type de notification
    String channelId = 'general_channel';
    String channelName = 'Notifications générales';
    
    if (notification.isReservationUpdate) {
      channelId = 'reservation_channel';
      channelName = 'Notifications de réservation';
    } else if (notification.type == NotificationType.message || 
            (notification.type is String && notification.type == 'message')) {
      channelId = 'message_channel';
      channelName = 'Notifications de message';
    }
    
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Canal pour les notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        notification.message,
        contentTitle: notification.title,
        summaryText: 'Nouvelle notification',
      ),
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: notification.id,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Recharger les notifications lorsque l'application revient au premier plan
      _notificationBloc.add(LoadNotifications(widget.user.id));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _fabAnimationController.dispose();
    _notificationBloc.add(const DisconnectFromNotificationSocket());
    super.dispose();
  }

  void _navigateToPage(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });

    if (_isChatbotOpen) {
      _fabAnimationController.reverse();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const ChatScreen(),
      ).then((_) {
        if (!_isChatbotMinimized) {
          setState(() {
            _isChatbotOpen = false;
          });
          _fabAnimationController.forward();
        }
      });
    }
  }

  void _hideChatbot() {
    setState(() {
      _isChatbotVisible = false;
      _isOverDeleteZone = false;
      _isDragging = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chatbot masqué'),
        action: SnackBarAction(
          label: 'Restaurer',
          onPressed: () {
            setState(() {
              _isChatbotVisible = true;
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleChatbotMenu() {
    setState(() {
      _showChatbotMenu = !_showChatbotMenu;
    });
  }

  void _restoreChatbot() {
    setState(() {
      _isChatbotVisible = true;
      _showChatbotMenu = false;
    });

    // Animation pour faire apparaître le bouton
    _fabAnimationController.forward(from: 0);
  }

  // Correction du comportement du bouton flottant
  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Correction: Utiliser directement la position absolue du doigt
      // au lieu d'ajouter le delta à la position actuelle
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.globalToLocal(details.globalPosition);

      // Ajuster pour que le centre du bouton soit sous le doigt
      _fabPosition = Offset(
        _screenSize.width -
            position.dx -
            30, // 30 est la moitié de la taille du bouton
        _screenSize.height - position.dy - 30,
      );

      // Vérifier si le bouton est au-dessus de la zone de suppression
      final deleteZoneY = 100; // Zone de suppression en haut
      _isOverDeleteZone = position.dy < deleteZoneY;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isOverDeleteZone) {
      _hideChatbot();
    } else {
      // Ajuster la position pour qu'elle reste dans les limites de l'écran
      setState(() {
        _fabPosition = Offset(
          _fabPosition.dx.clamp(0, _screenSize.width - 60),
          _fabPosition.dy.clamp(0, _screenSize.height - 160),
        );
        _isDragging = false;
      });
    }
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => FavoritesScreen(user: widget.user)),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(userId: widget.user.id),
      ),
    ).then((_) {
      // Refresh notification count after returning from notifications screen
      _notificationBloc.add(LoadNotifications(widget.user.id));
    });
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MessagesScreen()),
    );
  }

  void _showNotification(AppNotification notification) {
    print('🔔 Attempting to show notification: ${notification.title}');
    
    // Afficher une notification locale si l'application est en arrière-plan
    final appState = WidgetsBinding.instance.lifecycleState;
    if (appState != AppLifecycleState.resumed) {
      print('📱 App in background, showing system notification');
      _showLocalNotification(notification);
      return;
    }
    
    // Utiliser le système de popup pour afficher la notification dans l'application
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔔 Showing in-app notification popup');
      
      // Show the Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notification.message),  // Display the notification message in Snackbar
          duration: Duration(seconds: 3),  // Customize the duration of the Snackbar
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              print('👆 Snackbar tapped');
              // Handle the user tapping the Snackbar
              _notificationBloc.add(MarkNotificationAsRead(notification.id));
    
              // Navigate based on the notification type
              if (notification.isReservationUpdate) {
                _navigateToPage(2); // Go to reservations tab
              } else if (notification.type == NotificationType.message || 
                        (notification.type is String && notification.type == 'message')) {
                _openMessages();
              } else {
                _openNotifications();
              }
            },
          ),
        ),
      );
    
    // If you still want to show your custom popup after Snackbar, you can use the following code
    NotificationOverlay().show(
      context,
      notification,
      onTap: () {
        print('👆 Notification tapped');
        _notificationBloc.add(MarkNotificationAsRead(notification.id));
    
        // Navigate based on the notification type
        if (notification.isReservationUpdate) {
          _navigateToPage(2); // Go to reservations tab
        } else if (notification.type == NotificationType.message || 
                  (notification.type is String && notification.type == 'message')) {
          _openMessages();
        } else {
          _openNotifications();
        }
      },
    );
  });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    _screenSize = MediaQuery.of(context).size;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          // Listener pour mettre à jour le compteur de notifications
          BlocListener<NotificationBloc, NotificationState>(
            listener: (context, state) {
              if (state is NotificationsLoaded) {
                setState(() {
                  _notificationCount = state.unreadCount;
                });
                print('🔢 Nombre de notifications non lues: ${state.unreadCount}');
              }
            },
          ),
          // Listener séparé pour les nouvelles notifications
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (previous, current) => current is NotificationReceivedState,
            listener: (context, state) {
              if (state is NotificationReceivedState) {
                print('📱 Nouvelle notification reçue dans ClientMainScreen: ${state.notification.title}');
                _showNotification(state.notification);
              }
            },
          ),
        ],
        child: Scaffold(
          key: _scaffoldKey,
          /* appBar: AppBar(
            elevation: _isScrolled ? 4 : 0,
            scrolledUnderElevation: 4.0,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${widget.user.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Découvrez les nouvelles',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Bouton pour rouvrir le chatbot
              if (!_isChatbotVisible)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: _toggleChatbotMenu,
                  tooltip: 'Ouvrir le chatbot',
                ),
              // Favoris avec badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: _openFavorites,
                    tooltip: 'Favoris',
                  ),
                  if (_favoriteCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _favoriteCount > 9
                              ? '9+'
                              : _favoriteCount.toString(),
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
              ),
              // Notifications avec badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: _openNotifications,
                    tooltip: 'Notifications',
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _notificationCount > 9
                              ? '9+'
                              : _notificationCount.toString(),
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
              ),
              // Messages avec badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message_outlined),
                    onPressed: _openMessages,
                    tooltip: 'Messages',
                  ),
                  if (_messageCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _messageCount > 9 ? '9+' : _messageCount.toString(),
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
              ),
            ],
          ),
          */ body: Stack(
            children: [
              // Contenu principal avec PageView
              NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollUpdateNotification) {
                    setState(() {
                      _isScrolled = scrollNotification.metrics.pixels > 0;
                    });
                  }
                  return false;
                },
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: _screens,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),

              // Zone de suppression (visible uniquement pendant le glissement)
              if (_isDragging)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.transparent,
                          _isOverDeleteZone
                              ? Colors.red.withOpacity(0.7)
                              : Colors.grey.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(_isOverDeleteZone ? 16 : 12),
                        decoration: BoxDecoration(
                          color: _isOverDeleteZone
                              ? Colors.red
                              : Colors.grey.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: _isOverDeleteZone ? 32 : 24,
                        ),
                      ),
                    ),
                  ),
                ),

              // Menu pour rouvrir le chatbot
              if (_showChatbotMenu)
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top,
                  right: 16,
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Assistant',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: primaryColor,
                          ),
                          title: const Text('Ouvrir le chatbot'),
                          onTap: () {
                            _restoreChatbot();
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              _toggleChatbot();
                            });
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.chat,
                            color: primaryColor,
                          ),
                          title: const Text('Restaurer le bouton'),
                          onTap: _restoreChatbot,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.close,
                            color: Colors.grey,
                          ),
                          title: const Text('Fermer'),
                          onTap: _toggleChatbotMenu,
                        ),
                      ],
                    ),
                  ),
                ),

              // Bouton flottant pour le chatbot
              if (_isChatbotVisible && !_isChatbotOpen)
                Positioned(
                  right: _fabPosition.dx,
                  bottom: _fabPosition.dy,
                  child: GestureDetector(
                    onPanStart: _onDragStart,
                    onPanUpdate: _onDragUpdate,
                    onPanEnd: _onDragEnd,
                    child: ScaleTransition(
                      scale: _fabScaleAnimation,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              _isOverDeleteZone ? Colors.red : primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isDragging ? null : _toggleChatbot,
                            customBorder: const CircleBorder(),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _isDragging
                                    ? Icon(
                                        _isOverDeleteZone
                                            ? Icons.delete
                                            : Icons.drag_handle,
                                        color: Colors.white,
                                        key: const ValueKey('drag'),
                                      )
                                    : const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.white,
                                        key: ValueKey('chat'),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Navigation bar moderne avec Material 3
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _navigateToPage,
            elevation: 8,
            backgroundColor: theme.cardColor,
            indicatorColor: primaryColor.withOpacity(0.2),
            labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,
            animationDuration: const Duration(milliseconds: 500),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore, color: primaryColor),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search, color: primaryColor),
                label: 'Activités',
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today, color: primaryColor),
                label: 'Réservations',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: primaryColor),
                label: 'Profile',
              ),
            ],
          ),
          // Bouton d'action flottant pour rouvrir le chatbot (alternative)
          floatingActionButton: !_isChatbotVisible
              ? FloatingActionButton(
                  onPressed: _restoreChatbot,
                  tooltip: 'Restaurer le chatbot',
                  backgroundColor: primaryColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white),
                )
              : null,
        ),
      ),
    );
  }
}
