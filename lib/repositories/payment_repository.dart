// TODO Implement this library.
import 'package:flutter_activity_app/models/payment_method.dart';

abstract class PaymentRepository {
  /// Get all payment methods for the current user
  Future<List<PaymentMethod>> getPaymentMethods();
  
  /// Add a new payment method
  Future<bool> addPaymentMethod(PaymentMethod paymentMethod);
  
  /// Delete a payment method
  Future<bool> deletePaymentMethod(String paymentMethodId);
  
  /// Set a payment method as default
  Future<bool> setDefaultPaymentMethod(String paymentMethodId);
  
  /// Get a payment method by ID
  Future<PaymentMethod?> getPaymentMethodById(String paymentMethodId);

  Future<Map<String, dynamic>> processPayment({
    required PaymentMethod paymentMethod,
    required double amount,
    required String description,
    required Map<String, dynamic> metadata,
  });

  Future<Map<String, dynamic>> processTransaction({
    required PaymentMethod paymentMethod,
    required double amount,
    required String description,
    required Map<String, dynamic> metadata,
  });
}
