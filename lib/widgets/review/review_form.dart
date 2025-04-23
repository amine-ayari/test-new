import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/review/review_bloc.dart';
import 'package:flutter_activity_app/bloc/review/review_event.dart';
import 'package:flutter_activity_app/models/review.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReviewForm extends StatefulWidget {
  final String activityId;
  final User currentUser;
  final Function() onReviewSubmitted;

  const ReviewForm({
    Key? key,
    required this.activityId,
    required this.currentUser,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0;
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          _selectedImages.add(File(image.path));
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitReview() async {
    if (_formKey.currentState!.validate() && _rating > 0) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // In a real app, you would upload images to a server and get URLs back
        // For this example, we'll just use placeholder URLs
        final List<String> imageUrls = _selectedImages.map((file) => 
          'https://example.com/images/${const Uuid().v4()}.jpg'
        ).toList();

        final review = Review(
          id: const Uuid().v4(),
          userId: widget.currentUser.id,
          activityId: widget.activityId,
          userName: widget.currentUser.name,
          userAvatar: widget.currentUser.profileImage ?? 'https://ui-avatars.com/api/?name=${widget.currentUser.name}',
          rating: _rating,
          comment: _commentController.text.trim(),
          date: DateTime.now(),
          images: imageUrls,
          helpfulCount: 0,
          usersThatFoundHelpful: [],
        );

        context.read<ReviewBloc>().add(AddReview(review));
        widget.onReviewSubmitted();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez attribuer une note')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre avis sur cette activité',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Rating
          Text(
            'Note',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Comment
          Text(
            'Commentaire',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _commentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Partagez votre expérience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.black12 : Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer un commentaire';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Images
          Text(
            'Photos (optionnel)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_selectedImages.isNotEmpty)
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Soumettre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}