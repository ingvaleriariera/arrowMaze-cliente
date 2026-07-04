import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_cliente_copy/domain/validators/auth_validator.dart';

void main() {
  group('AuthValidator', () {
    group('validateEmail', () {
      test('accepts valid emails', () {
        final result = AuthValidator.validateEmail('user@example.com');
        expect(result.isValid, true);
      });

      test('rejects email with less than 3 characters before @', () {
        final result = AuthValidator.validateEmail('a@example.com');
        expect(result.isValid, false);
        expect(result.message, contains('más de 3 caracteres'));
      });

      test('rejects email with no @', () {
        final result = AuthValidator.validateEmail('userexample.com');
        expect(result.isValid, false);
      });

      test('rejects email with multiple @', () {
        final result = AuthValidator.validateEmail('user@@example.com');
        expect(result.isValid, false);
      });

      test('rejects email with invalid special characters', () {
        final result = AuthValidator.validateEmail('user!@example.com');
        expect(result.isValid, false);
      });

      test('accepts email with . and _ in local part', () {
        final result = AuthValidator.validateEmail('user.name_123@example.com');
        expect(result.isValid, true);
      });
    });

    group('validateUsername', () {
      test('accepts valid usernames', () {
        final result = AuthValidator.validateUsername('user123');
        expect(result.isValid, true);
      });

      test('rejects username with less than 3 characters', () {
        final result = AuthValidator.validateUsername('ab');
        expect(result.isValid, false);
      });

      test('rejects username with invalid special characters', () {
        final result = AuthValidator.validateUsername('user!name');
        expect(result.isValid, false);
      });

      test('accepts username with . and _', () {
        final result = AuthValidator.validateUsername('user_name.123');
        expect(result.isValid, true);
      });
    });

    group('validatePassword', () {
      test('requires minimum 8 characters', () {
        final result = AuthValidator.validatePassword('Pass@123');
        expect(result.hasMinLength, true);
      });

      test('requires at least one uppercase letter', () {
        final result = AuthValidator.validatePassword('Pass@1234');
        expect(result.hasUpperCase, true);
      });

      test('fails without uppercase letter', () {
        final result = AuthValidator.validatePassword('pass@1234');
        expect(result.hasUpperCase, false);
      });

      test('requires at least one special character', () {
        final result = AuthValidator.validatePassword('Pass@1234');
        expect(result.hasSpecialChar, true);
      });

      test('rejects passwords with ? or !', () {
        final result1 = AuthValidator.validatePassword('Pass?1234');
        expect(result1.hasSpecialChar, false);

        final result2 = AuthValidator.validatePassword('Pass!1234');
        expect(result2.hasSpecialChar, false);
      });

      test('isPasswordValid returns true only when all requirements met', () {
        final result = AuthValidator.validatePassword('Pass@1234');
        expect(AuthValidator.isPasswordValid(result), true);

        final result2 = AuthValidator.validatePassword('Pass1234');
        expect(AuthValidator.isPasswordValid(result2), false);
      });
    });

    group('validateEmailOrUsername', () {
      test('accepts valid email', () {
        final result = AuthValidator.validateEmailOrUsername('user@example.com');
        expect(result.isValid, true);
      });

      test('accepts valid username', () {
        final result = AuthValidator.validateEmailOrUsername('username');
        expect(result.isValid, true);
      });

      test('rejects invalid input', () {
        final result = AuthValidator.validateEmailOrUsername('ab');
        expect(result.isValid, false);
      });
    });
  });
}
