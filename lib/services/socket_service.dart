import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/config/app_config.dart';

class SocketService {
  late io.Socket _socket;
  final StreamController<AppNotification> _notificationController = StreamController<AppNotification>.broadcast();
  final StreamController<Reservation> _reservationController = StreamController<Reservation>.broadcast();
  
  bool _isConnected = false;
  String? _pendingUserId;

  SocketService() {
    _initSocket();
  }

  void _initSocket() {
    _socket = io.io("https://activityapp-backend.onrender.com", <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket.onConnect((_) {
      print('🟢 Socket connecté avec succès: ${_socket.id}');
      _isConnected = true;
      
      // Authentifier automatiquement si un ID est en attente
      if (_pendingUserId != null) {
        authenticate(_pendingUserId!);
        _pendingUserId = null;
      }
    });

    _socket.onConnectError((error) {
      print('🔴 Erreur de connexion Socket: $error');
    });

    _socket.onDisconnect((_) {
      print('🟠 Socket déconnecté');
      _isConnected = false;
    });

    _socket.on('notification', (data) {
      print('📣 Notification reçue: $data');
      try {
        final notification = AppNotification.fromJson(data);
        _notificationController.add(notification);
      } catch (e) {
        print('❌ Erreur lors du parsing de la notification: $e');
        print('Données reçues: $data');
      }
    });

    _socket.on('reservation_update', (data) {
      print('🔄 Mise à jour de réservation reçue: $data');
      try {
        final reservation = Reservation.fromJson(data);
        _reservationController.add(reservation);
      } catch (e) {
        print('❌ Erreur lors du parsing de la réservation: $e');
        print('Données reçues: $data');
      }
    });
  }

  Future<void> connect() async {
    if (!_isConnected) {
      print('🔄 Tentative de connexion Socket.IO...');
      _socket.connect();
      
      // Attendre que la connexion soit établie
      int attempts = 0;
      while (!_isConnected && attempts < 5) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
        print('Tentative $attempts...');
      }
      
      if (_isConnected) {
        print('✅ Socket connecté après $attempts tentatives');
      } else {
        print('❌ Échec de connexion après $attempts tentatives');
      }
    }
  }

  Future<void> disconnect() async {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
    }
  }

  Future<void> subscribe(String channel) async {
    if (_isConnected) {
      print('📲 Abonnement au canal: $channel');
      _socket.emit('subscribe', {'channel': channel});
    } else {
      throw Exception('Socket non connecté');
    }
  }

  Future<void> unsubscribe(String channel) async {
    if (_isConnected) {
      print('🚫 Désabonnement du canal: $channel');
      _socket.emit('unsubscribe', {'channel': channel});
    } else {
      throw Exception('Socket non connecté');
    }
  }

  void authenticate(String userId) {
    if (_isConnected) {
      print('🔑 Authentification de l\'utilisateur: $userId');
      _socket.emit('authenticate', userId);
    } else {
      print('⚠️ Tentative d\'authentification sans connexion');
      // Stocker l'ID pour authentification après connexion
      _pendingUserId = userId;
    }
  }

  Stream<AppNotification> onNotification() {
    return _notificationController.stream;
  }

  Stream<Reservation> onReservationUpdate() {
    return _reservationController.stream;
  }

  void dispose() {
    _notificationController.close();
    _reservationController.close();
    disconnect();
  }
  
  // Stream pour écouter les notifications globalement
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  // Méthode pour envoyer un message via socket
  void sendMessage(String event, dynamic data) {
    if (_isConnected) {
      print('📤 Envoi de message: $event');
      _socket.emit(event, data);
    } else {
      print('⚠️ Tentative d\'envoi de message sans connexion');
    }
  }
}