  import 'package:flutter_activity_app/models/activity.dart';
  import 'package:flutter_activity_app/repositories/activity_repository_impl.dart';

  abstract class ActivityRepository {
    ActivityRepository(ActivityRepositoryImpl activityRepositoryImpl);

    Future<List<Activity>> getActivities();
    Future<Activity> getActivityById(String id);
    Future<void> toggleFavorite(String id);
    Future<List<Activity>> getFavoriteActivities();
    Future<List<String>> getCategories();
    Future<void> rejectActivity(String id);
    Future<void> likeActivity(String id);
  }
