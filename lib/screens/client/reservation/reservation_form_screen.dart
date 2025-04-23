import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_bloc.dart';
import 'package:flutter_activity_app/bloc/activity/activity_event.dart';
import 'package:flutter_activity_app/bloc/activity/activity_state.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_bloc.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_event.dart';
import 'package:flutter_activity_app/bloc/reservation/reservation_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/reservation.dart';
import 'package:flutter_activity_app/widgets/network_error_widget.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ReservationFormScreen extends StatefulWidget {
  final String activityId;
  final String userId;

  const ReservationFormScreen({
    Key? key,
    required this.activityId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  late ActivityBloc _activityBloc;
  late ReservationBloc _reservationBloc;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  int _numberOfPeople = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activityBloc = getIt<ActivityBloc>();
    _reservationBloc = getIt<ReservationBloc>();

    // Load activity details
    _activityBloc.add(LoadActivityDetails(widget.activityId));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _activityBloc),
        BlocProvider.value(value: _reservationBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Activity'),
          elevation: 0,
        ),
        body: BlocListener<ReservationBloc, ReservationState>(
          listener: (context, state) {
            if (state is ReservationCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Reservation created successfully!')),
              );
              Navigator.pop(context);
            } else if (state is ReservationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          child: BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              if (state is ActivityLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ActivityDetailsLoaded) {
                return _buildForm(state.activity);
              } else if (state is ActivityError) {
                return NetworkErrorWidget(
                  message: 'Could not load activity details',
                  onRetry: () {
                    _activityBloc.add(LoadActivityDetails(widget.activityId));
                  },
                );
              } else {
                return const Center(child: Text('Something went wrong'));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Activity activity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivityInfo(activity),
          const SizedBox(height: 24),
          _buildDateSelection(activity),
          const SizedBox(height: 24),
          _buildTimeSelection(activity),
          const SizedBox(height: 24),
          _buildPeopleSelection(),
          const SizedBox(height: 24),
          _buildNotesField(),
          const SizedBox(height: 24),
          _buildPriceSummary(activity),
          const SizedBox(height: 32),
          _buildBookButton(activity),
        ],
      ),
    );
  }

  Widget _buildActivityInfo(Activity activity) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            activity.image,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      activity.location,
                      style: const TextStyle(color: Colors.grey),
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
                      style: const TextStyle(color: Colors.grey),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activity.availableDates.length,
            itemBuilder: (context, index) {
              final date = activity.availableDates[index];
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.date.year &&
                  _selectedDate!.month == date.date.month &&
                  _selectedDate!.day == date.date.day;

              return GestureDetector(
                onTap: date.available
                    ? () {
                        setState(() {
                          _selectedDate = date.date;
                          _selectedTimeSlot =
                              null; // Reset time slot when date changes
                        });
                      }
                    : null,
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : (date.available
                            ? Colors.white
                            : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date.date),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (date.available ? Colors.black87 : Colors.grey),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d').format(date.date),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (date.available ? Colors.black87 : Colors.grey),
                        ),
                      ),
                      if (!date.available)
                        const Text(
                          'Unavailable',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection(Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _selectedDate == null
            ? const Text(
                'Please select a date first',
                style: TextStyle(color: Colors.grey),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activity.availableTimes.map((time) {
                  final isSelected = _selectedTimeSlot == time.time;

                  return GestureDetector(
                    onTap: time.available
                        ? () {
                            setState(() {
                              _selectedTimeSlot = time.time;
                            });
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : (time.available
                                ? Colors.white
                                : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        time.time,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (time.available ? Colors.black87 : Colors.grey),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildPeopleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of People',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _numberOfPeople > 1
                  ? () {
                      setState(() {
                        _numberOfPeople--;
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove),
              color: _numberOfPeople > 1 ? Colors.black87 : Colors.grey,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _numberOfPeople.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _numberOfPeople < 10
                  ? () {
                      setState(() {
                        _numberOfPeople++;
                      });
                    }
                  : null,
              icon: const Icon(Icons.add),
              color: _numberOfPeople < 10 ? Colors.black87 : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Requests (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special requests or notes for the provider...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(Activity activity) {
    final totalPrice = activity.price * _numberOfPeople;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${activity.name} x $_numberOfPeople'),
                  Text(
                      '\$${(activity.price * _numberOfPeople).toStringAsFixed(2)}'),
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
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton(Activity activity) {
    final isFormValid = _selectedDate != null && _selectedTimeSlot != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid ? () => _createReservation(activity) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: BlocBuilder<ReservationBloc, ReservationState>(
          builder: (context, state) {
            if (state is ReservationLoading) {
              return const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              );
            }
            return const Text(
              'Book Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }

  void _createReservation(Activity activity) {
    if (_selectedDate == null || _selectedTimeSlot == null) return;

    final totalPrice = activity.price * _numberOfPeople;

    final reservation = Reservation(
      id: const Uuid().v4(), // This will be replaced by the backend
      activityId: activity.id!,
      userId: widget.userId,
      date: _selectedDate!,
      timeSlot: _selectedTimeSlot!,
      numberOfPeople: _numberOfPeople,
      totalPrice: totalPrice,
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : '',
      activityName: activity.name, cancellationReason: '', paymentStatus: '',
    );

    _reservationBloc.add(CreateReservation(reservation));
  }
}
