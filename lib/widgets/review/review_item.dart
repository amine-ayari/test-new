import 'package:flutter/material.dart';
import 'package:flutter_activity_app/models/review.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewItem extends StatelessWidget {
  final Review review;
  final String currentUserId;
  final Function(String) onMarkHelpful;
  final Function(String) onUnmarkHelpful;

  const ReviewItem({
    Key? key,
    required this.review,
    required this.currentUserId,
    required this.onMarkHelpful,
    required this.onUnmarkHelpful,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isHelpful = review.usersThatFoundHelpful.contains(currentUserId);
    final isOwnReview = review.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(review.userAvatar),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (isOwnReview) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Vous',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(review.date, locale: 'fr'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRatingStars(review.rating),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : AppTheme.textSecondaryColor,
            ),
          ),
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isOwnReview)
                TextButton.icon(
                  onPressed: () {
                    if (isHelpful) {
                      onUnmarkHelpful(review.id);
                    } else {
                      onMarkHelpful(review.id);
                    }
                  },
                  icon: Icon(
                    isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 16,
                    color: isHelpful ? AppTheme.primaryColor : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
                  ),
                  label: Text(
                    isHelpful ? 'Utile (${review.helpfulCount})' : 'Marquer comme utile (${review.helpfulCount})',
                    style: TextStyle(
                      color: isHelpful ? AppTheme.primaryColor : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              if (isOwnReview) ...[
                TextButton.icon(
                  onPressed: () {
                    // Edit review
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                  label: Text(
                    'Modifier',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Delete review
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                  label: Text(
                    'Supprimer',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star_rounded, color: Colors.amber, size: 16);
        } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
          return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_outline_rounded, color: Colors.amber, size: 16);
        }
      }),
    );
  }
}