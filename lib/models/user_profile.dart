class UserProfile {
  final String id;
  final String name;
  final String email;
  String? profileImage;  // Modifié pour être non-final
  final String? phoneNumber;
  final String? address;
  final String? bio;
  final DateTime? birthDate;
  final List<dynamic>? preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,  // Permet de modifier la valeur
    this.phoneNumber,
    this.address,
    this.bio,
    this.birthDate,
    this.preferences,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      bio: json['bio'],
       birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate']) // Parse the birthDate from JSON
          : null,
      preferences: json['preferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'address': address,
      'bio': bio,
      'birthDate': birthDate?.toIso8601String(),
      
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? phoneNumber,
    String? address,
    String? bio,
    DateTime? birthDate,
    List<dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      preferences: preferences ?? this.preferences,
    );
  }
}
