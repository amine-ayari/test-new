import 'package:equatable/equatable.dart';

enum NotificationType {
  reservation,
  message,
  payment,
  system,
  reservation_status_update
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final dynamic type; // Peut être NotificationType ou String
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  // Méthode pour marquer la notification comme lue
  AppNotification markAsRead() {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: true,
      data: data,
    );
  }

  // Méthode pour créer une copie avec des modifications
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    dynamic type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Méthode utilitaire pour vérifier si c'est une notification de mise à jour de réservation
  bool get isReservationUpdate => 
      type == NotificationType.reservation_status_update || 
      (type is String && type == 'reservation_status_update');

  // Méthode pour convertir un objet JSON en AppNotification
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Convertir le type de notification
    dynamic notificationType;
    if (json['type'] is String) {
      try {
        notificationType = NotificationType.values.firstWhere(
          (e) => e.toString() == 'NotificationType.${json['type']}',
        );
      } catch (e) {
        // Si la conversion échoue, utiliser la chaîne brute
        notificationType = json['type'];
      }
    } else {
      notificationType = json['type'];
    }

    return AppNotification(
      id: json['_id'] ?? json['id'],
      userId: json['user'] ?? json['userId'],
      title: json['title'],
      message: json['message'],
      type: notificationType,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isRead: json['read'] ?? json['isRead'] ?? false,
      data: json['data'],
    );
  }

  // Méthode pour convertir AppNotification en objet JSON
  Map<String, dynamic> toJson() {
    String typeString;
    if (type is NotificationType) {
      typeString = type.toString().split('.').last;
    } else {
      typeString = type.toString();
    }

    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': typeString,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  @override
  List<Object?> get props => [id, userId, title, message, type, createdAt, isRead, data];
}