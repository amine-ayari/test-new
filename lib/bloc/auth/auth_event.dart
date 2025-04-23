import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/auth_credentials.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/models/auth_credentials.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class UpdateUserRole extends AuthEvent {
  final UserRole role;

  const UpdateUserRole(this.role);

  @override
  List<Object?> get props => [role];
}

class RegisterRequested extends AuthEvent {
  final RegisterRequest request;

  const RegisterRequested(this.request);

  @override
  List<Object?> get props => [request];
}

class LoginRequested extends AuthEvent {
  final LoginRequest request;

  const LoginRequested(this.request);

  @override
  List<Object?> get props => [request];
}

class PhoneLoginRequested extends AuthEvent {
  final String phoneNumber;
  final String code;

  const PhoneLoginRequested(this.phoneNumber, this.code);

  @override
  List<Object?> get props => [phoneNumber, code];
}

// auth_event.dart
class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class PhoneVerificationRequested extends AuthEvent {
  final String phoneNumber;

  const PhoneVerificationRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}


class PhoneCodeVerified extends AuthEvent {
  final String phoneNumber;
  final String code;

  const PhoneCodeVerified(this.phoneNumber, this.code);

  @override
  List<Object?> get props => [phoneNumber, code];
}

class PasswordReset extends AuthEvent {
  final ResetPasswordRequest request;

  const PasswordReset(this.request);

  @override
  List<Object?> get props => [request];
}

class PasswordChanged extends AuthEvent {
  final String userId;
  final String oldPassword;
  final String newPassword;

  const PasswordChanged(this.userId, this.oldPassword, this.newPassword);

  @override
  List<Object?> get props => [userId, oldPassword, newPassword];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class UserUpdated extends AuthEvent {
  final User user;

  const UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class SocialLoginRequested extends AuthEvent {
  final SocialLoginRequest request;

  const SocialLoginRequested(this.request);

  @override
  List<Object?> get props => [request];
}