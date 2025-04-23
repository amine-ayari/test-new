// TODO Implement this library.import 'package:equatable/equatable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/payment_method.dart';

enum TransactionType {
  deposit,
  withdrawal,
  payment,
  refund,
  transfer
}

class Transaction extends Equatable {
  final String id;
  final String walletId;
  final String userId;
  final double amount;
  final TransactionType type;
  final DateTime timestamp;
  final String description;
  final String status;
  final String? reference;
  final PaymentMethod? paymentMethod;
  final Map<String, dynamic> metadata;

  const Transaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.timestamp,
    required this.description,
    required this.status,
    this.reference,
    this.paymentMethod,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
    id, walletId, userId, amount, type, timestamp, description, 
    status, reference, paymentMethod, metadata
  ];

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      walletId: json['walletId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: _parseTransactionType(json['type']),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'completed',
      reference: json['reference'],
      paymentMethod: json['paymentMethod'] != null 
          ? PaymentMethod.fromJson(json['paymentMethod']) 
          : null,
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'status': status,
      'reference': reference,
      'paymentMethod': paymentMethod?.toJson(),
      'metadata': metadata,
    };
  }

  static TransactionType _parseTransactionType(String? typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'payment':
        return TransactionType.payment;
      case 'refund':
        return TransactionType.refund;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.payment;
    }
  }

  Transaction copyWith({
    String? id,
    String? walletId,
    String? userId,
    double? amount,
    TransactionType? type,
    DateTime? timestamp,
    String? description,
    String? status,
    String? reference,
    PaymentMethod? paymentMethod,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      metadata: metadata ?? this.metadata,
    );
  }
}
