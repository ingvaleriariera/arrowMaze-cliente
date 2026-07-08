import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/auth_result_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';

  AuthRepositoryImpl({
    required this.apiClient,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<AuthResultDTO> login(String email, String password) async {
    debugPrint('🔐 AuthRepository.login: Iniciando login para $email');
    final json = await apiClient.post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });

    final token = json['token'] as String;
    final userId = json['userId'] as String;
    final username = json['username'] as String;

    debugPrint('🔐 AuthRepository.login: Guardando token y userId');
    await secureStorage.write(key: _tokenKey, value: token);
    await secureStorage.write(key: _userIdKey, value: userId);

    debugPrint('🔐 AuthRepository.login: Guardando credenciales biométricas');
    try {
      await saveBiometricCredentials(email, password);
      debugPrint('✅ AuthRepository.login: Login completado exitosamente');
    } catch (e) {
      debugPrint('⚠️  AuthRepository.login: Error guardando credenciales biométricas - $e');
    }

    apiClient.setToken(token);

    return AuthResultDTO(token: token, userId: userId, username: username);
  }

  @override
  Future<AuthResultDTO> register(String email, String username, String password) async {
    debugPrint('📝 AuthRepository.register: Iniciando registro para $email');
    final json = await apiClient.post('/api/v1/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    });

    final token = json['token'] as String;
    final userId = json['userId'] as String;
    final responseUsername = json['username'] as String;

    debugPrint('📝 AuthRepository.register: Guardando token y userId');
    await secureStorage.write(key: _tokenKey, value: token);
    await secureStorage.write(key: _userIdKey, value: userId);

    debugPrint('📝 AuthRepository.register: Guardando credenciales biométricas');
    try {
      await saveBiometricCredentials(email, password);
      debugPrint('✅ AuthRepository.register: Registro completado exitosamente');
    } catch (e) {
      debugPrint('⚠️  AuthRepository.register: Error guardando credenciales biométricas - $e');
    }

    apiClient.setToken(token);

    return AuthResultDTO(token: token, userId: userId, username: responseUsername);
  }

  @override
  Future<void> logout() async {
    debugPrint('🔓 AuthRepository.logout: Cerrando sesión');
    apiClient.clearToken();
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: _userIdKey);
    // Keep biometric credentials saved for Face ID login on next session
    debugPrint('✅ AuthRepository.logout: Sesión cerrada (credenciales biométricas conservadas para Face ID)');
  }

  Future<void> saveBiometricCredentials(String email, String password) async {
    try {
      debugPrint('💾 AuthRepository: Guardando credenciales biométricas para $email');
      await secureStorage.write(key: _emailKey, value: email);
      await secureStorage.write(key: _passwordKey, value: password);
      debugPrint('✅ AuthRepository: Credenciales biométricas guardadas exitosamente');
    } catch (e) {
      debugPrint('❌ AuthRepository: Error guardando credenciales - $e');
      throw Exception('Failed to save biometric credentials: $e');
    }
  }

  Future<(String email, String password)?> getBiometricCredentials() async {
    try {
      final email = await secureStorage.read(key: _emailKey);
      final password = await secureStorage.read(key: _passwordKey);

      debugPrint('🔍 AuthRepository.getBiometricCredentials: email=$email, password=${password != null ? '***' : 'null'}');

      if (email != null && password != null) {
        debugPrint('✅ AuthRepository: Credenciales encontradas');
        return (email, password);
      }
      debugPrint('❌ AuthRepository: No hay credenciales guardadas');
      return null;
    } catch (e) {
      debugPrint('❌ AuthRepository.getBiometricCredentials: Error - $e');
      throw Exception('Failed to retrieve biometric credentials: $e');
    }
  }

  Future<bool> hasSavedBiometricCredentials() async {
    try {
      final email = await secureStorage.read(key: _emailKey);
      final password = await secureStorage.read(key: _passwordKey);
      final hasSaved = email != null && password != null;
      debugPrint('🔐 AuthRepository.hasSavedBiometricCredentials: $hasSaved (email=${email != null}, password=${password != null})');
      return hasSaved;
    } catch (e) {
      debugPrint('❌ AuthRepository.hasSavedBiometricCredentials: Error - $e');
      return false;
    }
  }

  Future<bool> hasSavedCredentialsForEmail(String email) async {
    try {
      final savedEmail = await secureStorage.read(key: _emailKey);
      final password = await secureStorage.read(key: _passwordKey);
      final hasCredentials = savedEmail != null && password != null && savedEmail == email;
      debugPrint('🔐 AuthRepository.hasSavedCredentialsForEmail($email): $hasCredentials');
      return hasCredentials;
    } catch (e) {
      debugPrint('❌ AuthRepository.hasSavedCredentialsForEmail: Error - $e');
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    return secureStorage.read(key: _tokenKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}
