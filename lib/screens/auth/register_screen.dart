import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/auth/auth_state.dart';
import 'package:flutter_activity_app/di/service_locator.dart';
import 'package:flutter_activity_app/models/auth_credentials.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/screens/client/client_main_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _providerNameController = TextEditingController();
  final _providerDescriptionController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.client;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _providerNameController.dispose();
    _providerDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Register'),
          elevation: 0,
        ),
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is Authenticated) {
              _navigateToHome(state.user);
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRoleSelector(),
                    const SizedBox(height: 24),
                    _buildRegisterForm(state),
                    const SizedBox(height: 24),
                    _buildRegisterButton(state),
                    const SizedBox(height: 16),
                    _buildLoginLink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I want to register as:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                title: 'Client',
                icon: Icons.person,
                role: UserRole.client,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoleOption(
                title: 'Provider',
                icon: Icons.business,
                role: UserRole.provider,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String title,
    required IconData icon,
    required UserRole role,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
            enabled: state is! AuthLoading,
          ),
          const SizedBox(height: 16),
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
            enabled: state is! AuthLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number (Optional)',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            enabled: state is! AuthLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
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
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            enabled: state is! AuthLoading,
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
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            enabled: state is! AuthLoading,
          ),
          if (_selectedRole == UserRole.provider) ...[
            const SizedBox(height: 24),
            const Text(
              'Provider Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _providerNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_selectedRole == UserRole.provider && (value == null || value.isEmpty)) {
                  return 'Please enter your business name';
                }
                return null;
              },
              enabled: state is! AuthLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _providerDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Business Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (_selectedRole == UserRole.provider && (value == null || value.isEmpty)) {
                  return 'Please enter your business description';
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

  Widget _buildRegisterButton(AuthState state) {
    return ElevatedButton(
      onPressed: state is AuthLoading
          ? null
          : () {
              if (_formKey.currentState?.validate() ?? false) {
                final providerId = _selectedRole == UserRole.provider
                    ? DateTime.now().millisecondsSinceEpoch.toString()
                    : null;
                
                _authBloc.add(
                  RegisterRequested(
                    RegisterRequest(
                      name: _nameController.text,
                      email: _emailController.text,
                      password: _passwordController.text,
                      phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
                      role: _selectedRole,
                      providerId: providerId,
                      providerName: _selectedRole == UserRole.provider ? _providerNameController.text : null,
                      providerDescription: _selectedRole == UserRole.provider ? _providerDescriptionController.text : null,
                    ),
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: state is AuthLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Register',
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account?'),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Login'),
        ),
      ],
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
