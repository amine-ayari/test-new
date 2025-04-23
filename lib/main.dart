import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_activity_app/services/socket_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/auth/auth_state.dart';
import 'package:flutter_activity_app/bloc/chat/chat_bloc.dart';

import 'package:flutter_activity_app/config/app_config.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/providers/favorites_provider.dart';
import 'package:flutter_activity_app/providers/theme_provider.dart';

import 'package:flutter_activity_app/repositories/auth_repository_impl.dart';
import 'package:flutter_activity_app/repositories/chat_repository.dart';

import 'package:flutter_activity_app/screens/auth/login_screen.dart';
import 'package:flutter_activity_app/screens/client/client_main_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_main_screen.dart';

import 'package:flutter_activity_app/services/api_service.dart';
import 'package:flutter_activity_app/services/secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final sharedPreferences = await SharedPreferences.getInstance();
  final apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final secureStorage = SecureStorage();

  // Configure dependency injection
  await configureDependencies();

  // Optionally initialize Firebase (if needed later)
  await initializeFirebaseIfAvailable();

  runApp(MyApp(
    sharedPreferences: sharedPreferences,
    apiService: apiService,
    secureStorage: secureStorage,
  ));
}

Future<void> initializeFirebaseIfAvailable() async {
  try {
    // Uncomment if needed and Firebase is set up
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase not available: $e');
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final ApiService apiService;
  final SecureStorage secureStorage;

  const MyApp({
    Key? key,
    required this.sharedPreferences,
    required this.apiService,
    required this.secureStorage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
     final socketService = SocketService();
    socketService.connect(); // Make sure to connect to Socket.IO on app start

    return MultiProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AppStarted()),
        ),
         BlocProvider<ActivityBloc>(
          create: (_) => getIt<ActivityBloc>()..add(LoadActivities()),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => ChatBloc(
            chatRepository: ChatRepository(
              AuthRepositoryImpl(sharedPreferences, apiService, secureStorage),
            ),
          ),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Activity Discovery App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return state.user.isClient
                      ? ClientMainScreen(user: state.user)
                      : ProviderMainScreen(user: state.user);
                }
                return const LoginScreen();
              },
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
