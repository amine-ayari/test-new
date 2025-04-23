import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart' as auth_event; // Add prefix
import 'package:flutter_activity_app/bloc/auth/auth_state.dart' as auth_state; // Add prefix
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/auth_credentials.dart';
import 'package:flutter_activity_app/screens/auth/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _codeSent = false;
  bool _codeVerified = false;
  String? _verificationEmail;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forgot Password'),
          elevation: 0,
        ),
        body: BlocConsumer<AuthBloc, auth_state.AuthState>( // Use the correct prefix
          listener: (context, state) {
            if (state is auth_state.AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is auth_state.PasswordResetRequested) { // Use the correct prefix
              setState(() {
                _codeSent = true;
                _verificationEmail = state.email;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code sent to your email')),
              );
            }  else if (state is auth_state.PasswordResetSuccess) { // Use the correct prefix
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset successfully')),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(state),
                    const SizedBox(height: 24),
                    _buildActionButton(state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    String subtitle;
    
    if (!_codeSent) {
      title = 'Forgot Password';
      subtitle = 'Enter your email to receive a verification code';
    } else if (!_codeVerified) {
      title = 'Verify Code';
      subtitle = 'Enter the verification code sent to your email';
    } else {
      title = 'Reset Password';
      subtitle = 'Enter your new password';
    }
    
    return Column(
      children: [
        Icon(
          Icons.lock_reset,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildForm(auth_state.AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_codeSent)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              enabled: state is! auth_state.AuthLoading,
            ),
          if (_codeSent && !_codeVerified) ...[
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the verification code';
                }
                return null;
              },
              enabled: state is! auth_state.AuthLoading,
            ),
          ],
          if (_codeVerified) ...[
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              enabled: state is! auth_state.AuthLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              enabled: state is! auth_state.AuthLoading,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(auth_state.AuthState state) {
    String buttonText;
    
    if (!_codeSent) {
      buttonText = 'Send Verification Code';
    } else if (!_codeVerified) {
      buttonText = 'Verify Code';
    } else {
      buttonText = 'Reset Password';
    }
    
    return ElevatedButton(
      onPressed: state is auth_state.AuthLoading
          ? null
          : () {
              if (_formKey.currentState?.validate() ?? false) {
                if (!_codeSent) {
                  _authBloc.add(
                    auth_event.PasswordResetRequested(_emailController.text), // Corrected event name
                  );
                } else if (!_codeVerified) {
                  // In a real app, this would verify the code with the backend
                  // For demo purposes, we'll just accept any code
                  setState(() {
                    _codeVerified = true;
                  });
                } else {
                  _authBloc.add(
                    auth_event.PasswordReset(
                      ResetPasswordRequest(
                        email: _verificationEmail,
                        code: _codeController.text,
                        newPassword: _newPasswordController.text,
                      ),
                    ),
                  );
                }
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: state is auth_state.AuthLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              buttonText,
              style: const TextStyle(fontSize: 16),
            ),
    );
  }
}
