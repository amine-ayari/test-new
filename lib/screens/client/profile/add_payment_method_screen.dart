import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/payment/payment_bloc.dart';
import 'package:flutter_activity_app/bloc/payment/payment_event.dart';
import 'package:flutter_activity_app/bloc/payment/payment_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/payment_method.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({Key? key}) : super(key: key);

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  
  String _selectedCardType = 'Visa';
  bool _setAsDefault = true;
  bool _showBackOfCard = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final List<String> _cardTypes = ['Visa', 'Mastercard', 'American Express', 'Discover'];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    
    // Listen to CVV focus to flip the card
    _cvvController.addListener(_handleCvvFocus);
  }
  
  void _handleCvvFocus() {
    final hasFocus = FocusScope.of(context).hasFocus;
    if (_cvvController.text.isNotEmpty && !_showBackOfCard) {
      setState(() {
        _showBackOfCard = true;
      });
      _animationController.forward();
    } else if (_cvvController.text.isEmpty && _showBackOfCard) {
      setState(() {
        _showBackOfCard = false;
      });
      _animationController.reverse();
    }
  }
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Payment Method'),
          elevation: 0,
        ),
        body: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentMethodAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is PaymentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreditCardPreview(),
                    const SizedBox(height: 32),
                    _buildCardFields(),
                    const SizedBox(height: 24),
                    _buildCardTypeSelector(),
                    const SizedBox(height: 24),
                    _buildDefaultCheckbox(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(context, state),
                    const SizedBox(height: 16),
                    _buildSecurityInfo(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCreditCardPreview() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(_showBackOfCard ? math.pi : 0);
        
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: _showBackOfCard ? _buildCardBack() : _buildCardFront(),
        );
      },
    );
  }
  
  Widget _buildCardFront() {
    final cardNumber = _cardNumberController.text.isEmpty 
        ? 'XXXX XXXX XXXX XXXX' 
        : _cardNumberController.text.padRight(19, 'X').substring(0, 19);
    
    final cardholderName = _cardholderNameController.text.isEmpty 
        ? 'YOUR NAME' 
        : _cardholderNameController.text.toUpperCase();
    
    final expiryDate = _expiryDateController.text.isEmpty 
        ? 'MM/YY' 
        : _expiryDateController.text;
    
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCardGradient(_selectedCardType),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chip icon
              Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade200,
                      Colors.amber.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Card type logo
              _getCardLogo(_selectedCardType),
            ],
          ),
          // Card number
          Text(
            cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'monospace',
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          // Cardholder info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardholderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiryDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardBack() {
    final cvv = _cvvController.text.isEmpty ? 'XXX' : _cvvController.text;
    
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCardGradient(_selectedCardType),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Black magnetic strip
          Container(
            height: 40,
            color: Colors.black,
          ),
          const SizedBox(height: 20),
          // Signature strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      cvv,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Container(),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Card logo at bottom
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: _getCardLogo(_selectedCardType),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'XXXX XXXX XXXX XXXX',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your card number';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Please enter a valid card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardholderNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'JOHN DOE',
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the cardholder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'MM/YY',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 5) {
                    return 'Invalid format';
                  }
                  
                  // Check if the date is valid
                  final parts = value.split('/');
                  if (parts.length != 2) {
                    return 'Invalid format';
                  }
                  
                  final month = int.tryParse(parts[0]);
                  final year = int.tryParse('20${parts[1]}');
                  
                  if (month == null || year == null || month < 1 || month > 12) {
                    return 'Invalid date';
                  }
                  
                  final now = DateTime.now();
                  final expiryDate = DateTime(year, month + 1, 0);
                  
                  if (expiryDate.isBefore(now)) {
                    return 'Card expired';
                  }
                  
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: const Icon(Icons.security),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'XXX',
                  helperText: 'Flip to see CVV',
                  helperStyle: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onTap: () {
                  setState(() {
                    _showBackOfCard = true;
                  });
                  _animationController.forward();
                },
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 3) {
                    return 'Invalid CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCardTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _cardTypes.length,
            itemBuilder: (context, index) {
              final type = _cardTypes[index];
              final isSelected = type == _selectedCardType;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCardType = type;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                  ),
                  child: Center(
                    child: _getCardLogo(type, size: 40),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildDefaultCheckbox() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CheckboxListTile(
        value: _setAsDefault,
        onChanged: (value) {
          setState(() {
            _setAsDefault = value ?? false;
          });
        },
        title: const Text('Set as default payment method'),
        activeColor: AppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
  
  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Your payment information is securely stored and encrypted. We never store your full card details.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubmitButton(BuildContext context, PaymentState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: state is PaymentLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  final paymentMethod = PaymentMethod(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: _getPaymentMethodType(_selectedCardType),
                    lastFourDigits: _cardNumberController.text.replaceAll(' ', '').substring(12),
                    expiryDate: _expiryDateController.text,
                    cardholderName: _cardholderNameController.text,
                    isDefault: _setAsDefault,
                  );
                  
                  context.read<PaymentBloc>().add(AddPaymentMethod(paymentMethod));
                }
              },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: state is PaymentLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Add Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
  
  List<Color> _getCardGradient(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return [
          const Color(0xFF1A1F71),
          const Color(0xFF2B3595),
        ];
      case 'mastercard':
        return [
          const Color(0xFF3F51B5),
          const Color(0xFF5E35B1),
        ];
      case 'american express':
        return [
          const Color(0xFF006FCF),
          const Color(0xFF00BCD4),
        ];
      case 'discover':
        return [
          const Color(0xFFFF6F00),
          const Color(0xFFFF9800),
        ];
      default:
        return [
          Colors.grey.shade700,
          Colors.grey.shade900,
        ];
    }
  }
  
  Widget _getCardLogo(String type, {double size = 50}) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Image.asset(
          'assets/images/visa_logo.png',
          height: size,
        );
      case 'mastercard':
        return Image.asset(
          'assets/images/mastercard_logo.png',
          height: size,
        );
      case 'american express':
        return Image.asset(
          'assets/images/amex_logo.png',
          height: size,
        );
      case 'discover':
        return Image.asset(
          'assets/images/discover_logo.png',
          height: size,
        );
      default:
        return Icon(
          Icons.credit_card,
          size: size,
          color: Colors.white,
        );
    }
  }

  PaymentMethodType _getPaymentMethodType(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return PaymentMethodType.creditCard;
      case 'mastercard':
        return PaymentMethodType.creditCard;
      case 'american express':
        return PaymentMethodType.creditCard;
      case 'discover':
        return PaymentMethodType.creditCard;
      // Add more cases if needed
      default:
        throw ArgumentError('Invalid card type');
    }
  }
}

// Custom formatter for card number
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Custom formatter for expiry date
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i != text.length - 1) {
        buffer.write('/');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
