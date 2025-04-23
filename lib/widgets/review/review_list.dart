// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/review/review_bloc.dart';
import 'package:flutter_activity_app/bloc/review/review_event.dart';
import 'package:flutter_activity_app/bloc/review/review_state.dart';
import 'package:flutter_activity_app/models/review.dart';
import 'package:flutter_activity_app/widgets/review/review_item.dart';
import 'package:flutter_activity_app/config/app_theme.dart';

class ReviewList extends StatelessWidget {
  final String activityId;
  final String currentUserId;
  final Function() onAddReviewPressed;

  const ReviewList({
    Key? key,
    required this.activityId,
    required this.currentUserId,
    required this.onAddReviewPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewBloc, ReviewState>(
      builder: (context, state) {
        if (state is ReviewLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is ReviewsLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewHeader(context, state),
              const SizedBox(height: 16),
              if (state.reviews.isEmpty)
                _buildEmptyReviews(context)
              else
                _buildReviewsList(context, state.reviews),
            ],
          );
        } else if (state is ReviewError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildReviewHeader(BuildContext context, ReviewsLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black26
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${state.reviews.length} avis',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAddReviewPressed,
          icon: const Icon(Icons.rate_review_outlined, size: 16),
          label: const Text('Ajouter un avis'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyReviews(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white30
                : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun avis pour le moment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à donner votre avis !',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onAddReviewPressed,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter un avis'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, List<Review> reviews) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewItem(
          review: review,
          currentUserId: currentUserId,
          onMarkHelpful: (reviewId) {
            context.read<ReviewBloc>().add(MarkReviewAsHelpful(reviewId, currentUserId));
          },
          onUnmarkHelpful: (reviewId) {
            context.read<ReviewBloc>().add(UnmarkReviewAsHelpful(reviewId, currentUserId));
          },
        );
      },
    );
  }
}