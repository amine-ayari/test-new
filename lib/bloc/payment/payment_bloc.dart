import 'dart:async';
import 'package:flutter_activity_app/models/payment_method.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/payment/payment_event.dart';
import 'package:flutter_activity_app/bloc/payment/payment_state.dart';

import 'package:flutter_activity_app/models/transaction.dart';
import 'package:flutter_activity_app/models/wallet.dart';
import 'package:flutter_activity_app/repositories/payment_repository.dart';
import 'package:flutter_activity_app/repositories/wallet_repository.dart';
import 'package:uuid/uuid.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  final WalletRepository _walletRepository;

  PaymentBloc(this._paymentRepository, this._walletRepository) : super(const PaymentInitial()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<AddPaymentMethod>(_onAddPaymentMethod);
    on<DeletePaymentMethod>(_onDeletePaymentMethod);
    on<SetDefaultPaymentMethod>(_onSetDefaultPaymentMethod);
    on<ProcessPayment>(_onProcessPayment);
    on<LoadWallet>(_onLoadWallet);
    on<AddFundsToWallet>(_onAddFundsToWallet);
    on<WithdrawFromWallet>(_onWithdrawFromWallet);
    on<TransferFunds>(_onTransferFunds);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final paymentMethods = await _paymentRepository.getPaymentMethods();
      emit(PaymentMethodsLoaded(paymentMethods));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onAddPaymentMethod(
    AddPaymentMethod event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final paymentMethod = await _paymentRepository.addPaymentMethod(event.paymentMethod);
      emit(PaymentMethodAdded(paymentMethod as PaymentMethod));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onDeletePaymentMethod(
    DeletePaymentMethod event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      await _paymentRepository.deletePaymentMethod(event.id);
      emit(PaymentMethodDeleted(event.id));
      
      // Reload payment methods after deletion
      add(const LoadPaymentMethods());
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onSetDefaultPaymentMethod(
    SetDefaultPaymentMethod event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      await _paymentRepository.setDefaultPaymentMethod(event.id);
      emit(PaymentMethodSetAsDefault(event.id));
      
      // Reload payment methods after setting default
      add(const LoadPaymentMethods());
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final paymentMethod = await _paymentRepository.getPaymentMethodById(event.paymentMethodId);
      
      if (paymentMethod == null) {
        emit(PaymentError('Payment method not found.'));
        return;
      }
      
      final result = await _paymentRepository.processPayment(
        paymentMethod: paymentMethod,
        amount: event.amount,
        description: event.description,
        metadata: event.metadata,
      );
      
      emit(PaymentProcessed(
        transactionId: result['transactionId'],
        amount: event.amount,
        paymentMethodId: event.paymentMethodId,
      ));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onLoadWallet(
    LoadWallet event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      // Récupérer le portefeuille
      final wallet = await _walletRepository.getWalletByUserId(event.userId);
      
      // Récupérer les transactions récentes
      final transactions = await _walletRepository.getTransactionsByUserId(
        event.userId,
        limit: 20,
      );
      
      emit(WalletLoaded(wallet, transactions));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onAddFundsToWallet(
    AddFundsToWallet event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      // Récupérer la méthode de paiement
      final paymentMethod = await _paymentRepository.getPaymentMethodById(event.paymentMethodId);
      
      if (paymentMethod == null) {
        emit(PaymentError('Payment method not found.'));
        return;
      }
      
      // Récupérer ou créer le portefeuille
      Wallet wallet;
      try {
        wallet = await _walletRepository.getWalletByUserId(event.userId);
      } catch (e) {
        // Si le portefeuille n'existe pas, en créer un nouveau
        wallet = await _walletRepository.createWallet(event.userId);
      }
      
      // Traiter le paiement
      final paymentResult = await _paymentRepository.processTransaction(
        paymentMethod: paymentMethod,
        amount: event.amount,
        description: 'Ajout de fonds au portefeuille',
        metadata: {
          'walletId': wallet.id,
          'userId': event.userId,
          'type': 'wallet_deposit',
        },
      );
      
      // Créer une transaction
      final transaction = Transaction(
        id: const Uuid().v4(),
        walletId: wallet.id,
        userId: event.userId,
        amount: event.amount,
        type: TransactionType.deposit,
        timestamp: DateTime.now(),
        description: 'Ajout de fonds au portefeuille',
        status: 'completed',
        reference: paymentResult['transactionId'],
        paymentMethod: paymentMethod,
        metadata: {
          'paymentId': paymentResult['transactionId'],
        },
      );
      
      // Ajouter la transaction
      await _walletRepository.addTransaction(transaction);
      
      // Mettre à jour le solde du portefeuille
      final updatedWallet = wallet.copyWith(
        balance: wallet.balance + event.amount,
        lastUpdated: DateTime.now(),
      );
      
      // Enregistrer le portefeuille mis à jour
      await _walletRepository.updateWallet(updatedWallet);
      
      emit(WalletFundsAdded(updatedWallet, transaction));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onWithdrawFromWallet(
    WithdrawFromWallet event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      // Récupérer le portefeuille
      final wallet = await _walletRepository.getWalletByUserId(event.userId);
      
      // Vérifier si le solde est suffisant
      if (wallet.balance < event.amount) {
        emit(const PaymentError('Solde insuffisant'));
        return;
      }
      
      // Créer une transaction
      final transaction = Transaction(
        id: const Uuid().v4(),
        walletId: wallet.id,
        userId: event.userId,
        amount: event.amount,
        type: TransactionType.withdrawal,
        timestamp: DateTime.now(),
        description: 'Retrait de fonds du portefeuille',
        status: 'completed',
        metadata: {
          'destinationAccount': event.destinationAccount,
        },
      );
      
      // Ajouter la transaction
      await _walletRepository.addTransaction(transaction);
      
      // Mettre à jour le solde du portefeuille
      final updatedWallet = wallet.copyWith(
        balance: wallet.balance - event.amount,
        lastUpdated: DateTime.now(),
      );
      
      // Enregistrer le portefeuille mis à jour
      await _walletRepository.updateWallet(updatedWallet);
      
      emit(WalletFundsWithdrawn(updatedWallet, transaction));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onTransferFunds(
    TransferFunds event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      // Récupérer le portefeuille source
      final sourceWallet = await _walletRepository.getWalletByUserId(event.fromUserId);
      
      // Vérifier si le solde est suffisant
      if (sourceWallet.balance < event.amount) {
        emit(const PaymentError('Solde insuffisant'));
        return;
      }
      
      // Récupérer ou créer le portefeuille destination
      Wallet destinationWallet;
      try {
        destinationWallet = await _walletRepository.getWalletByUserId(event.toUserId);
      } catch (e) {
        // Si le portefeuille n'existe pas, en créer un nouveau
        destinationWallet = await _walletRepository.createWallet(event.toUserId);
      }
      
      // Créer une transaction pour le transfert
      final transaction = Transaction(
        id: const Uuid().v4(),
        walletId: sourceWallet.id,
        userId: event.fromUserId,
        amount: event.amount,
        type: TransactionType.transfer,
        timestamp: DateTime.now(),
        description: 'Transfert de fonds',
        status: 'completed',
        metadata: {
          'toUserId': event.toUserId,
          'toWalletId': destinationWallet.id,
          'message': event.message,
        },
      );
      
      // Ajouter la transaction
      await _walletRepository.addTransaction(transaction);
      
      // Mettre à jour le solde du portefeuille source
      final updatedSourceWallet = sourceWallet.copyWith(
        balance: sourceWallet.balance - event.amount,
        lastUpdated: DateTime.now(),
      );
      
      // Mettre à jour le solde du portefeuille destination
      final updatedDestinationWallet = destinationWallet.copyWith(
        balance: destinationWallet.balance + event.amount,
        lastUpdated: DateTime.now(),
      );
      
      // Enregistrer les portefeuilles mis à jour
      await _walletRepository.updateWallet(updatedSourceWallet);
      await _walletRepository.updateWallet(updatedDestinationWallet);
      
      emit(FundsTransferred(transaction));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
