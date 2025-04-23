import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_bloc.dart';
import 'package:flutter_activity_app/bloc/provider/provider_event.dart';
import 'package:flutter_activity_app/bloc/provider/provider_state.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/activity.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  final Activity activity;

  const AvailabilityManagementScreen({
    Key? key,
    required this.activity,
  }) : super(key: key);

  @override
  State<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends State<AvailabilityManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProviderBloc _providerBloc;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Copy of the activity's available dates and times for editing
  late List<AvailableDate> _availableDates;
  late List<AvailableTime> _availableTimes;
  
  // Map to track changes to dates
  final Map<DateTime, bool> _dateAvailabilityChanges = {};
  
  // List to track changes to times
  final List<AvailableTime> _updatedTimes = [];
  
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _providerBloc = getIt<ProviderBloc>();
    
    // Create copies of the activity's available dates and times
    _availableDates = List<AvailableDate>.from(widget.activity.availableDates);
    _availableTimes = List<AvailableTime>.from(widget.activity.availableTimes);
    
    // Initialize the selected day to today
    _selectedDay = DateTime.now();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Check if a date is available
  bool _isDateAvailable(DateTime day) {
    // First check if there's a change for this date
    if (_dateAvailabilityChanges.containsKey(day)) {
      return _dateAvailabilityChanges[day]!;
    }
    
    // Otherwise check the original availability
    final date = _availableDates.firstWhere(
      (d) => isSameDay(d.date, day),
      orElse: () => AvailableDate(date: day, available: false),
    );
    
    return date.available;
  }
  
  // Toggle the availability of a date
  void _toggleDateAvailability(DateTime day) {
    final currentAvailability = _isDateAvailable(day);
    
    setState(() {
      _dateAvailabilityChanges[day] = !currentAvailability;
      _hasChanges = true;
    });
  }
  
  // Check if a time is available
  bool _isTimeAvailable(String time) {
    // First check if there's a change for this time
    final updatedTime = _updatedTimes.firstWhere(
      (t) => t.time == time,
      orElse: () => AvailableTime(time: '', available: false),
    );
    
    if (updatedTime.time.isNotEmpty) {
      return updatedTime.available;
    }
    
    // Otherwise check the original availability
    final timeSlot = _availableTimes.firstWhere(
      (t) => t.time == time,
      orElse: () => AvailableTime(time: time, available: false),
    );
    
    return timeSlot.available;
  }
  
  // Toggle the availability of a time
  void _toggleTimeAvailability(String time) {
    final currentAvailability = _isTimeAvailable(time);
    
    setState(() {
      // Remove any existing entry for this time
      _updatedTimes.removeWhere((t) => t.time == time);
      
      // Add the updated time
      _updatedTimes.add(AvailableTime(time: time, available: !currentAvailability));
      
      _hasChanges = true;
    });
  }
  
  // Save changes
  void _saveChanges() {
    // Update the available dates
    final updatedDates = <AvailableDate>[];
    
    // Add dates from the original list that haven't been changed
    for (final date in _availableDates) {
      if (!_dateAvailabilityChanges.containsKey(date.date)) {
        updatedDates.add(date);
      }
    }
    
    // Add dates that have been changed
    for (final entry in _dateAvailabilityChanges.entries) {
      updatedDates.add(AvailableDate(date: entry.key, available: entry.value));
    }
    
    // Update the available times
    final updatedTimes = <AvailableTime>[];
    
    // Add times from the original list that haven't been changed
    for (final time in _availableTimes) {
      if (!_updatedTimes.any((t) => t.time == time.time)) {
        updatedTimes.add(time);
      }
    }
    
    // Add times that have been changed
    updatedTimes.addAll(_updatedTimes);
    
    // Update the activity's availability
    _providerBloc.add(UpdateAvailability(
      widget.activity.id!,
      updatedDates,
      updatedTimes,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Availability updated'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _providerBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Availability'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dates'),
              Tab(text: 'Times'),
            ],
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
          ),
          actions: [
            if (_hasChanges)
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: _saveChanges,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDatesTab(),
            _buildTimesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesTab() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final isAvailable = _isDateAvailable(day);
              
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isAvailable ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedDay != null) _buildSelectedDayActions(),
      ],
    );
  }

  Widget _buildSelectedDayActions() {
    final isAvailable = _isDateAvailable(_selectedDay!);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAvailable ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: isAvailable,
                        onChanged: (value) => _toggleDateAvailability(_selectedDay!),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimesTab() {
    // Define time slots
    final List<String> morningTimes = ['08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM'];
    final List<String> afternoonTimes = ['12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM'];
    final List<String> eveningTimes = ['04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set your available time slots',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These time slots will be available for all dates marked as available.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          _buildTimeSection('Morning', morningTimes),
          const SizedBox(height: 24),
          _buildTimeSection('Afternoon', afternoonTimes),
          const SizedBox(height: 24),
          _buildTimeSection('Evening', eveningTimes),
        ],
      ),
    );
  }

  Widget _buildTimeSection(String title, List<String> times) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            final isAvailable = _isTimeAvailable(time);
            
            return FilterChip(
              label: Text(time),
              selected: isAvailable,
              onSelected: (_) => _toggleTimeAvailability(time),
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.green.withOpacity(0.2),
              checkmarkColor: Colors.green,
              labelStyle: TextStyle(
                color: isAvailable ? Colors.green[800] : Colors.black,
                fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
