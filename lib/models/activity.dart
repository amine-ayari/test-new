import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/review.dart';
import 'package:latlong2/latlong.dart';

class Activity extends Equatable {
  final String? id;  // Make ID nullable for new activities
  final String name;
  final String category;
  final String location;
  final double price;
  final double rating;
  final List<Review> reviews;
  final String image;
  final String description;
  final String duration;
  final List<String> includes;
  final List<String> excludes;
  final Provider provider;
  final List<String> images;
  final double latitude;
  final double longitude;
  final List<AvailableDate> availableDates;
  final List<AvailableTime> availableTimes;
  final List<String> tags;
  final bool isFavorite;
  final bool requiresApproval;

  // 'capacity' n'est plus un champ obligatoire (nullable)
  final int?
      capacity; // Utilisez `int?` au lieu de `int` pour rendre ce champ nullable.

  const Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.description,
    required this.duration,
    required this.includes,
    required this.excludes,
    required this.provider,
    required this.images,
    required this.latitude,
    required this.longitude,
    required this.availableDates,
    required this.availableTimes,
    required this.tags,
    this.isFavorite = false,
    this.capacity, // Le champ capacity n'est plus requis
    required this.requiresApproval,
  });

  @override
  List<Object?> get props => [
        id, name, category, location, price, rating, reviews, image,
        description, duration, includes, excludes, provider, images,
        latitude, longitude, availableDates, availableTimes, tags, isFavorite,
        capacity, // Ajout de capacity ici
        requiresApproval,
      ];

 factory Activity.fromJson(Map<String, dynamic> json) {
  return Activity(
    id: json['_id']?.toString() ?? json['id']?.toString(),  // Handle both MongoDB _id and regular id
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    location: json['location'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    rating: (json['rating'] ?? 0).toDouble(),
    reviews: (json['reviews'] as List?)
            ?.map((e) => Review.fromJson(e))
            .toList() ??
        [],
    image: json['image'] ?? 'https://res.cloudinary.com/dpl8pr4y7/image/upload/v1745336268/ufab63vrlt62wskfy8km.jpg',
    description: json['description'] ?? '',
    duration: json['duration']?.toString() ?? '',
    includes: List<String>.from(json['includes'] ?? []),
    excludes: List<String>.from(json['excludes'] ?? []),
    provider: json['provider'] is Map<String, dynamic>
        ? Provider.fromJson(json['provider'])
        : Provider(
            id: json['provider'] ?? '',
            name: '',
            rating: 0.0,
            verified: false,
            image: '',
            phone: '',
            email: '',
          ),
    images: List<String>.from(json['images'] ?? []),
    latitude: (json['latitude'] ?? 0.0).toDouble(),
    longitude: (json['longitude'] ?? 0.0).toDouble(),
    availableDates: (json['availableDates'] as List?)
            ?.map((e) => AvailableDate.fromJson(e))
            .toList() ??
        [],
    availableTimes: (json['availableTimes'] as List?)
            ?.map((e) => AvailableTime.fromJson(e))
            .toList() ??
        [],
    tags: List<String>.from(json['tags'] ?? []),
    isFavorite: json['isFavorite'] ?? false,
    capacity: json['capacity'], // peut être null
    requiresApproval: json['requiresApproval'] ?? false,
  );
}

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,  // Only include _id if it exists
      'name': name,
      'category': category,
      'location': location,
      'price': price,
      'rating': rating,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'image': image,
      'description': description,
      'duration': duration,
      'includes': includes,
      'excludes': excludes,
      'provider': provider.toJson(),
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
      'availableDates': availableDates.map((d) => d.toJson()).toList(),
      'availableTimes': availableTimes.map((t) => t.toJson()).toList(),
      'tags': tags,
      'isFavorite': isFavorite,
      if (capacity != null) 'capacity': capacity,
      'requiresApproval': requiresApproval,
    };
  }

  Activity copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    double? price,
    double? rating,
    List<Review>? reviews,
    String? image,
    String? description,
    String? duration,
    List<String>? includes,
    List<String>? excludes,
    Provider? provider,
    List<String>? images,
    double? latitude,
    double? longitude,
    List<AvailableDate>? availableDates,
    List<AvailableTime>? availableTimes,
    List<String>? tags,
    bool? isFavorite,
    int? capacity, // Le champ capacity est maintenant optionnel
    bool? requiresApproval,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      image: image ?? this.image,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      provider: provider ?? this.provider,
      images: images ?? this.images,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availableDates: availableDates ?? this.availableDates,
      availableTimes: availableTimes ?? this.availableTimes,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      capacity: capacity ??
          this.capacity, // Si 'capacity' n'est pas fourni, utiliser l'existant
      requiresApproval: requiresApproval ?? this.requiresApproval,
    );
  }

  double distanceFrom(double lat, double lng) {
    if (latitude == null || longitude == null) {
      return double.infinity;
    }

    final distance = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(lat, lng),
      LatLng(latitude!, longitude!),
    );

    return distance;
  }
}

class Provider extends Equatable {
  final String id;
  final String name;
  final double rating;
  final bool verified;
  final String image;
  final String phone;
  final String email;
  final String? description;
  final String? website;

  const Provider({
    required this.id,
    required this.name,
    required this.rating,
    required this.verified,
    required this.image,
    required this.phone,
    required this.email,
    this.description,
    this.website,
  });

  @override
  List<Object?> get props =>
      [id, name, rating, verified, image, phone, email, description, website];

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'] ?? '',
      name: json['name'],
      rating: json['rating'].toDouble(),
      verified: json['verified'],
      image: json['image'] ?? '',
      phone: json['phone'],
      email: json['email'],
      description: json['description'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'verified': verified,
      'image': image,
      'phone': phone,
      'email': email,
      'description': description,
      'website': website,
    };
  }

  Provider copyWith({
    String? id,
    String? name,
    double? rating,
    bool? verified,
    String? image,
    String? phone,
    String? email,
    String? description,
    String? website,
  }) {
    return Provider(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      verified: verified ?? this.verified,
      image: image ?? this.image,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      description: description ?? this.description,
      website: website ?? this.website,
    );
  }
}

class AvailableDate extends Equatable {
  final DateTime date;
  final bool available;

  const AvailableDate({
    required this.date,
    required this.available,
  });

  @override
  List<Object?> get props => [date, available];

  factory AvailableDate.fromJson(Map<String, dynamic> json) {
    return AvailableDate(
      date: DateTime.parse(json['date']),
      available: json['available'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'available': available,
    };
  }

  AvailableDate copyWith({
    DateTime? date,
    bool? available,
  }) {
    return AvailableDate(
      date: date ?? this.date,
      available: available ?? this.available,
    );
  }
}

class AvailableTime extends Equatable {
  final String time;
  final bool available;

  const AvailableTime({
    required this.time,
    required this.available,
  });

  @override
  List<Object?> get props => [time, available];

  factory AvailableTime.fromJson(Map<String, dynamic> json) {
    return AvailableTime(
      time: json['time'],
      available: json['available'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'available': available,
    };
  }

  AvailableTime copyWith({
    String? time,
    bool? available,
  }) {
    return AvailableTime(
      time: time ?? this.time,
      available: available ?? this.available,
    );
  }
}
