import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/user.dart'; // Assurez-vous que le fichier user.dart contient l'énumération UserRole

 // Assurez-vous que le fichier user.dart contient l'énumération UserRole

class AuthCredentials {
  final String email;
  final String password;
  final String? phoneNumber;
  final UserRole role;
  final String? address;
  final String? profileImage;
  final String? bio;
  final List<String> favoriteActivities;
  final String? token;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final DateTime? birthDate;  // Declare the birthDate field

  AuthCredentials({
    required this.email,
    required this.password,
    this.phoneNumber,
    required this.role,
    this.address,
    this.profileImage,
    this.bio,
    this.favoriteActivities = const [],
    this.token,
    this.refreshToken,
    this.tokenExpiry,
    this.birthDate,  // Add birthDate to the constructor
  });

  bool get isTokenValid {
    if (token == null || tokenExpiry == null) return false;
    return DateTime.now().isBefore(tokenExpiry!);
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'address': address,
      'profileImage': profileImage,
      'bio': bio,
      'favoriteActivities': favoriteActivities,
      'token': token,
      'refreshToken': refreshToken,
      'tokenExpiry': tokenExpiry?.toIso8601String(),
      'birthDate': birthDate?.toIso8601String(), // Include birthDate in the toJson method
    };
  }

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    List<String> favoriteActivitiesList = [];
    if (json['favoriteActivities'] != null && json['favoriteActivities'] is List) {
      favoriteActivitiesList = List<String>.from(json['favoriteActivities']);
    }

    return AuthCredentials(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: _parseRole(json['role']),
      address: json['address'],
      profileImage: json['profileImage'],
      bio: json['bio'],
      favoriteActivities: favoriteActivitiesList,
      token: json['token'],
      refreshToken: json['refreshToken'],
      tokenExpiry: json['tokenExpiry'] != null 
          ? DateTime.parse(json['tokenExpiry']) 
          : null,
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null, // Parse birthDate from the JSON
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

  AuthCredentials copyWith({
    String? email,
    String? password,
    String? phoneNumber,
    UserRole? role,
    String? address,
    String? profileImage,
    String? bio,
    List<String>? favoriteActivities,
    String? token,
    String? refreshToken,
    DateTime? tokenExpiry,
  }) {
    return AuthCredentials(
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      favoriteActivities: favoriteActivities ?? this.favoriteActivities,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }
}
class RegisterRequest extends Equatable {
  final String name;
  final String email;
  final String password;
  final String? phoneNumber;
  final UserRole role;
  final String? providerId;
  final String? providerName;
  final String? providerDescription;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
    required this.role,
    this.providerId,
    this.providerName,
    this.providerDescription,
  });

  @override
  List<Object?> get props => [
    name, email, password, phoneNumber, role, 
    providerId, providerName, providerDescription
  ];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'providerId': providerId,
      'providerName': providerName,
      'providerDescription': providerDescription,
    };
  }
}

class LoginRequest extends Equatable {
  final String email;
  final String password;
 

  const LoginRequest({
    required this.email,
    required this.password,

  });

  @override
  List<Object?> get props => [email, password];

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      
    };
  }
}

class ResetPasswordRequest extends Equatable {
  final String? email;
  final String? phoneNumber;
  final String? code;
  final String? newPassword;

  const ResetPasswordRequest({
    this.email,
    this.phoneNumber,
    this.code,
    this.newPassword,
  });

  @override
  List<Object?> get props => [email, phoneNumber, code, newPassword];

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'code': code,
      'newPassword': newPassword,
    };
  }
}

class AuthResponse {
  final bool success;
  final String? message;
  final User? user;
  final String? token;
  final String? refreshToken;
  final DateTime? tokenExpiry;

  const AuthResponse({
    required this.success,
    this.message,
    this.user,
    this.token,
    this.refreshToken,
    this.tokenExpiry,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
      refreshToken: json['refreshToken'],
      tokenExpiry: json['tokenExpiry'] != null 
          ? DateTime.parse(json['tokenExpiry']) 
          : null,
    );
  }
}
enum SocialLoginProvider {
  google,
  facebook,
  apple
}

class SocialLoginRequest extends Equatable {
  final SocialLoginProvider provider;
  final String? accessToken;
  final String? idToken;
  final Map<String, dynamic>? userData;

  const SocialLoginRequest({
    required this.provider,
    this.accessToken,
    this.idToken,
    this.userData,
  });

  @override
  List<Object?> get props => [provider, accessToken, idToken, userData];

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.toString().split('.').last,
      'accessToken': accessToken,
      'idToken': idToken,
      'userData': userData,
    };
  }
}