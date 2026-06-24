import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations({required this.locale});

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'gameTitle': 'Arrow Maze',
      'levelSelect': 'Select Level',
      'victory': 'Victory!',
      'defeat': 'Defeat',
      'retry': 'Retry',
      'moves': 'Moves',
      'score': 'Score',
      'pause': 'Pause',
      'resume': 'Resume',
      'hint': 'Hint',
      'hammer': 'Hammer',
      'magnet': 'Magnet',
      'coins': 'Coins',
      'loading': 'Loading...',
      'error': 'Error',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'leaderboard': 'Leaderboard',
      'settings': 'Settings',
      'logout': 'Logout',
    },
    'es': {
      'gameTitle': 'Laberinto de Flechas',
      'levelSelect': 'Seleccionar Nivel',
      'victory': '¡Victoria!',
      'defeat': 'Derrota',
      'retry': 'Reintentar',
      'moves': 'Movimientos',
      'score': 'Puntuación',
      'pause': 'Pausa',
      'resume': 'Reanudar',
      'hint': 'Pista',
      'hammer': 'Martillo',
      'magnet': 'Imán',
      'coins': 'Monedas',
      'loading': 'Cargando...',
      'error': 'Error',
      'login': 'Iniciar sesión',
      'register': 'Registrarse',
      'email': 'Correo',
      'password': 'Contraseña',
      'username': 'Usuario',
      'leaderboard': 'Tabla de clasificación',
      'settings': 'Configuración',
      'logout': 'Cerrar sesión',
    },
  };

  static const supportedLocales = [
    Locale('en', ''),
    Locale('es', ''),
  ];

  String translate(String key) {
    final languageCode = locale.languageCode;
    return _localizedStrings[languageCode]?[key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(locale: const Locale('en', ''));
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale: locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
