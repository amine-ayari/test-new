import 'package:equatable/equatable.dart';
import 'package:flutter_activity_app/models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;
  final String token;

  const Authenticated(this.user, this.token);

  @override
  List<Object?> get props => [user, token];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class RegistrationSuccess extends AuthState {
  final User user;
  final String token;

  const RegistrationSuccess(this.user, this.token);

  @override
  List<Object?> get props => [user, token];
}

class LoginSuccess extends AuthState {
  final User user;
  final String token;

  const LoginSuccess(this.user, this.token);

  @override
  List<Object?> get props => [user, token];
}

class PasswordResetRequested extends AuthState {
  final String email;

  const PasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class PhoneVerificationRequested extends AuthState {
  final String phoneNumber;

  const PhoneVerificationRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class PhoneVerified extends AuthState {
  final String phoneNumber;

  const PhoneVerified(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}

class PasswordChangeSuccess extends AuthState {
  const PasswordChangeSuccess();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
