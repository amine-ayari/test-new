import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart' as auth_event; // Add prefix
import 'package:flutter_activity_app/bloc/auth/auth_state.dart'; // Remove prefix
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/screens/client/client_main_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _rememberMe = false;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('saved_phone');
    if (savedPhone != null && savedPhone.isNotEmpty) {
      setState(() {
        _phoneController.text = savedPhone;
        _rememberMe = true;
      });
    }
  }

  Future<void> _savePhone() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_phone', _phoneController.text);
    } else {
      await prefs.remove('saved_phone');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _requestVerificationCode() {
    if (_formKey.currentState?.validate() ?? false) {
      // Use the prefix to resolve ambiguity
      _authBloc.add(auth_event.PhoneVerificationRequested(_phoneController.text));
      
      // For now, just simulate the code being sent
      setState(() {
        _codeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _verifyAndLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      _savePhone();
      _authBloc.add(
        auth_event.PhoneLoginRequested(
          _phoneController.text,
          _codeController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phone Login'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is Authenticated) {
              _navigateToHome(state.user);
            }
          },
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
                      _buildForm(state),
                      if (!_codeSent) ...[
                        const SizedBox(height: 16),
                        _buildRememberMe(),
                      ],
                      const SizedBox(height: 24),
                      _buildActionButton(state),
                      if (_codeSent) ...[
                        const SizedBox(height: 16),
                        _buildResendCode(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
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
            Icons.phone_android,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _codeSent ? 'Enter Verification Code' : 'Phone Login',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _codeSent
              ? 'We have sent a verification code to your phone'
              : 'Enter your phone number to receive a verification code',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildForm(AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1 234 567 8900',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
            enabled: !_codeSent && state is! AuthLoading,
          ),
          if (_codeSent) ...[
            const SizedBox(height: 20),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                hintText: '123456',
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
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the verification code';
                }
                if (value.length < 4) {
                  return 'Please enter a valid verification code';
                }
                return null;
              },
              enabled: state is! AuthLoading,
            ),
          ],
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
        const Text('Remember my phone number'),
      ],
    );
  }

  Widget _buildActionButton(AuthState state) {
    return ElevatedButton(
      onPressed: state is AuthLoading
          ? null
          : () {
              if (_codeSent) {
                _verifyAndLogin();
              } else {
                _requestVerificationCode();
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
      child: state is AuthLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _codeSent ? 'Verify & Login' : 'Send Verification Code',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildResendCode() {
    return TextButton(
      onPressed: () {
        setState(() {
          _codeSent = false;
          _codeController.clear();
        });
      },
      child: const Text(
        'Didn\'t receive a code? Resend',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _navigateToHome(User user) {
    if (user.isClient) {
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