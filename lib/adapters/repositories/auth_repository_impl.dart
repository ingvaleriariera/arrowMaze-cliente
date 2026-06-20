import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../application/dtos/auth_result_dto.dart';
import '../../application/ports/i_auth_repository.dart';
import '../api/api_client.dart';

class AuthRepositoryImpl implements IAuthRepository {
  static const String _tokenKey = 'auth_token';

  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl(this.apiClient, this.secureStorage);

  @override
  Future<AuthResultDTO> login(String email, String password) async {
    final response = await apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
    final result = AuthResultDTO(response['token'] as String, response['userId'] as String);
    await _persistToken(result.token);
    return result;
  }

  @override
  Future<AuthResultDTO> register(String email, String username, String password) async {
    final response = await apiClient.post('/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    });
    final result = AuthResultDTO(response['token'] as String, response['userId'] as String);
    await _persistToken(result.token);
    return result;
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: _tokenKey);
    apiClient.clearToken();
  }

  @override
  Future<String?> getToken() => secureStorage.read(key: _tokenKey);

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> _persistToken(String token) async {
    await secureStorage.write(key: _tokenKey, value: token);
    apiClient.setToken(token);
  }
}
