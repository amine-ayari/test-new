import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/bloc/notification/notification_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/screens/provider/provider_dashboard_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_activities_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_reservations_screen.dart';
import 'package:flutter_activity_app/screens/provider/profile/provider_profile_screen.dart';
import 'package:flutter_activity_app/screens/provider/profile/edit_provider_profile_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_notification_screen.dart';
import 'package:flutter_activity_app/screens/provider/qr_scanner/qr_scanner_screen.dart';

class ProviderMainScreen extends StatefulWidget {
  final User user;

  const ProviderMainScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late AuthBloc _authBloc;
  late NotificationBloc _notificationBloc;
  
  @override
  void initState() {
    super.initState();
    print('Userproviderrr: ${widget.user.toJson()}');
    _authBloc = getIt<AuthBloc>();
    _notificationBloc = getIt<NotificationBloc>();
    
    _screens = [
      ProviderDashboardScreen(providerId: widget.user.providerId!),
      ProviderActivitiesScreen(providerId: widget.user.providerId!),
      ProviderReservationsScreen(providerId: widget.user.providerId!),
      ProviderProfileScreen(user: widget.user),
    ];
    
    // Connect to notification socket for real-time updates
    _notificationBloc.add(ConnectToNotificationSocket(
      userId: widget.user.providerId!,
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
    final theme = Theme.of(context);
    
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: _getAppBarTitle(),
          elevation: 0,
          actions: [
            // Edit Profile button - only show on Profile tab
            if (_currentIndex == 3)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProviderProfileScreen(user: widget.user),
                    ),
                  );
                },
              ),
            // QR Code Scanner Button
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan Client QR Code',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScannerScreen(
                      providerId: widget.user.providerId!,
                    ),
                  ),
                );
              },
            ),
            // Notifications Button with Badge
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
                              providerId: widget.user.providerId!,
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
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        // Floating Action Button for QR Scanner
      /*   floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRScannerScreen(
                  providerId: widget.user.providerId!,
                ),
              ),
            );
          },
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scan Client QR Code',
        ), */
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.hiking_outlined),
              selectedIcon: Icon(Icons.hiking),
              label: 'Activities',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Reservations',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return const Text('Dashboard');
      case 1:
        return const Text('My Activities');
      case 2:
        return const Text('Reservations');
      case 3:
        return const Text('Profile');
      default:
        return const Text('Provider Portal');
    }
  }
}
