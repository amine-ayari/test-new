  // TODO Implement this library.import 'package:equatable/equatable.dart';
  import 'package:equatable/equatable.dart';
  import 'package:flutter_activity_app/models/review.dart';

  abstract class ReviewEvent extends Equatable {
    const ReviewEvent();

    @override
    List<Object?> get props => [];
  }

  class LoadReviews extends ReviewEvent {
    final String activityId;

    const LoadReviews(this.activityId);

    @override
    List<Object?> get props => [activityId];
  }

  class AddReview extends ReviewEvent {
    final Review review;

    const AddReview(this.review);

    @override
    List<Object?> get props => [review];
  }

  class UpdateReview extends ReviewEvent {
    final Review review;

    const UpdateReview(this.review);

    @override
    List<Object?> get props => [review];
  }

  class DeleteReview extends ReviewEvent {
    final String reviewId;

    const DeleteReview(this.reviewId);

    @override
    List<Object?> get props => [reviewId];
  }

  class MarkReviewAsHelpful extends ReviewEvent {
    final String reviewId;
    final String userId;

    const MarkReviewAsHelpful(this.reviewId, this.userId);

    @override
    List<Object?> get props => [reviewId, userId];
  }

  class UnmarkReviewAsHelpful extends ReviewEvent {
    final String reviewId;
    final String userId;

    const UnmarkReviewAsHelpful(this.reviewId, this.userId);

    @override
    List<Object?> get props => [reviewId, userId];
  }