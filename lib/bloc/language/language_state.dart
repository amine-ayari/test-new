import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class LanguageState extends Equatable {
  const LanguageState();
  
  @override
  List<Object> get props => [];
}

class LanguageInitial extends LanguageState {}

class LanguageLoading extends LanguageState {}

class LanguageLoaded extends LanguageState {
  final String currentLanguage;
  final List<String> supportedLanguages;
  final bool useDeviceLanguage;
  final Locale locale;

  const LanguageLoaded({
    required this.currentLanguage,
    required this.supportedLanguages,
    required this.useDeviceLanguage,
    required this.locale,
  });

  @override
  List<Object> get props => [currentLanguage, supportedLanguages, useDeviceLanguage, locale];

  LanguageLoaded copyWith({
    String? currentLanguage,
    List<String>? supportedLanguages,
    bool? useDeviceLanguage,
    Locale? locale,
  }) {
    return LanguageLoaded(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      useDeviceLanguage: useDeviceLanguage ?? this.useDeviceLanguage,
      locale: locale ?? this.locale,
    );
  }
}

class LanguageError extends LanguageState {
  final String message;

  const LanguageError(this.message);

  @override
  List<Object> get props => [message];
}
// TODO Implement this library.
