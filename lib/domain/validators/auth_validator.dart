class AuthValidator {
  static const String _emailRegex =
      r'^[a-zA-Z0-9._]{3,}@[a-zA-Z0-9._]+\.[a-zA-Z]{2,}$';
  static const String _usernameRegex = r'^[a-zA-Z0-9._]{3,}$';

  /// Validates email format
  /// - Must have more than 3 characters before @
  /// - Must have exactly one @
  /// - Only allows . and _ as special characters
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'El correo es requerido',
      );
    }

    final atCount = '@'.allMatches(email).length;
    if (atCount != 1) {
      return ValidationResult(
        isValid: false,
        message: 'El correo debe contener exactamente un @',
      );
    }

    final parts = email.split('@');
    if (parts[0].length <= 3) {
      return ValidationResult(
        isValid: false,
        message: 'El correo debe tener más de 3 caracteres antes del @',
      );
    }

    // Check for invalid special characters (only . and _ are allowed)
    final invalidChars = RegExp(r'[!¡#*",;=+\s\-]');
    if (invalidChars.hasMatch(email)) {
      return ValidationResult(
        isValid: false,
        message:
            'El correo contiene caracteres no permitidos (solo . y _ están permitidos)',
      );
    }

    if (!RegExp(_emailRegex).hasMatch(email)) {
      return ValidationResult(
        isValid: false,
        message: 'Formato de correo inválido',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates username format
  /// - Must have at least 3 characters
  /// - Only allows . and _ as special characters
  static ValidationResult validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'El usuario es requerido',
      );
    }

    if (username.length < 3) {
      return ValidationResult(
        isValid: false,
        message: 'El usuario debe tener al menos 3 caracteres',
      );
    }

    // Check for invalid special characters (only . and _ are allowed)
    final invalidChars = RegExp(r'[!¡#*",;=+\s\-]');
    if (invalidChars.hasMatch(username)) {
      return ValidationResult(
        isValid: false,
        message:
            'El usuario contiene caracteres no permitidos (solo . y _ están permitidos)',
      );
    }

    if (!RegExp(_usernameRegex).hasMatch(username)) {
      return ValidationResult(
        isValid: false,
        message: 'El usuario solo puede contener letras, números, . y _',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validates if input is either a valid email or username
  static ValidationResult validateEmailOrUsername(String input) {
    final emailResult = validateEmail(input);
    if (emailResult.isValid) {
      return emailResult;
    }

    final usernameResult = validateUsername(input);
    if (usernameResult.isValid) {
      return usernameResult;
    }

    return ValidationResult(
      isValid: false,
      message: 'Ingresa un correo o usuario válido',
    );
  }

  /// Validates password and returns detailed requirements status
  static PasswordValidationResult validatePassword(String password) {
    final result = PasswordValidationResult();

    result.hasMinLength = password.length >= 8;
    result.hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    result.hasSpecialChar = _hasValidSpecialChar(password);

    return result;
  }

  /// Helper to check if password contains valid special characters
  /// Excludes ? and ! as per requirements
  static bool _hasValidSpecialChar(String password) {
    final specialCharRegex = RegExp(
      r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>~/`"]',
    );
    final hasSpecialChar = specialCharRegex.hasMatch(password);

    // Make sure it doesn't have ? or !
    final hasInvalidSpecial = password.contains('?') || password.contains('!');

    return hasSpecialChar && !hasInvalidSpecial;
  }

  /// Checks if password is fully valid
  static bool isPasswordValid(PasswordValidationResult result) {
    return result.hasMinLength &&
        result.hasUpperCase &&
        result.hasSpecialChar;
  }
}

class ValidationResult {
  final bool isValid;
  final String? message;

  ValidationResult({
    required this.isValid,
    this.message,
  });
}

class PasswordValidationResult {
  bool hasMinLength = false;
  bool hasUpperCase = false;
  bool hasSpecialChar = false;

  bool get isValid => hasMinLength && hasUpperCase && hasSpecialChar;

  String getErrorMessage() {
    final missing = <String>[];

    if (!hasMinLength) missing.add('8 caracteres mínimo');
    if (!hasUpperCase) missing.add('1 mayúscula');
    if (!hasSpecialChar) missing.add('1 carácter especial');

    return missing.join(', ');
  }
}
