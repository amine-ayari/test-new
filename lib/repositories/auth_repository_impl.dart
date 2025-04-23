import 'dart:convert';
import 'package:flutter_activity_app/models/auth_credentials.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/repositories/auth_repository.dart';
import 'package:flutter_activity_app/services/api_service.dart';
import 'package:flutter_activity_app/services/exceptions.dart';
import 'package:flutter_activity_app/services/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPreferences _sharedPreferences;
  final ApiService _apiService;
  final String _userKey = 'current_user';
  final String _credentialsKey = 'auth_credentials';
  bool _useLocalStorage = false;

  AuthRepositoryImpl(
      this._sharedPreferences, this._apiService, SecureStorage secureStorage) {
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    _useLocalStorage = !(await _apiService.isBackendReachable());
    print('Use local storage' + _useLocalStorage.toString());
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      print('Register request: ${request.toJson()}'); // Log the request
      final response =
          await _apiService.post('/auth/register', request.toJson());
      final authResponse = AuthResponse.fromJson(response);

      if (authResponse.success && authResponse.user != null) {
        final credentials = AuthCredentials(
            email: request.email,
            password: request.password,
            phoneNumber: request.phoneNumber,
            role: request.role,
            token: authResponse.token,
            refreshToken: authResponse.refreshToken,
            tokenExpiry: authResponse.tokenExpiry,
            address: authResponse.user!.address, // Ensure address is provided
            profileImage: authResponse.user!.profileImage,
            favoriteActivities: authResponse
                .user!.favoriteActivities // Ensure profileImage is provided
            );

        await _saveUser(authResponse.user!);
        await _saveCredentials(credentials);
        _saveTokens(authResponse.token.toString(),
            authResponse.refreshToken.toString());
      }

      return authResponse;
    } catch (e) {
      print('Registration failed: $e'); // Log the error
      return const AuthResponse(
        success: false,
        message: 'Registration failed due to an error',
      );
    }
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('Login request: ${request.toJson()}'); // Log the request
      final response = await _apiService.post('/auth/login', request.toJson());

      if (response == null) {
        print('Login failed: Response is null');
        return const AuthResponse(
          success: false,
          message: 'Login failed: No response from server',
        );
      }

      print('Response from server: $response'); // Log the raw response

      final authResponse = AuthResponse.fromJson(response);

      if (authResponse.success && authResponse.user != null) {
        final user = authResponse.user!;
        print('User details: ${user}'); // Log the user details

        // Handle missing data gracefully
        final phoneNumber =
            user.phoneNumber ?? ''; // Default to empty string if null
        final address =
            user.address ?? 'No address provided'; // Default to address if null
        final profileImage = user.profileImage ??
            'defaultProfileImage.png'; // Default to profile image if null
        final bio = user.bio ?? 'No bio available'; // Default bio if null
        final birthDate = authResponse.user?.birthDate ?? DateTime.now();

        // Default to current date if null
        // Ensure favoriteActivities is a list
        final favoriteActivities = user.favoriteActivities ??
            const []; // Default to empty list if null

        print(
            'Processed user data: phoneNumber=$phoneNumber, address=$address, profileImage=$profileImage, bio=$bio, favoriteActivities=$favoriteActivities');
        print("ddddddddddddddddd$birthDate");
        final credentials = AuthCredentials(
          email: request.email,
          password: request.password,
          phoneNumber: phoneNumber,
          role: user.role,
          address: address,
          profileImage: profileImage,
          bio: bio,
          birthDate:
              birthDate, // Use birthDate directly if it's already a DateTime
          favoriteActivities: favoriteActivities,
          token: authResponse.token,
          refreshToken: authResponse.refreshToken,
          tokenExpiry: authResponse.tokenExpiry,
        );

        await _saveUser(user);
        await _saveCredentials(credentials);
        _saveTokens(authResponse.token.toString(),
            authResponse.refreshToken.toString());
      }

      return authResponse;
    } catch (e) {
      // Check if the error is from the API
      if (e is ApiException) {
        print('API Exception: ${e.message}');
        return AuthResponse(
          success: false,
          message: e.message ?? 'Server error occurred',
        );
      }

      // Check internet connection
      if (e is NetworkException) {
        print('Network Exception: Please check your internet connection');
        return const AuthResponse(
          success: false,
          message: 'Please check your internet connection',
        );
      }

      // Log the error for debugging
      print('Login error details: $e');

      return AuthResponse(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResponse> loginWithPhone(String phoneNumber, String code) async {
    try {
      final response = await _apiService.post('/auth/login/phone/verify', {
        'phoneNumber': phoneNumber,
        'otp': code,
      });

      final authResponse = AuthResponse.fromJson(response);

      if (authResponse.success && authResponse.user != null) {
        final user = authResponse.user!;
        final credentials = AuthCredentials(
          email: user.email ?? '', // Ensure email is provided
          password: '', // Provide a default or fetched password here
          phoneNumber: phoneNumber,
          role: user.role,
          address: user.address ??
              'No address provided', // Default to address if null
          profileImage: user.profileImage ??
              'defaultProfileImage.png', // Default to profile image if null
          bio: user.bio ?? 'No bio available', // Default bio if null
          favoriteActivities: user.favoriteActivities ??
              const [], // Default to empty list if null
          token: authResponse.token,
          refreshToken: authResponse.refreshToken,
          tokenExpiry: authResponse.tokenExpiry,
          birthDate: user.birthDate ?? DateTime.now(),
        );

        await _saveUser(user);
        await _saveCredentials(credentials);
        _saveTokens(authResponse.token.toString(),
            authResponse.refreshToken.toString());
      }

      return authResponse;
    } catch (e) {
      print('Login with phone failed: $e'); // Log the error
      return const AuthResponse(
        success: false,
        message: 'Login with phone failed due to an error',
      );
    }
  }

  @override
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _apiService.post('/auth/request-password-reset', {
        'email': email,
      });

      return response['success'] ?? false;
    } catch (e) {
      print('Password reset request failed: $e'); // Log the error
      return false;
    }
  }

  @override
  Future<bool> requestPhoneVerification(String phoneNumber) async {
    try {
      final response = await _apiService.post('/auth/login/phone/request', {
        'phoneNumber': phoneNumber,
      });

      return response['success'] ?? false;
    } catch (e) {
      print('Phone verification request failed: $e'); // Log the error
      return false;
    }
  }

  @override
  Future<bool> verifyPhoneCode(String phoneNumber, String code) async {
    try {
      final response = await _apiService.post('/auth/verify-phone', {
        'phoneNumber': phoneNumber,
        'code': code,
      });

      return response['success'] ?? false;
    } catch (e) {
      print('Phone code verification failed: $e'); // Log the error
      return false;
    }
  }

  @override
  Future<bool> resetPassword(ResetPasswordRequest request) async {
    try {
      final response =
          await _apiService.post('/auth/reset-password', request.toJson());

      return response['success'] ?? false;
    } catch (e) {
      print('Password reset failed: $e'); // Log the error
      return false;
    }
  }

  @override
  Future<bool> changePassword(
      String userId, String oldPassword, String newPassword) async {
    try {
      final response = await _apiService.post('/auth/change-password', {
        'userId': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });

      return response['success'] ?? false;
    } catch (e) {
      print('Change password failed: $e'); // Log the error
      return false;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      final token = await getToken();

      if (token != null) {
        await _apiService.post('/auth/logout', {
          'token': token,
        });
        _clearTokens();
      }

      await _sharedPreferences.remove(_userKey);
      await _sharedPreferences.remove(_credentialsKey);

      return true;
    } catch (e) {
      print('Logout failed: $e'); // Log the error
      return false;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final userJson = _sharedPreferences.getString(_userKey);

    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }

    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    final token = await getToken();

    return user != null && token != null;
  }

  @override
  Future<String?> getToken() async {
    final credentialsJson = _sharedPreferences.getString(_credentialsKey);

    if (credentialsJson != null) {
      final credentials = AuthCredentials.fromJson(jsonDecode(credentialsJson));

      if (credentials.isTokenValid) {
        return credentials.token;
      } else {
        // Token expired, try to refresh
        final refreshed = await refreshToken();

        if (refreshed) {
          final updatedCredentialsJson =
              _sharedPreferences.getString(_credentialsKey);

          if (updatedCredentialsJson != null) {
            final updatedCredentials =
                AuthCredentials.fromJson(jsonDecode(updatedCredentialsJson));

            return updatedCredentials.token;
          }
        }
      }
    }

    return null;
  }

  @override
  Future<bool> refreshToken() async {
    final credentialsJson = _sharedPreferences.getString(_credentialsKey);

    if (credentialsJson != null) {
      final credentials = AuthCredentials.fromJson(jsonDecode(credentialsJson));

      if (credentials.refreshToken != null) {
        try {
          final response = await _apiService.post('/auth/refresh-token', {
            'refreshToken': credentials.refreshToken,
          });

          if (response['success'] == true && response['token'] != null) {
            final updatedCredentials = credentials.copyWith(
              token: response['token'],
              refreshToken:
                  response['refreshToken'] ?? credentials.refreshToken,
              tokenExpiry: response['tokenExpiry'] != null
                  ? DateTime.parse(response['tokenExpiry'])
                  : null,
            );

            // 🔄 Sauvegarder les nouveaux tokens
            await _saveCredentials(updatedCredentials);
            _saveTokens(updatedCredentials.token.toString(),
                updatedCredentials.refreshToken.toString());

            return true;
          }
        } catch (e) {
          print('❌ Token refresh failed: $e');
          return false;
        }
      }
    }

    return false;
  }

  // Helper methods
  Future<void> _saveUser(User user) async {
    await _sharedPreferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _saveCredentials(AuthCredentials credentials) async {
    await _sharedPreferences.setString(
        _credentialsKey, jsonEncode(credentials.toJson()));
  }

  // Fix for the social login method in AuthRepositoryImpl
  @override
  Future<AuthResponse> loginWithSocialProvider(
      SocialLoginRequest request) async {
    try {
      final response = await _apiService.post(
        '/auth/social-login',
        {
          'provider': request.provider.toString().split('.').last,
          'accessToken': request.accessToken,
          'idToken': request.idToken,
          'userData': request.userData,
        },
      );

      // Check if the response is a map
      if (response is Map<String, dynamic>) {
        final authResponse = AuthResponse.fromJson(response);
        print('Response from server: $response'); // Log the raw response

        if (authResponse.success && authResponse.user != null) {
          final credentials = AuthCredentials(
            email: authResponse.user!.email,
            password: '', // Provide a default or fetched password here
            role: authResponse.user!.role,
            token: authResponse.token,
            refreshToken: authResponse.refreshToken,
            tokenExpiry: authResponse.tokenExpiry,
            birthDate: authResponse.user?.birthDate ?? DateTime.now(),
          );
          User user = authResponse.user!;
          await _saveUser(user);
          await _saveCredentials(credentials);
          _saveTokens(authResponse.token.toString(),
              authResponse.refreshToken.toString());
        }

        return authResponse;
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print('Social login failed: $e'); // Log the error
      return const AuthResponse(
        success: false,
        message: 'Social login failed due to an error',
      );
    }
  }

  static Future<void> _saveTokens(
      String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  static Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }

  Future<User> updateUserRole(UserRole role) async {
  try {
    final response = await _apiService.put('/users/role', {
      'role': role.toString().split('.').last, // Convert enum to string
    });

    // Parse the response as per your backend structure
    final authResponse = AuthResponse.fromJson(response);

    // Ensure that the response is valid
    if (authResponse.success && authResponse.user != null) {
      final user = authResponse.user!;

      // Create credentials for the updated user
      final credentials = AuthCredentials(
        email: user.email ?? '',
        password: '', // TODO: handle password securely
        phoneNumber: user.phoneNumber,
        role: user.role,
        address: user.address ?? 'No address provided',
        profileImage: user.profileImage ?? 'defaultProfileImage.png',
        bio: user.bio ?? 'No bio available',
        favoriteActivities: user.favoriteActivities ?? const [],
        token: authResponse.token,
        refreshToken: authResponse.refreshToken,
        tokenExpiry: authResponse.tokenExpiry,
        birthDate: user.birthDate ?? DateTime.now(),
      );

      // Save the user and credentials
      await _saveUser(user);
      await _saveCredentials(credentials);
      _saveTokens(authResponse.token ?? '', authResponse.refreshToken ?? '');

      // Return the updated user
      return user;
    } else {
      throw Exception('Erreur : utilisateur introuvable ou requête échouée');
    }
  } catch (e) {
    throw Exception('Échec de la mise à jour du rôle utilisateur: ${e.toString()}');
  }
}}
