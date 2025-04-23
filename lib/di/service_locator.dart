import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/chat/chat_bloc.dart';
import 'package:flutter_activity_app/bloc/location/location_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/participant/participant_bloc.dart';
/* import 'package:flutter_activity_app/bloc/discover/discover_bloc.dart'; */
import 'package:flutter_activity_app/bloc/payment/payment_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/review/review_bloc.dart';
import 'package:flutter_activity_app/bloc/user/user_bloc.dart';
import 'package:flutter_activity_app/bloc/verification/verification_bloc.dart';
import 'package:flutter_activity_app/config/app_config.dart';
import 'package:flutter_activity_app/repositories/activity_repository.dart';
import 'package:flutter_activity_app/repositories/activity_repository_impl.dart';
import 'package:flutter_activity_app/repositories/auth_repository.dart';
import 'package:flutter_activity_app/repositories/auth_repository_impl.dart';
import 'package:flutter_activity_app/repositories/chat_repository.dart';
import 'package:flutter_activity_app/repositories/notification_repository.dart';
import 'package:flutter_activity_app/repositories/notification_repository_impl.dart';
// Remove the duplicate import
// import 'package:flutter_activity_app/repositories/participant_repository copy.dart';
import 'package:flutter_activity_app/repositories/participant_repository.dart';
import 'package:flutter_activity_app/repositories/participant_repository_impl.dart';
import 'package:flutter_activity_app/repositories/payment_repository.dart';
import 'package:flutter_activity_app/repositories/payment_repository_impl.dart';
import 'package:flutter_activity_app/repositories/provider_repository.dart';
import 'package:flutter_activity_app/repositories/provider_repository_impl.dart';
import 'package:flutter_activity_app/repositories/reservation_repository.dart';
import 'package:flutter_activity_app/repositories/reservation_repository_impl.dart';
import 'package:flutter_activity_app/repositories/review_repository.dart';
import 'package:flutter_activity_app/repositories/review_repository_imp.dart';
 // Fix the import name
import 'package:flutter_activity_app/repositories/user_repository.dart';
import 'package:flutter_activity_app/repositories/user_repository_impl.dart';
import 'package:flutter_activity_app/repositories/verification_repository.dart';
import 'package:flutter_activity_app/repositories/verification_repository_impl.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:flutter_activity_app/services/secure_storage.dart';
import 'package:flutter_activity_app/services/social_auth_service.dart';
import 'package:flutter_activity_app/services/socket_service.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:flutter_activity_app/repositories/coupon_repository.dart';
import 'package:flutter_activity_app/repositories/wallet_repository.dart';
import 'package:flutter_activity_app/services/payment_service.dart';
import 'package:flutter_activity_app/bloc/coupon/coupon_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  // Register SharedPreferences as a singleton
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register services
  getIt.registerSingleton<ApiService>(
    ApiService(baseUrl: AppConfig.getApiBaseUrl()),
  );
  
  getIt.registerSingleton<SocketService>(
    SocketService(),
  );

  // Register repositories
  getIt.registerSingleton<ActivityRepository>(
    ActivityRepositoryImpl(
      getIt<SharedPreferences>(),
      getIt<ApiService>(),
    ),
  );
  
  getIt.registerSingleton<ReservationRepository>(
    ReservationRepositoryImpl(getIt<ApiService>()),
  );
  
  getIt.registerSingleton<ProviderRepository>(
    ProviderRepositoryImpl(
      getIt<SharedPreferences>(),
      getIt<ApiService>(),
    ),
  );
  
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(
      getIt<SharedPreferences>(),
      getIt<ApiService>(),
    ),
  );
  
  // Update the AuthRepositoryImpl registration
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    getIt<SharedPreferences>(),
    getIt<ApiService>(),
    getIt<SecureStorage>(), // Add this parameter
  ));
  
  getIt.registerSingleton<PaymentRepository>(
    PaymentRepositoryImpl(
      getIt<SharedPreferences>(),
      getIt<ApiService>(),
    ),
  );
  
  getIt.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(
      getIt<SharedPreferences>(),
      getIt<ApiService>(),
    ),
  );

  /* // Register BLoCs
  getIt.registerFactory<DiscoverBloc>(
    () => DiscoverBloc(getIt<ActivityRepository>()),
  );  */
  
  getIt.registerFactory<ActivityBloc>(
    () => ActivityBloc(getIt<ActivityRepository>()),
  );
  
  getIt.registerFactory<ReservationBloc>(
    () => ReservationBloc(getIt<ReservationRepository>()),
  );
  
  getIt.registerFactory<ProviderBloc>(
    () => ProviderBloc(getIt<ProviderRepository>()),
  );
  
  getIt.registerFactory<UserBloc>(
    () => UserBloc(getIt<UserRepository>()),
  );
  
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
    getIt<AuthRepository>(),
    getIt<SocialAuthService>(),
  ));
  
  getIt.registerFactory<PaymentBloc>(
    () => PaymentBloc(
      getIt<PaymentRepository>(),
      getIt<WalletRepository>(),
    ),
  );
  
  getIt.registerFactory<NotificationBloc>(
    () => NotificationBloc(
      notificationRepository: getIt<NotificationRepository>(),
      socketService: getIt<SocketService>(),
    ),
  );
  
  getIt.registerLazySingleton<LocationBloc>(() => LocationBloc());
  
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(chatRepository: getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton<SocialAuthService>(() => SocialAuthService());

  // Register Review and Participant repositories and BLoCs (only once)
  getIt.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(getIt<ApiService>()),
  );

  getIt.registerLazySingleton<ParticipantRepository>(
    () => ParticipantRepositoryImpl(getIt<ApiService>()),
  );

  // Register BLoCs
  getIt.registerFactory<ReviewBloc>(
    () => ReviewBloc(getIt<ReviewRepository>()),
  );

  getIt.registerFactory<ParticipantBloc>(
    () => ParticipantBloc(getIt<ParticipantRepository>()),
  );


  // Register repositories
getIt.registerLazySingleton<VerificationRepository>(
  () => VerificationRepositoryImpl(apiService: getIt<ApiService>()),
);

// Register BLoCs
getIt.registerFactory<VerificationBloc>(
  () => VerificationBloc(
    verificationRepository: getIt<VerificationRepository>(),
    providerRepository: getIt<ProviderRepository>(),
  ),
);


// Services
  getIt.registerLazySingleton<PaymentService>(() => PaymentServiceImpl());

  // Payment Repository and Bloc
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(getIt<SharedPreferences>(), getIt<ApiService>()),
  );
  
  // Wallet Repository
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(getIt<SharedPreferences>()),
  );
  
  getIt.registerFactory<PaymentBloc>(
    () => PaymentBloc(
      getIt<PaymentRepository>(),
      getIt<WalletRepository>(),
    ),
  );

  // Coupon Repository and Bloc
  getIt.registerLazySingleton<CouponRepository>(
    () => CouponRepositoryImpl(getIt<ApiService>(), getIt<SharedPreferences>()),
  );
  getIt.registerFactory<CouponBloc>(
    () => CouponBloc(getIt<CouponRepository>()),
  );

  // Reservation Repository and Bloc
  getIt.registerLazySingleton<ReservationRepository>(
    () => ReservationRepositoryImpl(getIt<ApiService>()),
  );
  getIt.registerFactory<ReservationBloc>(
    () => ReservationBloc(getIt<ReservationRepository>()),
  );
}