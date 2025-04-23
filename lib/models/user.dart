import 'package:equatable/equatable.dart';

enum UserRole { client, provider, admin, none }
enum VerificationStatus { notSubmitted, pending, approved, rejected }
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImage;
  final String? bio;
  final String? address;
  final String? businessName; // Optional field
  final String? taxId; // Optional field
  final String? nationalId; // Optional field
  final UserRole role;
  final String? providerId;
  final bool isVerified;
  final DateTime createdAt;
  final VerificationStatus verificationStatus;
  final Map<String, dynamic> preferences;
  final List<String> favoriteActivities;
  final DateTime? birthDate; // Nullable birthDate

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImage,
    this.bio,
    this.address,
    this.businessName, // Optional
    this.taxId, // Optional
    this.nationalId, // Optional
    required this.role,
    this.providerId,
    this.isVerified = false,
    required this.createdAt,
    this.preferences = const {},
    this.favoriteActivities = const [],
    this.verificationStatus = VerificationStatus.notSubmitted,
    this.birthDate,  // Nullable birthDate
  });

  // Add these getters to fix the errors
  bool get isClient => role == UserRole.client;
  bool get isProvider => role == UserRole.provider;
  bool get isAdmin => role == UserRole.admin;
  bool get hasRole => role != UserRole.none;
  bool get isApproved => verificationStatus == VerificationStatus.approved;

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        firstName,
        lastName,
        phoneNumber,
        profileImage,
        bio,
        address,
        businessName, // Optional field in props
        taxId, // Optional field in props
        nationalId, // Optional field in props
        role,
        providerId,
        isVerified,
        createdAt,
        preferences,
        favoriteActivities,
        birthDate,  // Include birthDate in props
        verificationStatus, // Add verificationStatus
      ];

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle preferences field which might be null
    Map<String, dynamic> preferencesMap = {};
    if (json['preferences'] != null && json['preferences'] != 'undefined') {
      preferencesMap = Map<String, dynamic>.from(json['preferences']);
    }

    // Handle favoriteActivities which might be null
    List<String> favoriteActivitiesList = [];
    if (json['favoriteActivities'] != null &&
        json['favoriteActivities'] is List) {
      favoriteActivitiesList = List<String>.from(
          json['favoriteActivities'].map((x) => x.toString()));
    }

    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      bio: json['bio'],
      address: json['address'] == 'undefined' ? null : json['address'],
      businessName: json['businessName'], // Optional field
      taxId: json['taxId'], // Optional field
      nationalId: json['nationalId'], // Optional field
      role: _parseRole(json['role']),
      providerId: json['providerId']?.toString(),
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      preferences: preferencesMap,
      favoriteActivities: favoriteActivitiesList,
      verificationStatus: _parseVerificationStatus(json['verificationStatus']),
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate']) // Parse the birthDate from JSON
          : null, // Handle birthDate being null
    );
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'provider':
        return UserRole.provider;
      case 'admin':
        return UserRole.admin;
      case 'none':
        return UserRole.none;
      case 'client':
      default:
        return UserRole.client;
    }
  }

  static VerificationStatus _parseVerificationStatus(String? statusStr) {
    switch (statusStr?.toLowerCase()) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'notsubmitted':
      default:
        return VerificationStatus.notSubmitted;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'bio': bio,
      'address': address,
      'businessName': businessName, // Optional field
      'taxId': taxId, // Optional field
      'nationalId': nationalId, // Optional field
      'role': role.toString().split('.').last,
      'providerId': providerId,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences,
      'favoriteActivities': favoriteActivities,
      'birthDate': birthDate?.toIso8601String(), // Convert birthDate to string for JSON
      'verificationStatus': verificationStatus.toString().split('.').last, // Add verification status
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImage,
    String? bio,
    String? address,
    String? businessName, // Optional
    String? taxId, // Optional
    String? nationalId, // Optional
    UserRole? role,
    String? providerId,
    bool? isVerified,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
    List<String>? favoriteActivities,
    DateTime? birthDate, // Optional birthDate
    VerificationStatus? verificationStatus, // Optional verificationStatus
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      businessName: businessName ?? this.businessName, // Allow updating businessName
      taxId: taxId ?? this.taxId, // Allow updating taxId
      nationalId: nationalId ?? this.nationalId, // Allow updating nationalId
      role: role ?? this.role,
      providerId: providerId ?? this.providerId,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
      favoriteActivities: favoriteActivities ?? this.favoriteActivities,
      birthDate: birthDate ?? this.birthDate, // Allow updating birthDate
      verificationStatus: verificationStatus ?? this.verificationStatus, // Allow updating verificationStatus
    );
  }
}
