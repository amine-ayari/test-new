import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/transaction.dart';

class Wallet extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final List<Transaction> transactions;
  final DateTime lastUpdated;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.transactions = const [],
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [id, userId, balance, transactions, lastUpdated];

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    List<Transaction>? transactions,
    DateTime? lastUpdated,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      userId: json['userId'],
      balance: json['balance'].toDouble(),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((item) => Transaction.fromJson(item))
              .toList()
          : [],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create an empty wallet for a user
  factory Wallet.empty(String userId) {
    return Wallet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      balance: 0.0,
      transactions: [],
      lastUpdated: DateTime.now(),
    );
  }
}
