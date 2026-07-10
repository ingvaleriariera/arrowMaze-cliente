import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(Locale initialLocale) : super(initialLocale);

  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLanguage() {
    final newLocale = state.languageCode == 'es'
        ? const Locale('en', '')
        : const Locale('es', '');
    setLocale(newLocale);
  }
}
