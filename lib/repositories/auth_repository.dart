import 'package:flutter_activity_app/models/auth_credentials.dart';
import 'package:flutter_activity_app/models/user.dart';

abstract class AuthRepository {
  Future<AuthResponse> register(RegisterRequest request);
  Future<AuthResponse> login(LoginRequest request);
  Future<AuthResponse> loginWithPhone(String phoneNumber, String code);
  Future<bool> requestPasswordReset(String email);
  Future<bool> requestPhoneVerification(String phoneNumber);
  Future<bool> verifyPhoneCode(String phoneNumber, String code);
  Future<bool> resetPassword(ResetPasswordRequest request);
  Future<bool> changePassword(
      String userId, String oldPassword, String newPassword);
  Future<bool> logout();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<bool> refreshToken();
  Future<AuthResponse> loginWithSocialProvider(SocialLoginRequest request);
  Future<User> updateUserRole(UserRole role);
}
