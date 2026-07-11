import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/services/biometric_service.dart';
import 'package:arrow_maze_cliente_copy/domain/exceptions/app_exceptions.dart';
import 'package:flutter/foundation.dart';

class FaceIdLoginWithEmailUseCase {
  final IAuthRepository authRepository;
  final BiometricService biometricService;

  FaceIdLoginWithEmailUseCase({
    required this.authRepository,
    required this.biometricService,
  });

  Future<bool> canUseFaceIdForEmail(String email) async {
    final hasSavedCredentials = await authRepository.hasSavedCredentialsForEmail(email);
    final isFaceIdAvailable = await biometricService.isFaceIDAvailable();
    return hasSavedCredentials && isFaceIdAvailable;
  }

  /// The identifier saved alongside the biometric credentials on this
  /// device (or null when nothing is saved) — lets the login screen
  /// pre-fill the field so a returning Face ID user doesn't retype it.
  /// Reading it does NOT trigger a biometric prompt; only execute() does.
  Future<String?> getSavedEmail() async {
    try {
      final credentials = await authRepository.getBiometricCredentials();
      return credentials?.$1;
    } catch (e) {
      debugPrint('⚠️  FaceIdLoginWithEmailUseCase.getSavedEmail: $e');
      return null;
    }
  }

  Future<dynamic> execute(String email) async {
    try {
      debugPrint('🔐 FaceIdLoginWithEmailUseCase: Starting Face ID login for $email');

      final canUse = await canUseFaceIdForEmail(email);
      if (!canUse) {
        throw UnauthorizedException('Face ID not available for this email');
      }

      final authenticated = await biometricService.authenticate();
      if (!authenticated) {
        debugPrint('❌ FaceIdLoginWithEmailUseCase: Face ID authentication failed');
        throw UnauthorizedException('Face ID authentication failed');
      }

      final credentials = await authRepository.getBiometricCredentials();
      if (credentials == null) {
        throw UnauthorizedException('No saved credentials found');
      }

      final (savedEmail, password) = credentials;

      // Verify that the saved email matches the provided email
      if (savedEmail != email) {
        throw UnauthorizedException('Face ID credentials do not match this email');
      }

      debugPrint('🔓 FaceIdLoginWithEmailUseCase: Face ID authenticated for $email');

      final result = await authRepository.login(email, password);
      return result;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('❌ FaceIdLoginWithEmailUseCase: Error - $e');
      throw Exception('Face ID login failed: $e');
    }
  }
}
