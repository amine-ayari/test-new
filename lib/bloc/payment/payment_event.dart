import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/payment_method.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentMethods extends PaymentEvent {
  const LoadPaymentMethods();
}

class AddPaymentMethod extends PaymentEvent {
  final PaymentMethod paymentMethod;

  const AddPaymentMethod(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}

class DeletePaymentMethod extends PaymentEvent {
  final String id;

  const DeletePaymentMethod(this.id);

  @override
  List<Object?> get props => [id];
}

class SetDefaultPaymentMethod extends PaymentEvent {
  final String id;

  const SetDefaultPaymentMethod(this.id);

  @override
  List<Object?> get props => [id];
}

class ProcessPayment extends PaymentEvent {
  final String paymentMethodId;
  final double amount;
  final String description;
  final Map<String, dynamic> metadata;

  const ProcessPayment({
    required this.paymentMethodId,
    required this.amount,
    required this.description,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [paymentMethodId, amount, description, metadata];
}

// Événements liés au portefeuille
class LoadWallet extends PaymentEvent {
  final String userId;

  const LoadWallet(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddFundsToWallet extends PaymentEvent {
  final String userId;
  final double amount;
  final String paymentMethodId;

  const AddFundsToWallet({
    required this.userId,
    required this.amount,
    required this.paymentMethodId,
  });

  @override
  List<Object?> get props => [userId, amount, paymentMethodId];
}

class WithdrawFromWallet extends PaymentEvent {
  final String userId;
  final double amount;
  final String? destinationAccount;

  const WithdrawFromWallet({
    required this.userId,
    required this.amount,
    this.destinationAccount,
  });

  @override
  List<Object?> get props => [userId, amount, destinationAccount];
}

class TransferFunds extends PaymentEvent {
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String? message;

  const TransferFunds({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.message,
  });

  @override
  List<Object?> get props => [fromUserId, toUserId, amount, message];
}
