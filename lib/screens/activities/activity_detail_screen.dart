import 'package:flutter/material.dart';

class ActivityDetailScreen extends StatelessWidget {
  final int activityId;

  ActivityDetailScreen({required this.activityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity $activityId', // Replace with actual activity data
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Detailed description of Activity $activityId', // Replace with actual activity data
              style: TextStyle(fontSize: 16),
            ),
            // Add more widgets to display additional details
          ],
        ),
      ),
    );
  }
}