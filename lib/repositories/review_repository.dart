import 'package:flutter_activity_app/models/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviewsForActivity(String activityId);
  Future<Review> addReview(Review review);
  Future<Review> updateReview(Review review);
  Future<void> deleteReview(String reviewId);
  Future<void> markReviewAsHelpful(String reviewId, String userId);
  Future<void> unmarkReviewAsHelpful(String reviewId, String userId);
}