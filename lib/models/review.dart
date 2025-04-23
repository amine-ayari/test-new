import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String userId;
  final String activityId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime date;
  final List<String> images; // Optional images attached to review
  final int helpfulCount; // Number of users who found this review helpful
  final List<String> usersThatFoundHelpful; // IDs of users who found this helpful

  const Review({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
    this.images = const [],
    this.helpfulCount = 0,
    this.usersThatFoundHelpful = const [],
  });

  @override
  List<Object?> get props => [
    id, userId, activityId, userName, userAvatar, 
    rating, comment, date, images, helpfulCount, usersThatFoundHelpful
  ];

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      activityId: json['activityId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      images: List<String>.from(json['images'] ?? []),
      helpfulCount: json['helpfulCount'] ?? 0,
      usersThatFoundHelpful: List<String>.from(json['usersThatFoundHelpful'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
      'images': images,
      'helpfulCount': helpfulCount,
      'usersThatFoundHelpful': usersThatFoundHelpful,
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? activityId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? comment,
    DateTime? date,
    List<String>? images,
    int? helpfulCount,
    List<String>? usersThatFoundHelpful,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      images: images ?? this.images,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      usersThatFoundHelpful: usersThatFoundHelpful ?? this.usersThatFoundHelpful,
    );
  }
}