import 'package:flutter_activity_app/models/activity.dart';
import 'package:flutter_activity_app/models/user.dart';

abstract class ProviderRepository {
  Future<List<Activity>> getProviderActivities(String providerId);
  Future<Activity> createActivity(Activity activity);
  Future<Activity> updateActivity(Activity activity);
  Future<void> deleteActivity(String activityId);
  Future<Activity> updateAvailability(String activityId, List<AvailableDate> dates, List<AvailableTime> times);

  Future<User> updateProviderVerificationInfo({
    required String providerId,
    String? businessName,
    String? taxId,
    String? nationalId,
  });
  
  Future<User> getProviderVerificationStatus(String providerId);
}
