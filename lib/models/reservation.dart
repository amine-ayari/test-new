import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/activity.dart';

enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  rejected
}

class Reservation extends Equatable {
  final String id;
  final String activityId;
  final String activityName; // Ajout du nom de l'activité
  final String userId;
  final DateTime date;
  final String timeSlot;
  final int numberOfPeople;
  final double totalPrice;
  final ReservationStatus status;
  final DateTime createdAt;
  final String notes;
  final String cancellationReason;
  final String paymentStatus; // Ajout du statut de paiement
  final Activity? activity; // Optional reference to the activity

  const Reservation({
    required this.id,
    required this.activityId,
    required this.activityName,
    required this.userId,
    required this.date,
    required this.timeSlot,
    required this.numberOfPeople,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.notes,
    required this.cancellationReason,
    required this.paymentStatus,
    this.activity,
  });

  @override
  List<Object?> get props => [
    id, activityId, activityName, userId, date, timeSlot, numberOfPeople, 
    totalPrice, status, createdAt, notes, cancellationReason, paymentStatus, activity
  ];

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Gestion de l'activityId qui peut être un objet ou une chaîne
    String extractedActivityId;
    String activityName = 'Unknown Activity';
    
    if (json['activityId'] is Map) {
      extractedActivityId = json['activityId']['_id'] ?? '';
      activityName = json['activityId']['name'] ?? 'Unknown Activity';
    } else {
      extractedActivityId = json['activityId'] ?? '';
    }

    // Conversion du statut
    ReservationStatus convertedStatus;
    if (json['status'] is String) {
      switch (json['status']) {
        case 'pending':
          convertedStatus = ReservationStatus.pending;
          break;
        case 'accepted':
        case 'confirmed':
          convertedStatus = ReservationStatus.confirmed;
          break;
        case 'rejected':
          convertedStatus = ReservationStatus.rejected;
          break;
        case 'cancelled':
          convertedStatus = ReservationStatus.cancelled;
          break;
        case 'completed':
          convertedStatus = ReservationStatus.completed;
          break;
        default:
          convertedStatus = ReservationStatus.pending;
      }
    } else {
      convertedStatus = ReservationStatus.pending;
    }

    return Reservation(
      id: json['_id'] ?? json['id'] ?? '',
      activityId: extractedActivityId,
      activityName: activityName,
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : (json['userId'] ?? ''),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      timeSlot: json['timeSlot'] ?? 'No time slot available',
      numberOfPeople: json['numberOfPeople'] ?? 1,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: convertedStatus,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      notes: json['notes'] ?? 'No notes available',
      cancellationReason: json['cancellationReason'] ?? 'No cancellation reason',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      activity: json['activity'] != null ? Activity.fromJson(json['activity']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'activityName': activityName,
      'userId': userId,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'numberOfPeople': numberOfPeople,
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'cancellationReason': cancellationReason,
      'paymentStatus': paymentStatus,
      'activity': activity?.toJson(),
    };
  }

  Reservation copyWith({
    String? id,
    String? activityId,
    String? activityName,
    String? userId,
    DateTime? date,
    String? timeSlot,
    int? numberOfPeople,
    double? totalPrice,
    ReservationStatus? status,
    DateTime? createdAt,
    String? notes,
    String? cancellationReason,
    String? paymentStatus,
    Activity? activity,
  }) {
    return Reservation(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      activityName: activityName ?? this.activityName,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      activity: activity ?? this.activity,
    );
  }
  
  bool get isPending => status == ReservationStatus.pending;
  bool get isConfirmed => status == ReservationStatus.confirmed;
  bool get isCancelled => status == ReservationStatus.cancelled;
  bool get isCompleted => status == ReservationStatus.completed;
  bool get isRejected => status == ReservationStatus.rejected;
  
  bool get canCancel => isPending || isConfirmed;
  bool get canConfirm => isPending;
  bool get canReject => isPending;
  bool get canComplete => isConfirmed;

  String get userName => "null";
}

class ReservationWithActivity {
  final Reservation reservation;
  final Activity activity;

  ReservationWithActivity({
    required this.reservation,
    required this.activity,
  });
  
  // Factory method to create from a Reservation that already has an activity
  factory ReservationWithActivity.fromReservation(Reservation reservation) {
    if (reservation.activity == null) {
      throw Exception('Reservation does not have an activity');
    }
    return ReservationWithActivity(
      reservation: reservation,
      activity: reservation.activity!,
    );
  }
}