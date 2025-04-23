import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/payment_method.dart';
import 'package:flutter_activity_app/models/transaction.dart';
import 'package:flutter_activity_app/models/wallet.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentMethodsLoaded extends PaymentState {
  final List<PaymentMethod> paymentMethods;

  const PaymentMethodsLoaded(this.paymentMethods);

  @override
  List<Object?> get props => [paymentMethods];
}

class PaymentMethodAdded extends PaymentState {
  final PaymentMethod paymentMethod;

  const PaymentMethodAdded(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}

class PaymentMethodDeleted extends PaymentState {
  final String id;

  const PaymentMethodDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class PaymentMethodSetAsDefault extends PaymentState {
  final String id;

  const PaymentMethodSetAsDefault(this.id);

  @override
  List<Object?> get props => [id];
}

class PaymentProcessed extends PaymentState {
  final String transactionId;
  final double amount;
  final String paymentMethodId;

  const PaymentProcessed({
    required this.transactionId,
    required this.amount,
    required this.paymentMethodId,
  });

  @override
  List<Object?> get props => [transactionId, amount, paymentMethodId];
}

// États liés au portefeuille
class WalletLoaded extends PaymentState {
  final Wallet wallet;
  final List<Transaction> recentTransactions;

  const WalletLoaded(this.wallet, this.recentTransactions);

  @override
  List<Object?> get props => [wallet, recentTransactions];
}

class WalletFundsAdded extends PaymentState {
  final Wallet wallet;
  final Transaction transaction;

  const WalletFundsAdded(this.wallet, this.transaction);

  @override
  List<Object?> get props => [wallet, transaction];
}

class WalletFundsWithdrawn extends PaymentState {
  final Wallet wallet;
  final Transaction transaction;

  const WalletFundsWithdrawn(this.wallet, this.transaction);

  @override
  List<Object?> get props => [wallet, transaction];
}

class FundsTransferred extends PaymentState {
  final Transaction transaction;

  const FundsTransferred(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}
