import 'package:flutter/material.dart';

class ActivitiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activities'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with actual number of activities
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text('Activity $index'), // Replace with actual activity name
              subtitle: Text('Description of Activity $index'), // Replace with actual activity description
              onTap: () {
                // Navigate to activity detail screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActivityDetailScreen(activityId: index),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

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