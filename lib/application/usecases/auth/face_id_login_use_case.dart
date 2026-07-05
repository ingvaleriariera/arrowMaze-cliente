import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/services/biometric_service.dart';
import 'package:arrow_maze_cliente_copy/domain/exceptions/app_exceptions.dart';
import 'package:flutter/foundation.dart';

class FaceIdLoginUseCase {
  final IAuthRepository authRepository;
  final BiometricService biometricService;

  FaceIdLoginUseCase({
    required this.authRepository,
    required this.biometricService,
  });

  Future<bool> canUseFaceId() async {
    debugPrint('🔐 FaceIdLoginUseCase.canUseFaceId: Verificando si se puede usar Face ID');
    final hasSavedCredentials = await authRepository.hasSavedBiometricCredentials();
    final isFaceIdAvailable = await biometricService.isFaceIDAvailable();
    final result = hasSavedCredentials && isFaceIdAvailable;
    debugPrint('🔐 FaceIdLoginUseCase.canUseFaceId: hasSavedCredentials=$hasSavedCredentials, isFaceIdAvailable=$isFaceIdAvailable, result=$result');
    return result;
  }

  Future<dynamic> execute() async {
    try {
      debugPrint('🔐 FaceIdLoginUseCase: Starting Face ID login');

      final canUse = await canUseFaceId();
      if (!canUse) {
        throw UnauthorizedException('Face ID not available');
      }

      final authenticated = await biometricService.authenticate();
      if (!authenticated) {
        debugPrint('❌ FaceIdLoginUseCase: Face ID authentication failed');
        throw UnauthorizedException('Face ID authentication failed');
      }

      final credentials = await authRepository.getBiometricCredentials();
      if (credentials == null) {
        throw UnauthorizedException('No saved credentials found');
      }

      final (email, password) = credentials;
      debugPrint('🔓 FaceIdLoginUseCase: Face ID authenticated, using saved credentials');

      final result = await authRepository.login(email, password);
      return result;
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('❌ FaceIdLoginUseCase: Error - $e');
      throw Exception('Face ID login failed: $e');
    }
  }
}
