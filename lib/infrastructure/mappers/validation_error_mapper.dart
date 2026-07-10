import 'package:arrow_maze_cliente_copy/domain/entities/validation_error_type.dart';

class ValidationErrorMapper {
  static String toTranslationKey(ValidationErrorType errorType) {
    return switch (errorType) {
      ValidationErrorType.emailRequired => 'emailRequired',
      ValidationErrorType.emailMustHaveAt => 'emailMustHaveAt',
      ValidationErrorType.emailTooShort => 'emailTooShort',
      ValidationErrorType.emailInvalidChars => 'emailInvalidChars',
      ValidationErrorType.emailInvalidFormat => 'emailInvalidFormat',
      ValidationErrorType.usernameRequired => 'usernameRequired',
      ValidationErrorType.usernameTooShort => 'usernameTooShort',
      ValidationErrorType.usernameInvalidChars => 'usernameInvalidChars',
      ValidationErrorType.usernameInvalidFormat => 'usernameInvalidFormat',
      ValidationErrorType.invalidEmailOrUsername => 'invalidEmailOrUsername',
    };
  }
}
