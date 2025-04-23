import 'package:flutter/material.dart';
import 'package:flutter_activity_app/bloc/notification/notification_bloc.dart';
import 'package:flutter_activity_app/bloc/notification/notification_event.dart';
import 'package:flutter_activity_app/models/notification.dart';
import 'package:flutter_activity_app/widgets/notification_popup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationOverlay {
  static final NotificationOverlay _instance = NotificationOverlay._internal();
  factory NotificationOverlay() => _instance;
  NotificationOverlay._internal();

  OverlayEntry? _overlayEntry;
  final List<AppNotification> _queue = [];
  bool _isShowingNotification = false;

  void show(
    BuildContext context,
    AppNotification notification, {
    VoidCallback? onTap,
  }) {
    print('🔔 Showing notification popup: ${notification.title}');
    
    // Ajouter à la file d'attente si une notification est déjà affichée
    if (_isShowingNotification) {
      print('📋 Adding notification to queue, already showing one');
      _queue.add(notification);
      return;
    }

    _isShowingNotification = true;
    _showOverlay(context, notification, onTap: onTap);
  }

  void _showOverlay(
    BuildContext context,
    AppNotification notification, {
    VoidCallback? onTap,
  }) {
    // Supprimer l'overlay existant s'il y en a un
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Vérifier si le contexte est valide
    if (!context.mounted) {
      print('❌ Context is not mounted, cannot show notification');
      _isShowingNotification = false;
      return;
    }

    // Obtenir le bloc de notification
    final NotificationBloc? notificationBloc = BlocProvider.of<NotificationBloc>(context, listen: false);
    if (notificationBloc == null) {
      print('❌ NotificationBloc not found in context');
      _isShowingNotification = false;
      return;
    }

    // Créer un nouvel overlay
    final overlayState = Overlay.of(context);
    if (overlayState == null) {
      print('❌ OverlayState not found in context');
      _isShowingNotification = false;
      return;
    }

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16.0,
        right: 16.0,
        child: Material(
          color: Colors.transparent,
          child: NotificationPopup(
            notification: notification,
            notificationBloc: notificationBloc,
            onTap: () {
              _dismiss();
              onTap?.call();
            },
            onDismiss: _dismiss,
          ),
        ),
      ),
    );

    // Stocker l'entrée d'overlay
    _overlayEntry = overlayEntry;

    // Insérer l'overlay
    try {
      overlayState.insert(overlayEntry);
      print('✅ Notification overlay inserted successfully');
    } catch (e) {
      print('❌ Error inserting overlay: $e');
      _isShowingNotification = false;
      return;
    }

    // Auto-fermeture après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      if (_overlayEntry != null) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    print('🔕 Dismissing notification popup');
    
    try {
      _overlayEntry?.remove();
    } catch (e) {
      print('❌ Error removing overlay: $e');
    }
    
    _overlayEntry = null;
    _isShowingNotification = false;

    // Afficher la notification suivante dans la file d'attente s'il y en a une
    if (_queue.isNotEmpty) {
      final nextNotification = _queue.removeAt(0);
      print('📋 Showing next notification from queue: ${nextNotification.title}');
      
      // Utiliser un petit délai pour permettre à la notification actuelle de se fermer complètement
      Future.delayed(const Duration(milliseconds: 300), () {
        final context = _findGlobalContext();
        if (context != null) {
          _isShowingNotification = true;
          _showOverlay(context, nextNotification);
        } else {
          print('❌ Could not find a valid context for next notification');
          _isShowingNotification = false;
        }
      });
    }
  }

  // Méthode auxiliaire pour trouver un BuildContext valide
  BuildContext? _findGlobalContext() {
    try {
      // Essayer de trouver un contexte valide
      final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
      if (context != null) {
        return context;
      }
      
      // Essayer une autre approche
      final rootContext = WidgetsBinding.instance.focusManager.rootScope.focusedChild?.context;
      if (rootContext != null) {
        return rootContext;
      }
      
      print('❌ Could not find a valid global context');
      return null;
    } catch (e) {
      print('❌ Error finding global context: $e');
      return null;
    }
  }

  void dismissAll() {
    print('🔕 Dismissing all notifications');
    _queue.clear();
    _dismiss();
  }
}
