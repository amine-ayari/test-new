import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_activity_app/bloc/language/language_event.dart';
import 'package:flutter_activity_app/bloc/language/language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final List<String> _supportedLanguages = ['en', 'fr', 'es', 'de', 'ar'];
  
  LanguageBloc() : super(LanguageInitial()) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ToggleUseDeviceLanguage>(_onToggleUseDeviceLanguage);
  }

  Future<void> _onLoadLanguage(LoadLanguage event, Emitter<LanguageState> emit) async {
    emit(LanguageLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'en';
      final useDeviceLanguage = prefs.getBool('use_device_language') ?? false;
      
      emit(LanguageLoaded(
        currentLanguage: languageCode,
        supportedLanguages: _supportedLanguages,
        useDeviceLanguage: useDeviceLanguage,
        locale: Locale(languageCode),
      ));
    } catch (e) {
      emit(LanguageError('Failed to load language settings: $e'));
    }
  }

  Future<void> _onChangeLanguage(ChangeLanguage event, Emitter<LanguageState> emit) async {
    if (state is LanguageLoaded) {
      final currentState = state as LanguageLoaded;
      
      if (_supportedLanguages.contains(event.languageCode)) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('language', event.languageCode);
          await prefs.setBool('use_device_language', false);
          
          emit(currentState.copyWith(
            currentLanguage: event.languageCode,
            useDeviceLanguage: false,
            locale: Locale(event.languageCode),
          ));
        } catch (e) {
          emit(LanguageError('Failed to change language: $e'));
        }
      }
    }
  }

  Future<void> _onToggleUseDeviceLanguage(ToggleUseDeviceLanguage event, Emitter<LanguageState> emit) async {
    if (state is LanguageLoaded) {
      final currentState = state as LanguageLoaded;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('use_device_language', event.useDeviceLanguage);
        
        // If using device language, we would typically get the device locale here
        // For simplicity, we'll just use English as a fallback
        final languageCode = event.useDeviceLanguage 
            ? WidgetsBinding.instance.window.locale.languageCode
            : currentState.currentLanguage;
        
        if (event.useDeviceLanguage) {
          await prefs.setString('language', languageCode);
        }
        
        emit(currentState.copyWith(
          useDeviceLanguage: event.useDeviceLanguage,
          currentLanguage: languageCode,
          locale: Locale(languageCode),
        ));
      } catch (e) {
        emit(LanguageError('Failed to update device language setting: $e'));
      }
    }
  }
}
