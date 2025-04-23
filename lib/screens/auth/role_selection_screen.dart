import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_activity_app/bloc/auth/auth_event.dart';
import 'package:flutter_activity_app/bloc/auth/auth_state.dart';
import 'package:flutter_activity_app/models/user.dart';
import 'package:flutter_activity_app/screens/client/client_main_screen.dart';
import 'package:flutter_activity_app/screens/provider/provider_main_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final User user;

  const RoleSelectionScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate based on the updated role
          if (state.user.isClient) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ClientMainScreen(user: state.user),
              ),
            );
          } else if (state.user.isProvider) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderMainScreen(user: state.user),
              ),
            );
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(context),
                    const SizedBox(height: 60),
                    _buildRoleOptions(context, isLoading),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose Your Role',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Select how you want to use the app',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleOptions(BuildContext context, bool isLoading) {
    return Column(
      children: [
        _buildRoleCard(
          context,
          title: 'Join as a Client',
          description: 'Discover and book exciting activities',
          icon: Icons.explore,
          color: Colors.blue,
          onTap: isLoading ? null : () => _selectRole(context, UserRole.client),
          isLoading: isLoading && user.role == UserRole.client,
        ),
        const SizedBox(height: 20),
        _buildRoleCard(
          context,
          title: 'Join as a Provider',
          description: 'Create and manage your own activities',
          icon: Icons.business_center,
          color: Colors.green,
          onTap: isLoading ? null : () => _selectRole(context, UserRole.provider),
          isLoading: isLoading && user.role == UserRole.provider,
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, UserRole role) {
    context.read<AuthBloc>().add(UpdateUserRole(role));
  }
}
