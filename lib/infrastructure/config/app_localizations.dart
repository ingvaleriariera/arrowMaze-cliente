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
      'gameOver': 'Game Over',
      'retry': 'Retry',
      'backToLevels': 'Back to Levels',
      'backToMenu': 'Back to Menu',
      'backToLogin': 'Back to Login',
      'moves': 'Moves',
      'score': 'Score',
      'pause': 'Pause',
      'resume': 'Resume',
      'hint': 'Hint',
      'tapArrowToDestroy': 'Tap an arrow to destroy it',
      'cancel': 'Cancel',
      'hammer': 'Hammer',
      'magnet': 'Magnet',
      'coins': 'Coins',
      'loading': 'Loading...',
      'loadingLevels': 'Loading levels...',
      'noLevelsAvailable': 'No levels available',
      'noLeaderboardData': 'No leaderboard data',
      'error': 'Error',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'leaderboard': 'Leaderboard',
      'settings': 'Settings',
      'language': 'Language',
      'languageSubtitle': 'English / Español',
      'logout': 'Logout',
      'level': 'Level',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'paused': 'Paused',
      'restart': 'Restart',
      'sound': 'Sound',
      'music': 'Music',
      'vibration': 'Vibration',
      'preloadAllTitle': 'Download all levels?',
      'preloadAllMessage':
          'You can download every level\'s board now so they open instantly later, or keep downloading them one by one as you play.',
      'notNow': 'Not now',
      'downloadAll': 'Download all',
      'downloadingLevels': 'Downloading levels...',
      'home': 'Home',
      'play': 'Play',
      'profile': 'Profile',
      'globalLeaderboard': 'Global',
      'perLevel': 'By Level',
      'selectAvatar': 'Choose your avatar',
      'levelsCompleted': 'Levels',
      'totalScore': 'Total Score',
      'biometricIdentification': 'Biometric Identification',
      'notEnoughCoins': 'Not enough coins',
      'hintName': 'Hint',
      'hintDescription': 'Highlights an arrow that can exit right now.',
      'gridName': 'Grid',
      'gridDescription': 'Shows where each arrow on the board exits to.',
      'hammerName': 'Hammer',
      'hammerDescription': 'Tap any arrow on the board to destroy it, even if blocked.',
      'magnetName': 'Magnet',
      'magnetDescription': 'Removes up to 5 arrows that can already exit the board.',
      'emailRequired': 'Email is required',
      'emailMustHaveAt': 'Email must contain exactly one @',
      'emailTooShort': 'Email must have more than 3 characters before @',
      'emailInvalidChars': 'Email contains invalid characters (only . and _ are allowed)',
      'emailInvalidFormat': 'Invalid email format',
      'usernameRequired': 'Username is required',
      'usernameTooShort': 'Username must have at least 3 characters',
      'usernameInvalidChars': 'Username contains invalid characters (only . and _ are allowed)',
      'usernameInvalidFormat': 'Username can only contain letters, numbers, . and _',
      'invalidEmailOrUsername': 'Enter a valid email or username',
      'passwordMinLength': '8 characters minimum',
      'passwordNeedsUpperCase': '1 uppercase letter',
      'passwordNeedsSpecialChar': '1 special character',
      'passwordRequirements': 'Password Requirements',
      'passwordRequiresMinLength': 'At least 8 characters',
      'passwordRequiresUpperCase': 'At least 1 uppercase letter',
      'passwordRequiresSpecialChar': 'At least 1 special character (@#\$%^&*)',
    },
    'es': {
      'gameTitle': 'Laberinto de Flechas',
      'levelSelect': 'Seleccionar Nivel',
      'victory': '¡Victoria!',
      'defeat': 'Derrota',
      'gameOver': 'Fin del Juego',
      'retry': 'Reintentar',
      'backToLevels': 'Volver a Niveles',
      'backToMenu': 'Ir al inicio',
      'backToLogin': 'Volver a login',
      'moves': 'Movimientos',
      'score': 'Puntuación',
      'pause': 'Pausa',
      'resume': 'Reanudar',
      'hint': 'Pista',
      'tapArrowToDestroy': 'Toca una flecha para destruirla',
      'cancel': 'Cancelar',
      'hammer': 'Martillo',
      'magnet': 'Imán',
      'coins': 'Monedas',
      'loading': 'Cargando...',
      'loadingLevels': 'Cargando niveles...',
      'noLevelsAvailable': 'No hay niveles disponibles',
      'noLeaderboardData': 'No hay datos de tabla de clasificación',
      'error': 'Error',
      'login': 'Iniciar sesión',
      'register': 'Registrarse',
      'email': 'Correo',
      'password': 'Contraseña',
      'username': 'Usuario',
      'leaderboard': 'Tabla de clasificación',
      'settings': 'Configuración',
      'language': 'Idioma',
      'languageSubtitle': 'English / Español',
      'logout': 'Cerrar sesión',
      'level': 'Nivel',
      'easy': 'Fácil',
      'medium': 'Medio',
      'hard': 'Difícil',
      'paused': 'Pausa',
      'restart': 'Reiniciar',
      'sound': 'Sonido',
      'music': 'Música',
      'vibration': 'Vibración',
      'preloadAllTitle': '¿Descargar todos los niveles?',
      'preloadAllMessage':
          'Podés descargar el tablero de todos los niveles ahora para que abran al instante después, o seguir descargándolos de a uno mientras jugás.',
      'notNow': 'Ahora no',
      'downloadAll': 'Descargar todos',
      'downloadingLevels': 'Descargando niveles...',
      'home': 'Inicio',
      'play': 'Jugar',
      'profile': 'Perfil',
      'globalLeaderboard': 'Global',
      'perLevel': 'Por nivel',
      'selectAvatar': 'Elige tu avatar',
      'levelsCompleted': 'Niveles',
      'totalScore': 'Puntaje total',
      'biometricIdentification': 'Identificación biométrica',
      'notEnoughCoins': 'No tienes suficientes monedas',
      'hintName': 'Pista',
      'hintDescription': 'Resalta una flecha que puede salir ahora mismo.',
      'gridName': 'Cuadrícula',
      'gridDescription': 'Muestra hacia dónde sale cada flecha del tablero.',
      'hammerName': 'Martillo',
      'hammerDescription': 'Toca cualquier flecha del tablero para destruirla, incluso si está bloqueada.',
      'magnetName': 'Imán',
      'magnetDescription': 'Elimina hasta 5 flechas que ya pueden salir del tablero.',
      'emailRequired': 'El correo es requerido',
      'emailMustHaveAt': 'El correo debe contener exactamente un @',
      'emailTooShort': 'El correo debe tener más de 3 caracteres antes del @',
      'emailInvalidChars': 'El correo contiene caracteres no permitidos (solo . y _ están permitidos)',
      'emailInvalidFormat': 'Formato de correo inválido',
      'usernameRequired': 'El usuario es requerido',
      'usernameTooShort': 'El usuario debe tener al menos 3 caracteres',
      'usernameInvalidChars': 'El usuario contiene caracteres no permitidos (solo . y _ están permitidos)',
      'usernameInvalidFormat': 'El usuario solo puede contener letras, números, . y _',
      'invalidEmailOrUsername': 'Ingresa un correo o usuario válido',
      'passwordMinLength': '8 caracteres mínimo',
      'passwordNeedsUpperCase': '1 mayúscula',
      'passwordNeedsSpecialChar': '1 carácter especial',
      'passwordRequirements': 'Requisitos de contraseña',
      'passwordRequiresMinLength': 'Al menos 8 caracteres',
      'passwordRequiresUpperCase': 'Al menos 1 mayúscula',
      'passwordRequiresSpecialChar': 'Al menos 1 carácter especial (@#\$%^&*)',
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
