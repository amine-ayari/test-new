import 'package:flutter_activity_app/models/review.dart';
import 'package:flutter_activity_app/repositories/review_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ApiService _apiService;

  ReviewRepositoryImpl(this._apiService);

  @override
  Future<List<Review>> getReviewsForActivity(String activityId) async {
    try {
      final response = await _apiService.get('/activities/$activityId/reviews');
      return (response as List).map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      // For demo purposes, return mock data if API fails
      return _getMockReviews(activityId);
    }
  }

  @override
  Future<Review> addReview(Review review) async {
    try {
      final response = await _apiService.postWithAuth(
        '/activities/${review.activityId}/reviews',
        review.toJson(),
      );
      return Review.fromJson(response);
    } catch (e) {
      // For demo purposes, return the review with a generated ID
      return review.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
      );
    }
  }

  @override
  Future<Review> updateReview(Review review) async {
    try {
      final response = await _apiService.put(
        '/reviews/${review.id}',
        review.toJson(),
      );
      return Review.fromJson(response);
    } catch (e) {
      // For demo purposes, return the updated review
      return review;
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      await _apiService.delete('/reviews/$reviewId');
    } catch (e) {
      // Handle error silently for demo
      print('Error deleting review: $e');
    }
  }

  @override
  Future<void> markReviewAsHelpful(String reviewId, String userId) async {
    try {
      await _apiService.postWithAuth(
        '/reviews/$reviewId/helpful',
        {'userId': userId},
      );
    } catch (e) {
      // Handle error silently for demo
      print('Error marking review as helpful: $e');
    }
  }

  @override
  Future<void> unmarkReviewAsHelpful(String reviewId, String userId) async {
    try {
      await _apiService.postWithAuth(
        '/reviews/$reviewId/unhelpful',
        {'userId': userId},
      );
    } catch (e) {
      // Handle error silently for demo
      print('Error unmarking review as helpful: $e');
    }
  }

  // Mock data for demo purposes
  List<Review> _getMockReviews(String activityId) {
    return [
      Review(
        id: '1',
        userId: '1',
        activityId: activityId,
        userName: 'Sophie Martin',
        userAvatar: 'https://randomuser.me/api/portraits/women/44.jpg',
        rating: 4.5,
        comment: 'Une expérience incroyable, je recommande vivement !',
        date: DateTime.now().subtract(const Duration(days: 2)),
        helpfulCount: 3,
        usersThatFoundHelpful: ['2', '3', '4'],
      ),
      Review(
        id: '2',
        userId: '2',
        activityId: activityId,
        userName: 'Thomas Dubois',
        userAvatar: 'https://randomuser.me/api/portraits/men/32.jpg',
        rating: 5.0,
        comment: 'Parfait du début à la fin. Le guide était très professionnel.',
        date: DateTime.now().subtract(const Duration(days: 1)),
        helpfulCount: 2,
        usersThatFoundHelpful: ['1', '3'],
      ),
      Review(
        id: '3',
        userId: '5',
        activityId: activityId,
        userName: 'Julie Moreau',
        userAvatar: 'https://randomuser.me/api/portraits/women/22.jpg',
        rating: 3.5,
        comment: 'Bonne activité mais un peu chère pour ce que c\'est.',
        date: DateTime.now().subtract(const Duration(hours: 10)),
        helpfulCount: 1,
        usersThatFoundHelpful: ['4'],
      ),
    ];
  }
}