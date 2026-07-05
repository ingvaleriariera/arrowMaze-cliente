import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('❌ BiometricService.isBiometricAvailable: Error - $e');
      return false;
    }
  }

  Future<bool> isFaceIDAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      debugPrint('🔍 BiometricService: canCheckBiometrics = $canCheck');

      if (!canCheck) {
        debugPrint('❌ BiometricService: No puede verificar biometría');
        return false;
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('🔍 BiometricService: Biometrics disponibles = $biometrics');

      final hasFaceID = biometrics.contains(BiometricType.face);
      debugPrint('🔍 BiometricService: Face ID disponible = $hasFaceID');

      return hasFaceID;
    } catch (e) {
      debugPrint('❌ BiometricService.isFaceIDAvailable: Error - $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      debugPrint('🔐 BiometricService.authenticate: Starting Face ID authentication');

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Autentica con Face ID para acceder a tu cuenta',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isAuthenticated) {
        debugPrint('✅ BiometricService.authenticate: Face ID authentication successful');
      } else {
        debugPrint('❌ BiometricService.authenticate: Face ID authentication cancelled');
      }

      return isAuthenticated;
    } catch (e) {
      debugPrint('❌ BiometricService.authenticate: Authentication error - $e');
      return false;
    }
  }
}
