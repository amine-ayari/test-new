import 'package:flutter_activity_app/services/social_auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/auth/auth_state.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart' as event;
import 'package:flutter_activity_app/bloc/auth/auth_state.dart' as authStatess;

import 'package:flutter_activity_app/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  final SocialAuthService _socialAuthService;
  AuthBloc(this._authRepository, this._socialAuthService)
      : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<RegisterRequested>(_onRegisterRequested);
    on<LoginRequested>(_onLoginRequested);
    on<PhoneLoginRequested>(_onPhoneLoginRequested);
    on<event.PasswordResetRequested>(_onPasswordResetRequested);
    on<event.PhoneVerificationRequested>(_onPhoneVerificationRequested);
    on<PhoneCodeVerified>(_onPhoneCodeVerified);
    on<PasswordReset>(_onPasswordReset);
    on<PasswordChanged>(_onPasswordChanged);
    on<LogoutRequested>(_onLogoutRequested);
    on<UserUpdated>(_onUserUpdated);
    on<SocialLoginRequested>(_onSocialLoginRequested);
      on<UpdateUserRole>(_onUpdateUserRole);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        final token = await _authRepository.getToken();

        if (user != null && token != null) {
          emit(Authenticated(user, token));
        } else {
          emit(const Unauthenticated());
        }
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      
      final response = await _authRepository.register(event.request);

      if (response.success && response.user != null && response.token != null) {
        emit(RegistrationSuccess(response.user!, response.token!));
        emit(Authenticated(response.user!, response.token!));
      } else {
        emit(AuthError(response.message ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _authRepository.login(event.request);

      if (response.success && response.user != null && response.token != null) {
        emit(LoginSuccess(response.user!, response.token!));
        emit(Authenticated(response.user!, response.token!));
      } else {
        emit(AuthError(response.message ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onPhoneLoginRequested(
    PhoneLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response =
          await _authRepository.loginWithPhone(event.phoneNumber, event.code);

      if (response.success && response.user != null && response.token != null) {
        emit(LoginSuccess(response.user!, response.token!));
        emit(Authenticated(response.user!, response.token!));
      } else {
        emit(AuthError(response.message ?? 'Phone login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onPasswordResetRequested(
    event.PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success = await _authRepository.requestPasswordReset(event.email);

      if (success) {
        emit(authStatess.PasswordResetRequested(event.email));
      } else {
        emit(const AuthError('Password reset request failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onPhoneVerificationRequested(
    event.PhoneVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success =
          await _authRepository.requestPhoneVerification(event.phoneNumber);

      if (success) {
        emit(authStatess.PhoneVerificationRequested(event.phoneNumber));
      } else {
        emit(const AuthError('Phone verification request failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onPhoneCodeVerified(
    PhoneCodeVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success =
          await _authRepository.verifyPhoneCode(event.phoneNumber, event.code);

      if (success) {
        emit(PhoneVerified(event.phoneNumber));
      } else {
        emit(const AuthError('Phone verification failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onPasswordReset(
    PasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success = await _authRepository.resetPassword(event.request);

      if (success) {
        emit(const PasswordResetSuccess());
      } else {
        emit(const AuthError('Password reset failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onPasswordChanged(
    PasswordChanged event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success = await _authRepository.changePassword(
        event.userId,
        event.oldPassword,
        event.newPassword,
      );

      if (success) {
        emit(const PasswordChangeSuccess());
      } else {
        emit(const AuthError('Password change failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final success = await _authRepository.logout();

      if (success) {
        emit(const Unauthenticated());
      } else {
        emit(const AuthError('Logout failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUserUpdated(
    UserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    if (state is Authenticated) {
      final currentState = state as Authenticated;
      emit(Authenticated(event.user, currentState.token));
    }
  }

  Future<void> _onSocialLoginRequested(
    SocialLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response =
          await _authRepository.loginWithSocialProvider(event.request);

      if (response.success && response.user != null && response.token != null) {
        emit(LoginSuccess(response.user!, response.token!));
        emit(Authenticated(response.user!, response.token!));
      } else {
        emit(AuthError(response.message ?? 'Social login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRole event, Emitter<AuthState> emit) async {
  try {
    // Emit loading state first
    emit(AuthLoading());

    // Update the user role through the repository
    final user = await _authRepository.updateUserRole(event.role);

    // Check if the current state is Authenticated
    if (state is Authenticated) {
      final currentState = state as Authenticated;

      // Emit the updated Authenticated state with the new user data and the current token
      emit(Authenticated(user, currentState.token));
    } else {
      // If the state is not Authenticated, we can handle it as needed.
      // In this case, we can just emit the Authenticated state with the updated user and a new token.
      final token = await _authRepository.getToken(); // Or retrieve the token from your source
      emit(Authenticated(user, token.toString()));
    }
  } catch (e) {
    emit(AuthError(e.toString())); // Emit error if something fails
  }
}

}
