import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/bloc/notification/notification_state.dart';
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/repositories/notification_repository.dart';
import 'package:flutter_activity_app/services/socket_service.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  final SocketService _socketService;
  StreamSubscription? _socketSubscription;
  String? _currentUserId;

  NotificationBloc({
    required NotificationRepository notificationRepository,
    required SocketService socketService,
  }) : _notificationRepository = notificationRepository,
       _socketService = socketService,
       super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
    on<LoadNotificationSettings>(_onLoadNotificationSettings);
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<ConnectToNotificationSocket>(_onConnectToNotificationSocket);
    on<DisconnectFromNotificationSocket>(_onDisconnectFromNotificationSocket);
    on<NewNotificationReceived>(_onNewNotificationReceived);
    on<NotificationReceived>(_onNotificationReceived);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      _currentUserId = event.userId; // Stocker l'ID utilisateur actuel
      final notifications = await _notificationRepository.getNotifications(event.userId);
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      print('❌ Erreur lors du chargement des notifications: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markNotificationAsRead(event.notificationId);
      
      // Update the state with the read notification
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = currentState.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification.markAsRead();
          }
          return notification;
        }).toList();
        
        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        ));
      }
    } catch (e) {
      print('❌ Erreur lors du marquage de la notification comme lue: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAllNotificationsAsRead(event.userId);
      
      // Update the state with all notifications read
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = currentState.notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: 0,
        ));
      }
    } catch (e) {
      print('❌ Erreur lors du marquage de toutes les notifications comme lues: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteNotification(event.notificationId);
      
      // Update the state without the deleted notification
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = currentState.notifications
            .where((notification) => notification.id != event.notificationId)
            .toList();
        
        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        ));
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression de la notification: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.clearAllNotifications(event.userId);
      
      // Update the state with empty notifications
      emit(const NotificationsLoaded(
        notifications: [],
        unreadCount: 0,
      ));
    } catch (e) {
      print('❌ Erreur lors de la suppression de toutes les notifications: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettings event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final settings = await _notificationRepository.getNotificationSettings(event.userId);
      emit(NotificationSettingsLoaded(
        activityReminders: settings.activityReminders,
        bookingConfirmations: settings.bookingConfirmations,
        promotions: settings.promotions,
        newsletter: settings.newsletter,
        appUpdates: settings.appUpdates,
        quietHoursEnabled: settings.quietHoursEnabled,
        quietHoursStart: settings.quietHoursStart,
        quietHoursEnd: settings.quietHoursEnd,
      ));
    } catch (e) {
      print('❌ Erreur lors du chargement des paramètres de notification: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettings event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.updateNotificationSettings(
        activityReminders: event.activityReminders,
        bookingConfirmations: event.bookingConfirmations,
        promotions: event.promotions,
        newsletter: event.newsletter,
        appUpdates: event.appUpdates,
        quietHoursEnabled: event.quietHoursEnabled,
        quietHoursStart: event.quietHoursStart,
        quietHoursEnd: event.quietHoursEnd,
      );
      
      emit(NotificationSettingsLoaded(
        activityReminders: event.activityReminders,
        bookingConfirmations: event.bookingConfirmations,
        promotions: event.promotions,
        newsletter: event.newsletter,
        appUpdates: event.appUpdates,
        quietHoursEnabled: event.quietHoursEnabled,
        quietHoursStart: event.quietHoursStart,
        quietHoursEnd: event.quietHoursEnd,
      ));
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des paramètres de notification: $e');
      emit(NotificationError(e.toString()));
    }
  }

  // Méthode corrigée pour éviter l'erreur d'émission après la fin du gestionnaire d'événements
  Future<void> _onConnectToNotificationSocket(
    ConnectToNotificationSocket event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      _currentUserId = event.userId; // Stocker l'ID utilisateur actuel
      
      // Connecter au socket et attendre la connexion
      await _socketService.connect();
      print('🔌 Socket connecté pour les notifications');

      // Authentifier l'utilisateur
      _socketService.authenticate(event.userId);
      print('🔑 Utilisateur authentifié: ${event.userId}');

      // S'abonner au canal approprié
      final channel = event.userType == 'provider' 
          ? 'provider-${event.userId}' 
          : 'user-${event.userId}';
      await _socketService.subscribe(channel);
      print('📲 Abonné au canal: $channel');

      // Émettre l'état de connexion réussie
      emit(NotificationSocketConnected());

      // IMPORTANT: Configurer l'écoute des notifications APRÈS avoir émis l'état de connexion
      await _setupSocketListener();
      
    } catch (e) {
      print('❌ Erreur de connexion socket: $e');
      emit(NotificationError('Échec de connexion au service de notification: ${e.toString()}'));
    }
  }

  // Méthode séparée pour configurer l'écouteur de socket
  Future<void> _setupSocketListener() async {
    // Annuler toute souscription existante
    await _socketSubscription?.cancel();
    
    // Créer une nouvelle souscription
    _socketSubscription = _socketService.onNotification().listen(
      (notification) {
        print('📬 Notification reçue dans le bloc: ${notification.title}');
        
        // Ajouter un événement pour la nouvelle notification reçue
        // au lieu d'émettre directement un état
        add(NotificationReceived(notification));
      },
      onError: (error) {
        print('❌ Erreur dans la souscription aux notifications: $error');
      },
    );
  }

  // Gestionnaire pour l'événement de nouvelle notification
  Future<void> _onNewNotificationReceived(
    NewNotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    // Émettre d'abord l'état de nouvelle notification
    emit(NotificationReceivedState(event.notification));
    
    try {
      // Sauvegarder la notification dans le repository
      await _notificationRepository.saveSocketNotification(event.notification);
      
      // Recharger les notifications si l'ID utilisateur est disponible
      if (_currentUserId != null) {
        add(LoadNotifications(_currentUserId!));
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  // Gestionnaire pour l'événement de notification reçue
  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    // Émettre l'état pour la nouvelle notification
    emit(NotificationReceivedState(event.notification));
    
    try {
      // Sauvegarder la notification dans le repository
      await _notificationRepository.saveSocketNotification(event.notification);
      
      // Recharger les notifications si l'ID utilisateur est disponible
      if (_currentUserId != null) {
        add(LoadNotifications(_currentUserId!));
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  Future<void> _onDisconnectFromNotificationSocket(
    DisconnectFromNotificationSocket event,
    Emitter<NotificationState> emit,
  ) async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _socketService.disconnect();
    emit(NotificationSocketDisconnected());
  }

  @override
  Future<void> close() async {
    await _socketSubscription?.cancel();
    await _socketService.disconnect();
    return super.close();
  }
}
