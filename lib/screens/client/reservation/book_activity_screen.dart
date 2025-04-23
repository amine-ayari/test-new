import 'package:flutter/material.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_state.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/bloc/payment/payment_bloc.dart';
import 'package:flutter_activity_app/bloc/payment/payment_event.dart';
import 'package:flutter_activity_app/bloc/payment/payment_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/payment_method.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/screens/client/profile/payment_methods_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookActivityScreen extends StatefulWidget {
  final String activityId;

  const BookActivityScreen({
    Key? key,
    required this.activityId,
  }) : super(key: key);

  @override
  State<BookActivityScreen> createState() => _BookActivityScreenState();
}

class _BookActivityScreenState extends State<BookActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _selectedDate;
  String? _selectedTime;
  int _participants = 1;
  String? _selectedPaymentMethodId;
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ActivityBloc>()..add(LoadActivityDetails(widget.activityId)),
        ),
        BlocProvider(
          create: (_) => getIt<PaymentBloc>()..add(const LoadPaymentMethods()),
        ),
        BlocProvider(
          create: (_) => getIt<ReservationBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Activity'),
          elevation: 0,
        ),
        body: BlocConsumer<ReservationBloc, ReservationState>(
          listener: (context, state) {
            if (state is ReservationCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservation created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
              Navigator.pop(context); // Pop twice to go back to the activity list
            } else if (state is ReservationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, reservationState) {
            return BlocBuilder<ActivityBloc, ActivityState>(
              builder: (context, activityState) {
                if (activityState is ActivityLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (activityState is ActivityDetailsLoaded) {
                  return _buildBookingForm(
                    context,
                    activityState.activity,
                    reservationState,
                  );
                }
                
                return const Center(child: Text('Failed to load activity details'));
              },
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildBookingForm(
    BuildContext context,
    Activity activity,
    ReservationState reservationState,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildActivityCard(activity),
          const SizedBox(height: 24),
          _buildDateSelection(activity),
          const SizedBox(height: 24),
          _buildTimeSelection(activity),
          const SizedBox(height: 24),
          _buildParticipantsSelection(activity),
          const SizedBox(height: 24),
          _buildPaymentMethodSelection(),
          const SizedBox(height: 24),
          _buildPriceSummary(activity),
          const SizedBox(height: 32),
          _buildBookButton(context, activity, reservationState),
        ],
      ),
    );
  }
  
  Widget _buildActivityCard(Activity activity) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              activity.image,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.location,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      activity.duration,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateSelection(Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context, activity),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                        : 'Select a date',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_selectedDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Please select a date',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
  
  Future<void> _selectDate(BuildContext context, Activity activity) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = now.add(const Duration(days: 90));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime date) {
        // Check if the date is available in the activity's available dates
        return activity.availableDates.any(
          (availableDate) => 
            availableDate.date.year == date.year &&
            availableDate.date.month == date.month &&
            availableDate.date.day == date.day &&
            availableDate.available,
        );
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
    }
  }
  
  Widget _buildTimeSelection(Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedDate == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: const Text(
              'Please select a date first',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activity.availableTimes
                .where((time) => time.available)
                .map((time) => _buildTimeChip(time.time))
                .toList(),
          ),
        if (_selectedDate != null && _selectedTime == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Please select a time',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTimeChip(String time) {
    final isSelected = _selectedTime == time;
    
    return ChoiceChip(
      label: Text(time),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTime = selected ? time : null;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
  
  Widget _buildParticipantsSelection(Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Participants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Participants'),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _participants > 1
                    ? () {
                        setState(() {
                          _participants--;
                        });
                      }
                    : null,
                color: _participants > 1 ? AppTheme.primaryColor : Colors.grey,
              ),
              Text(
                _participants.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _participants < 10
                    ? () {
                        setState(() {
                          _participants++;
                        });
                      }
                    : null,
                color: _participants < 10 ? AppTheme.primaryColor : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (state is PaymentMethodsLoaded) {
              if (state.paymentMethods.isEmpty) {
                return _buildAddPaymentMethodButton();
              }
              
              return Column(
                children: [
                  ...state.paymentMethods.map((method) => _buildPaymentMethodItem(method)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Payment Method'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsScreen(),
                        ),
                      ).then((_) {
                        context.read<PaymentBloc>().add(const LoadPaymentMethods());
                      });
                    },
                  ),
                ],
              );
            }
            
            return _buildAddPaymentMethodButton();
          },
        ),
        if (_selectedPaymentMethodId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'Please select a payment method',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildAddPaymentMethodButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Add Payment Method'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaymentMethodsScreen(),
          ),
        ).then((_) {
          context.read<PaymentBloc>().add(const LoadPaymentMethods());
        });
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethodItem(PaymentMethod method) {
    final isSelected = _selectedPaymentMethodId == method.id;
    
    // If no payment method is selected yet and this one is default, select it
    if (_selectedPaymentMethodId == null && method.isDefault) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedPaymentMethodId = method.id;
        });
      });
    }
    
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethodId = method.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Radio<String>(
                value: method.id,
                groupValue: _selectedPaymentMethodId,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethodId = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.credit_card,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentMethodTypeToString(method.type),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.primaryColor : null,
                      ),
                    ),
                    Text(
                      '•••• ${method.lastFourDigits}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _paymentMethodTypeToString(PaymentMethodType type) {
    return type.toString().split('.').last;
  }
  
  Widget _buildPriceSummary(Activity activity) {
    final basePrice = activity.price * _participants;
    final tax = basePrice * 0.1; // 10% tax
    final total = basePrice + tax;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activity Price (x$_participants)'),
                Text('\$${basePrice.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax (10%)'),
                Text('\$${tax.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookButton(
    BuildContext context,
    Activity activity,
    ReservationState state,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is ReservationLoading
            ? null
            : () => _submitBooking(context, activity),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state is ReservationLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Confirm Booking',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
  
  Future<void> _submitBooking(BuildContext context, Activity activity) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final basePrice = activity.price * _participants;
    final tax = basePrice * 0.1; // 10% tax
    final total = basePrice + tax;
    final prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('user_profile') ?? ''; // Récupère l'ID de l'utilisateur

  final reservation = Reservation(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  activityId: activity.id!,
  userId: userId,  // Add the userId, as it's required in your class
  date: _selectedDate!,
  timeSlot: _selectedTime!,  // Ensure this matches the field name
  numberOfPeople: _participants,  // Ensure this is correct
  totalPrice: total,
  status: ReservationStatus.confirmed,  // Correct type, not a string
  createdAt: DateTime.now(),
  notes: "null",  // If no notes, pass null or a string
  cancellationReason: "null",  // If no cancellation reason, pass null or a string
  activity: activity, activityName: activity.name, paymentStatus: '',  // Pass the activity object, if available
);

    context.read<ReservationBloc>().add(CreateReservation(reservation));
  }
}
