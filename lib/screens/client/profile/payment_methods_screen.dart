import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/payment/payment_bloc.dart';
import 'package:flutter_activity_app/bloc/payment/payment_event.dart';
import 'package:flutter_activity_app/bloc/payment/payment_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/payment_method.dart';
import 'package:flutter_activity_app/screens/client/profile/add_payment_method_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentBloc>()..add(const LoadPaymentMethods()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment Methods'),
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddPaymentMethodScreen(),
              ),
            ).then((_) {
              // Refresh payment methods when returning from add screen
              context.read<PaymentBloc>().add(const LoadPaymentMethods());
            });
          },
          child: const Icon(Icons.add),
          tooltip: 'Add Payment Method',
        ),
        body: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentMethodDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Payment method removed'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(10),
                ),
              );
            } else if (state is PaymentMethodSetAsDefault) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Default payment method updated'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(10),
                ),
              );
            } else if (state is PaymentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(10),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PaymentLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (state is PaymentMethodsLoaded) {
              if (state.paymentMethods.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return _buildPaymentMethodsList(context, state.paymentMethods);
            }
            
            return const Center(
              child: Text('Failed to load payment methods'),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Payment Methods',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add a payment method to make bookings easier and faster',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPaymentMethodScreen(),
                ),
              ).then((_) {
                // Refresh payment methods when returning from add screen
                context.read<PaymentBloc>();
                // Refresh payment methods when returning from add screen
                context.read<PaymentBloc>().add(const LoadPaymentMethods());
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodsList(BuildContext context, List<PaymentMethod> paymentMethods) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        ...paymentMethods.map((method) => _buildPaymentMethodCard(context, method)),
      ],
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Your payment information is securely stored. You can add multiple payment methods and set a default one for faster checkout.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodCard(BuildContext context, PaymentMethod method) {
    final Color cardColor = _getCardColor(_paymentMethodTypeToString(method.type));
    final IconData cardIcon = _getCardIcon(_paymentMethodTypeToString(method.type));
    
    return Slidable(
      key: ValueKey(method.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(
          onDismissed: () {
            context.read<PaymentBloc>().add(DeletePaymentMethod(method.id));
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              context.read<PaymentBloc>().add(DeletePaymentMethod(method.id));
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: method.isDefault
              ? BorderSide(color: AppTheme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: method.isDefault
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        cardIcon,
                        color: cardColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _paymentMethodTypeToString(method.type),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (method.isDefault)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!method.isDefault)
                      TextButton.icon(
                        onPressed: () {
                          context.read<PaymentBloc>().add(SetDefaultPaymentMethod(method.id));
                        },
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        label: Text(
                          'Set Default',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.credit_card,
                      title: 'Card Number',
                      value: '•••• •••• •••• ${method.lastFourDigits}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.calendar_today,
                            title: 'Expiry Date',
                            value: method.expiryDate ?? 'N/A',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.person,
                            title: 'Cardholder',
                            value: method.cardholderName ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getCardColor(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.deepOrange;
      case 'american express':
        return Colors.indigo;
      case 'discover':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getCardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
      case 'mastercard':
      case 'american express':
      case 'discover':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet;
      default:
        return Icons.credit_card;
    }
  }
  
  String _paymentMethodTypeToString(PaymentMethodType type) {
    return type.toString().split('.').last;
  }
}
