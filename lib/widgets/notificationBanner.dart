import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_activity_app/services/socket_service.dart';
import 'package:flutter_activity_app/models/notification.dart';

class NotificationBanner extends StatefulWidget {
  @override
  _NotificationBannerState createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> {
  late StreamSubscription<AppNotification> notificationSubscription;
  String _notificationMessage = '';
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // S'abonner aux notifications via le SocketService
    notificationSubscription = SocketService().notificationStream.listen((notification) {
      setState(() {
        _notificationMessage = notification.message;
        _isVisible = true;
      });

      // Masquer la notification après quelques secondes
      Future.delayed(Duration(seconds: 5), () {
        setState(() {
          _isVisible = false;
        });
      });
    });
  }

  @override
  void dispose() {
    notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isVisible
        ? Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(16),
                color: Colors.blueAccent,
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _notificationMessage,
                        style: TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isVisible = false;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
          )
        : SizedBox.shrink();
  }
}
