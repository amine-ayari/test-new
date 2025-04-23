// TODO Implement this library.
import 'package:equatable/equatable.dart';

abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object> get props => [];
}

class LoadLanguage extends LanguageEvent {}

class ChangeLanguage extends LanguageEvent {
  final String languageCode;

  const ChangeLanguage(this.languageCode);

  @override
  List<Object> get props => [languageCode];
}

class ToggleUseDeviceLanguage extends LanguageEvent {
  final bool useDeviceLanguage;

  const ToggleUseDeviceLanguage(this.useDeviceLanguage);

  @override
  List<Object> get props => [useDeviceLanguage];
}
