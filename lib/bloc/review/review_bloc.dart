import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/review/review_event.dart';
import 'package:flutter_activity_app/bloc/review/review_state.dart';
import 'package:flutter_activity_app/repositories/review_repository.dart';
import 'package:flutter_activity_app/models/review.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepository;

  ReviewBloc(this._reviewRepository) : super(const ReviewInitial()) {
    on<LoadReviews>(_onLoadReviews);
    on<AddReview>(_onAddReview);
    on<UpdateReview>(_onUpdateReview);
    on<DeleteReview>(_onDeleteReview);
    on<MarkReviewAsHelpful>(_onMarkReviewAsHelpful);
    on<UnmarkReviewAsHelpful>(_onUnmarkReviewAsHelpful);
  }

  Future<void> _onLoadReviews(
    LoadReviews event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewLoading());
    try {
      final reviews = await _reviewRepository.getReviewsForActivity(event.activityId);
      
      // Calculate average rating
      double averageRating = 0;
      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
        averageRating = totalRating / reviews.length;
      }
      
      emit(ReviewsLoaded(
        reviews: reviews,
        averageRating: averageRating,
      ));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onAddReview(
    AddReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      final addedReview = await _reviewRepository.addReview(event.review);
      emit(ReviewAdded(addedReview));
      
      // Reload reviews to update the list and average
      add(LoadReviews(event.review.activityId));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onUpdateReview(
    UpdateReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      final updatedReview = await _reviewRepository.updateReview(event.review);
      emit(ReviewUpdated(updatedReview));
      
      // Reload reviews to update the list and average
      add(LoadReviews(event.review.activityId));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onDeleteReview(
    DeleteReview event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewRepository.deleteReview(event.reviewId);
      emit(ReviewDeleted(event.reviewId));
      
      // If we're in the loaded state, we need to reload the reviews
      if (state is ReviewsLoaded) {
        final currentState = state as ReviewsLoaded;
        final activityId = currentState.reviews.firstWhere(
          (review) => review.id == event.reviewId,
          orElse: () => Review(
            id: '',
            userId: '',
            activityId: '',
            userName: '',
            userAvatar: '',
            rating: 0,
            comment: '',
            date: DateTime.now(),
          ),
        ).activityId;
        
        if (activityId.isNotEmpty) {
          add(LoadReviews(activityId));
        }
      }
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onMarkReviewAsHelpful(
    MarkReviewAsHelpful event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewRepository.markReviewAsHelpful(event.reviewId, event.userId);
      
      // Update the review in the state
      if (state is ReviewsLoaded) {
        final currentState = state as ReviewsLoaded;
        final updatedReviews = currentState.reviews.map((review) {
          if (review.id == event.reviewId) {
            final updatedHelpfulUsers = List<String>.from(review.usersThatFoundHelpful)
              ..add(event.userId);
            return review.copyWith(
              helpfulCount: review.helpfulCount + 1,
              usersThatFoundHelpful: updatedHelpfulUsers,
            );
          }
          return review;
        }).toList();
        
        emit(currentState.copyWith(reviews: updatedReviews));
      }
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onUnmarkReviewAsHelpful(
    UnmarkReviewAsHelpful event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewRepository.unmarkReviewAsHelpful(event.reviewId, event.userId);
      
      // Update the review in the state
      if (state is ReviewsLoaded) {
        final currentState = state as ReviewsLoaded;
        final updatedReviews = currentState.reviews.map((review) {
          if (review.id == event.reviewId) {
            final updatedHelpfulUsers = List<String>.from(review.usersThatFoundHelpful)
              ..remove(event.userId);
            return review.copyWith(
              helpfulCount: review.helpfulCount - 1,
              usersThatFoundHelpful: updatedHelpfulUsers,
            );
          }
          return review;
        }).toList();
        
        emit(currentState.copyWith(reviews: updatedReviews));
      }
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }
}