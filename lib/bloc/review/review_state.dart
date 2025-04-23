import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/review.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class ReviewsLoaded extends ReviewState {
  final List<Review> reviews;
  final double averageRating;

  const ReviewsLoaded({
    required this.reviews,
    required this.averageRating,
  });

  @override
  List<Object?> get props => [reviews, averageRating];

  ReviewsLoaded copyWith({
    List<Review>? reviews,
    double? averageRating,
  }) {
    return ReviewsLoaded(
      reviews: reviews ?? this.reviews,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}

class ReviewAdded extends ReviewState {
  final Review review;

  const ReviewAdded(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewUpdated extends ReviewState {
  final Review review;

  const ReviewUpdated(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewDeleted extends ReviewState {
  final String reviewId;

  const ReviewDeleted(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);

  @override
  List<Object?> get props => [message];
}