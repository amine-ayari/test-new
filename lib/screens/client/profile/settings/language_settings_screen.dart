import 'package:flutter/material.dart';
import 'package:flutter_activity_app/config/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_activity_app/bloc/language/language_bloc.dart';
import 'package:flutter_activity_app/bloc/language/language_event.dart';
import 'package:flutter_activity_app/bloc/language/language_state.dart';

import 'package:flutter_activity_app/widgets/loading_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LanguageBloc()..add(LoadLanguage()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Language Settings'),
          elevation: 0,
        ),
        body: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, state) {
            if (state is LanguageLoading) {
              return const Center(child: LoadingIndicator());
            } else if (state is LanguageLoaded) {
              return _buildContent(context, state);
            } else if (state is LanguageError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('Loading language settings...'));
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LanguageLoaded state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Language',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isDarkMode
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[850]!,
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey[50]!,
                        ],
                      ),
              ),
              child: Column(
                children: [
                  _buildLanguageOption(
                    context,
                    'en',
                    'English',
                    'English',
                    'assets/flags/us.png',
                    isDarkMode,
                    state.currentLanguage,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildLanguageOption(
                    context,
                    'fr',
                    'French',
                    'Français',
                    'assets/flags/fr.png',
                    isDarkMode,
                    state.currentLanguage,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildLanguageOption(
                    context,
                    'es',
                    'Spanish',
                    'Español',
                    'assets/flags/es.png',
                    isDarkMode,
                    state.currentLanguage,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildLanguageOption(
                    context,
                    'de',
                    'German',
                    'Deutsch',
                    'assets/flags/de.png',
                    isDarkMode,
                    state.currentLanguage,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildLanguageOption(
                    context,
                    'ar',
                    'Arabic',
                    'العربية',
                    'assets/flags/ar.png',
                    isDarkMode,
                    state.currentLanguage,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            'Language Preferences',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Use Device Language'),
                    subtitle: const Text('Automatically use your device language settings'),
                    value: state.useDeviceLanguage,
                    onChanged: (value) {
                      context.read<LanguageBloc>().add(ToggleUseDeviceLanguage(value));
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('App Translation'),
                    subtitle: const Text('Help us translate the app to your language'),
                    trailing: const Icon(Icons.translate),
                    onTap: () {
                      // Navigate to translation contribution page
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageCode,
    String englishName,
    String nativeName,
    String flagAsset,
    bool isDarkMode,
    String currentLanguage,
  ) {
    final isSelected = currentLanguage == languageCode;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
          image: DecorationImage(
            image: AssetImage(flagAsset),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        englishName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(nativeName),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: AppTheme.primaryColor,
            )
          : null,
      onTap: () {
        context.read<LanguageBloc>().add(ChangeLanguage(languageCode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to $englishName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
