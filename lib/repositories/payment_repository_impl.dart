import 'dart:convert';

import 'package:flutter_activity_app/models/payment_method.dart';
import 'package:flutter_activity_app/repositories/payment_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final SharedPreferences _sharedPreferences;
  final ApiService _apiService;
  
  // Key for SharedPreferences
  static const String _paymentMethodsKey = 'payment_methods';

  PaymentRepositoryImpl(this._sharedPreferences, this._apiService);

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      // In a real app, we would fetch from API
      // final response = await _apiService.get('/payment/methods');
      
      // For demo purposes, we'll use SharedPreferences
      final methodsJson = _sharedPreferences.getString(_paymentMethodsKey);
      
      if (methodsJson != null) {
        final List<dynamic> methodsList = jsonDecode(methodsJson);
        return methodsList.map((json) => PaymentMethod.fromJson(json)).toList();
      }
      
      // Return an empty list if none are found
      return [];
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  @override
  Future<bool> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      // In a real app, we would add via API
      // final response = await _apiService.post('/payment/methods', body: paymentMethod.toJson());
      
      // For demo purposes, we'll use SharedPreferences
      final methods = await getPaymentMethods();
      
      // If this is the first payment method or it's set as default, make sure others are not default
      if (methods.isEmpty || paymentMethod.isDefault) {
        for (var i = 0; i < methods.length; i++) {
          if (methods[i].isDefault) {
            methods[i] = methods[i].copyWith(isDefault: false);
          }
        }
      }
      
      methods.add(paymentMethod);
      
      await _sharedPreferences.setString(_paymentMethodsKey, jsonEncode(methods.map((m) => m.toJson()).toList()));
      
      // Add a delay to simulate network request
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  @override
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      // In a real app, we would delete via API
      // final response = await _apiService.delete('/payment/methods/$paymentMethodId');
      
      // For demo purposes, we'll use SharedPreferences
      final methods = await getPaymentMethods();
      final wasDefault = methods.any((m) => m.id == paymentMethodId && m.isDefault);
      
      methods.removeWhere((method) => method.id == paymentMethodId);
      
      // If we removed the default method and there are other methods, make the first one default
      if (wasDefault && methods.isNotEmpty) {
        methods[0] = methods[0].copyWith(isDefault: true);
      }
      
      await _sharedPreferences.setString(_paymentMethodsKey, jsonEncode(methods.map((m) => m.toJson()).toList()));
      
      // Add a delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 800));
      
      return true;
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  @override
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      // In a real app, we would update via API
      // final response = await _apiService.put('/payment/methods/$paymentMethodId/default');
      
      // For demo purposes, we'll use SharedPreferences
      final methods = await getPaymentMethods();
      
      for (var i = 0; i < methods.length; i++) {
        if (methods[i].id == paymentMethodId) {
          methods[i] = methods[i].copyWith(isDefault: true);
        } else if (methods[i].isDefault) {
          methods[i] = methods[i].copyWith(isDefault: false);
        }
      }
      
      await _sharedPreferences.setString(_paymentMethodsKey, jsonEncode(methods.map((m) => m.toJson()).toList()));
      
      // Add a delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 500));
      
      return true;
    } catch (e) {
      throw Exception('Failed to set default payment method: $e');
    }
  }

  @override
  Future<PaymentMethod?> getPaymentMethodById(String paymentMethodId) async {
    try {
      final methods = await getPaymentMethods();
      return methods.firstWhere((method) => method.id == paymentMethodId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> processTransaction({
    required PaymentMethod paymentMethod,
    required double amount,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    // Simulate a transaction processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate a successful transaction processing
    return {
      'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'status': 'completed',
    };
  }

  @override
  Future<Map<String, dynamic>> processPayment({
    required PaymentMethod paymentMethod,
    required double amount,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    // Simulate a payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate a successful payment processing
    return {
      'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'status': 'completed',
    };
  }
}
