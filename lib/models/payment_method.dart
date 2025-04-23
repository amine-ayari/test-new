import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PaymentMethodType {
  creditCard,
  paypal,
  applePay,
  googlePay,
  bankTransfer,
  orangeMoney,
  mobileMoney,
  wavePayment
}

class PaymentMethod extends Equatable {
  final String id;
  final PaymentMethodType type;
  final String? lastFourDigits;
  final String? expiryDate;
  final String? cardholderName;
  final String? email;
  final String? phoneNumber;
  final String? bankName;
  final String? accountNumber;
  final bool isDefault;
  final String? brand; // Visa, Mastercard, etc.
  final String? countryCode;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.lastFourDigits,
    this.expiryDate,
    this.cardholderName,
    this.email,
    this.phoneNumber,
    this.bankName,
    this.accountNumber,
    this.isDefault = false,
    this.brand,
    this.countryCode,
  });

  @override
  List<Object?> get props => [
    id, type, lastFourDigits, expiryDate, cardholderName, 
    email, phoneNumber, bankName, accountNumber, isDefault,
    brand, countryCode
  ];

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: PaymentMethodType.values.firstWhere(
        (e) => e.toString() == 'PaymentMethodType.${json['type']}',
        orElse: () => PaymentMethodType.creditCard,
      ),
      lastFourDigits: json['lastFourDigits'],
      expiryDate: json['expiryDate'],
      cardholderName: json['cardholderName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      isDefault: json['isDefault'] ?? false,
      brand: json['brand'],
      countryCode: json['countryCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'lastFourDigits': lastFourDigits,
      'expiryDate': expiryDate,
      'cardholderName': cardholderName,
      'email': email,
      'phoneNumber': phoneNumber,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
      'brand': brand,
      'countryCode': countryCode,
    };
  }

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? lastFourDigits,
    String? expiryDate,
    String? cardholderName,
    String? email,
    String? phoneNumber,
    String? bankName,
    String? accountNumber,
    bool? isDefault,
    String? brand,
    String? countryCode,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryDate: expiryDate ?? this.expiryDate,
      cardholderName: cardholderName ?? this.cardholderName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
      brand: brand ?? this.brand,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  // Helper methods to get payment method details
  String getDisplayTitle() {
    switch (type) {
      case PaymentMethodType.creditCard:
        return brand != null 
            ? '$brand •••• $lastFourDigits' 
            : 'Carte •••• $lastFourDigits';
      case PaymentMethodType.paypal:
        return 'PayPal${email != null ? ' ($email)' : ''}';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
      case PaymentMethodType.bankTransfer:
        return 'Virement bancaire${bankName != null ? ' ($bankName)' : ''}';
      case PaymentMethodType.orangeMoney:
        return 'Orange Money${phoneNumber != null ? ' ($phoneNumber)' : ''}';
      case PaymentMethodType.mobileMoney:
        return 'Mobile Money${phoneNumber != null ? ' ($phoneNumber)' : ''}';
      case PaymentMethodType.wavePayment:
        return 'Wave${phoneNumber != null ? ' ($phoneNumber)' : ''}';
      default:
        return 'Méthode de paiement';
    }
  }

  String getSubtitle() {
    switch (type) {
      case PaymentMethodType.creditCard:
        return expiryDate != null ? 'Expire le $expiryDate' : '';
      case PaymentMethodType.paypal:
        return email ?? '';
      case PaymentMethodType.applePay:
        return 'Paiement sécurisé Apple';
      case PaymentMethodType.googlePay:
        return 'Paiement sécurisé Google';
      case PaymentMethodType.bankTransfer:
        return accountNumber != null ? 'Compte: $accountNumber' : '';
      case PaymentMethodType.orangeMoney:
      case PaymentMethodType.mobileMoney:
      case PaymentMethodType.wavePayment:
        return phoneNumber ?? '';
      default:
        return '';
    }
  }

  IconData getIcon() {
    switch (type) {
      case PaymentMethodType.creditCard:
        if (brand?.toLowerCase() == 'visa') return Icons.credit_card;
        if (brand?.toLowerCase() == 'mastercard') return Icons.credit_card;
        if (brand?.toLowerCase() == 'amex') return Icons.credit_card;
        return Icons.credit_card;
      case PaymentMethodType.paypal:
        return Icons.account_balance_wallet;
      case PaymentMethodType.applePay:
        return Icons.apple;
      case PaymentMethodType.googlePay:
        return Icons.g_mobiledata;
      case PaymentMethodType.bankTransfer:
        return Icons.account_balance;
      case PaymentMethodType.orangeMoney:
        return Icons.phone_android;
      case PaymentMethodType.mobileMoney:
        return Icons.phone_android;
      case PaymentMethodType.wavePayment:
        return Icons.waves;
      default:
        return Icons.payment;
    }
  }

  Color getIconColor() {
    switch (type) {
      case PaymentMethodType.creditCard:
        if (brand?.toLowerCase() == 'visa') return Colors.blue;
        if (brand?.toLowerCase() == 'mastercard') return Colors.deepOrange;
        if (brand?.toLowerCase() == 'amex') return Colors.indigo;
        return Colors.blueGrey;
      case PaymentMethodType.paypal:
        return Colors.blue;
      case PaymentMethodType.applePay:
        return Colors.black;
      case PaymentMethodType.googlePay:
        return Colors.blue;
      case PaymentMethodType.bankTransfer:
        return Colors.green;
      case PaymentMethodType.orangeMoney:
        return Colors.orange;
      case PaymentMethodType.mobileMoney:
        return Colors.purple;
      case PaymentMethodType.wavePayment:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
