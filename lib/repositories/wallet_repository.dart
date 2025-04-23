import 'dart:convert';
import 'package:flutter_activity_app/models/transaction.dart';
import 'package:flutter_activity_app/models/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class WalletRepository {
  Future<Wallet> getWalletByUserId(String userId);
  Future<Wallet> createWallet(String userId);
  Future<Wallet> updateWallet(Wallet wallet);
  Future<List<Transaction>> getTransactionsByUserId(String userId, {int limit = 10});
  Future<Transaction> addTransaction(Transaction transaction) {
    // TODO: implement addTransaction
    throw UnimplementedError();
  }
}

class WalletRepositoryImpl implements WalletRepository {
  final SharedPreferences _sharedPreferences;
  
  // Keys for SharedPreferences
  static const String _walletsKey = 'wallets';
  static const String _transactionsKey = 'transactions';
  
  WalletRepositoryImpl(this._sharedPreferences);
  
  @override
  Future<Wallet> getWalletByUserId(String userId) async {
    try {
      // In a real app, we would fetch from API
      // final response = await _apiService.get('/wallets/$userId');
      
      // For demo purposes, we'll use SharedPreferences
      final walletsJson = _sharedPreferences.getString(_walletsKey);
      
      if (walletsJson != null) {
        final List<dynamic> decodedList = jsonDecode(walletsJson);
        final wallets = decodedList.map((item) => Wallet.fromJson(item)).toList();
        
        final wallet = wallets.firstWhere(
          (wallet) => wallet.userId == userId,
          orElse: () => throw Exception('Wallet not found'),
        );
        
        return wallet;
      }
      
      throw Exception('Wallet not found');
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }
  
  @override
  Future<Wallet> createWallet(String userId) async {
    try {
      // In a real app, we would create via API
      // final response = await _apiService.post('/wallets', body: {'userId': userId});
      
      // For demo purposes, we'll use SharedPreferences
      final walletsJson = _sharedPreferences.getString(_walletsKey);
      List<Wallet> wallets = [];
      
      if (walletsJson != null) {
        final List<dynamic> decodedList = jsonDecode(walletsJson);
        wallets = decodedList.map((item) => Wallet.fromJson(item)).toList();
        
        // Check if wallet already exists
        final existingWallet = wallets.where((wallet) => wallet.userId == userId).toList();
        if (existingWallet.isNotEmpty) {
          return existingWallet.first;
        }
      }
      
      // Create a new wallet
      final now = DateTime.now();
      final wallet = Wallet(
        id: const Uuid().v4(),
        userId: userId,
        balance: 0,
        
         lastUpdated: now,
      );
      
      wallets.add(wallet);
      
      await _sharedPreferences.setString(_walletsKey, jsonEncode(wallets.map((w) => w.toJson()).toList()));
      
      return wallet;
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }
  
  @override
  Future<Wallet> updateWallet(Wallet wallet) async {
    try {
      // In a real app, we would update via API
      // final response = await _apiService.put('/wallets/${wallet.id}', body: wallet.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      final walletsJson = _sharedPreferences.getString(_walletsKey);
      List<Wallet> wallets = [];
      
      if (walletsJson != null) {
        final List<dynamic> decodedList = jsonDecode(walletsJson);
        wallets = decodedList.map((item) => Wallet.fromJson(item)).toList();
      }
      
      // Find and update the wallet
      final index = wallets.indexWhere((w) => w.id == wallet.id);
      if (index != -1) {
        wallets[index] = wallet.copyWith(lastUpdated: DateTime.now());
      } else {
        wallets.add(wallet.copyWith(lastUpdated: DateTime.now()));
      }
      
      await _sharedPreferences.setString(_walletsKey, jsonEncode(wallets.map((w) => w.toJson()).toList()));
      
      return wallet;
    } catch (e) {
      throw Exception('Failed to update wallet: $e');
    }
  }
  
  @override
  Future<List<Transaction>> getTransactionsByUserId(String userId, {int limit = 10}) async {
    try {
      // In a real app, we would fetch from API
      // final response = await _apiService.get('/transactions?userId=$userId&limit=$limit');
      
      // For demo purposes, we'll use SharedPreferences
      final transactionsJson = _sharedPreferences.getString(_transactionsKey);
      
      if (transactionsJson != null) {
        final List<dynamic> decodedList = jsonDecode(transactionsJson);
        final allTransactions = decodedList.map((item) => Transaction.fromJson(item)).toList();
        
        // Filter transactions by userId and sort by timestamp (newest first)
        final userTransactions = allTransactions
            .where((transaction) => transaction.userId == userId)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Apply limit
        if (limit > 0 && userTransactions.length > limit) {
          return userTransactions.sublist(0, limit);
        }
        
        return userTransactions;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }
  
  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      // In a real app, we would create via API
      // final response = await _apiService.post('/transactions', body: transaction.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      final transactionsJson = _sharedPreferences.getString(_transactionsKey);
      List<Transaction> transactions = [];
      
      if (transactionsJson != null) {
        final List<dynamic> decodedList = jsonDecode(transactionsJson);
        transactions = decodedList.map((item) => Transaction.fromJson(item)).toList();
      }
      
      transactions.add(transaction);
      
      await _sharedPreferences.setString(_transactionsKey, jsonEncode(transactions.map((t) => t.toJson()).toList()));
      
      return transaction;
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }
}
