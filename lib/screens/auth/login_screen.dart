import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_activity_app/screens/auth/role_selection_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/auth/auth_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/auth_credentials.dart';
// Make sure this is imported
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/screens/auth/forgot_password_screen.dart';
import 'package:flutter_activity_app/screens/auth/phone_login_screen.dart';
import 'package:flutter_activity_app/screens/auth/register_screen.dart';
import 'package:flutter_activity_app/screens/client/client_main_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_main_screen.dart';
import 'package:flutter_activity_app/services/social_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AuthBloc _authBloc;
  final _socialAuthService = getIt<SocialAuthService>();
  bool _rememberMe = false;
  bool _isSocialLoading = false;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text);
    } else {
      await prefs.remove('saved_email');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSocialLoading) return;

    setState(() {
      _isSocialLoading = true;
    });

    try {
      final request = await _socialAuthService.signInWithGoogle();
      if (request != null) {
        _authBloc.add(SocialLoginRequested(request));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    if (_isSocialLoading) return;

    setState(() {
      _isSocialLoading = true;
    });

    try {
      final request = await _socialAuthService.signInWithFacebook();
      if (request != null) {
        _authBloc.add(SocialLoginRequested(request));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Facebook sign in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isSocialLoading) return;

    setState(() {
      _isSocialLoading = true;
    });

    try {
      final request = await _socialAuthService.signInWithApple();
      if (request != null) {
        _authBloc.add(SocialLoginRequested(request));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple sign in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Authenticated) {
            _saveCredentials();
            _navigateToHome(state.user);
          }
        },
        child: Scaffold(
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildLoginForm(state),
                        const SizedBox(height: 24),
                        _buildLoginButton(state),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSocialLoginButtons(state),
                        const SizedBox(height: 16),
                        _buildPhoneLoginButton(),
                        const SizedBox(height: 32),
                        _buildRegisterButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.hiking,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to your activities',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            enabled: state is! AuthLoading,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
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
                return 'Please enter your password';
              }
              return null;
            },
            enabled: state is! AuthLoading,
          ),
          const SizedBox(height: 12),
          _buildRememberMe(),
        ],
      ),
    );
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        const Text('Remember me'),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthState state) {
    final isLoading = state is AuthLoading;

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              if (_formKey.currentState?.validate() ?? false) {
                _authBloc.add(
                  LoginRequested(
                    LoginRequest(
                      email: _emailController.text,
                      password: _passwordController.text,
                    ),
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildSocialLoginButtons(AuthState state) {
    final isLoading = state is AuthLoading || _isSocialLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Or continue with',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialIconButton(
              icon: 'assets/icons/google.png',
              onPressed: isLoading ? null : _handleGoogleSignIn,
              backgroundColor: Colors.white,
              borderColor: Colors.grey[300]!,
              isLoading: isLoading,
            ),
            _buildSocialIconButton(
              icon: 'assets/icons/facebook.png',
              onPressed: isLoading ? null : _handleFacebookSignIn,
              backgroundColor: const Color(0xFF1877F2),
              isLoading: isLoading,
            ),
            if (Platform.isIOS)
              _buildSocialIconButton(
                icon: 'assets/icons/apple.png',
                onPressed: isLoading ? null : _handleAppleSignIn,
                backgroundColor: Colors.black,
                isLoading: isLoading,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIconButton({
    required String icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    Color? borderColor,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isLoading ? backgroundColor.withOpacity(0.7) : backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      backgroundColor == Colors.white
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                    ),
                  ),
                )
              : Image.asset(
                  icon,
                  height: 30,
                  width: 30,
                ),
        ),
      ),
    );
  }

  Widget _buildPhoneLoginButton() {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PhoneLoginScreen(),
          ),
        );
      },
      icon: const Icon(Icons.phone_outlined),
      label: const Text('Login with Phone Number'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Theme.of(context).primaryColor),
        foregroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(color: Colors.grey[700]),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text(
            'Register',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _navigateToHome(User user) {
  if (!user.hasRole) {
    // User doesn't have a role yet, navigate to role selection
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RoleSelectionScreen(user: user),
      ),
    );
  } else if (user.isClient) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClientMainScreen(user: user),
      ),
    );
  } else if (user.isProvider) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderMainScreen(user: user),
      ),
    );
  }
}

}
