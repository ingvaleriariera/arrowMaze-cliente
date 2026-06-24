import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/auth_result_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  AuthRepositoryImpl({
    required this.apiClient,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<AuthResultDTO> login(String email, String password) async {
    final json = await apiClient.post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });

    final token = json['token'] as String;
    final userId = json['userId'] as String;

    await secureStorage.write(key: _tokenKey, value: token);
    await secureStorage.write(key: _userIdKey, value: userId);
    apiClient.setToken(token);

    return AuthResultDTO(token: token, userId: userId);
  }

  @override
  Future<AuthResultDTO> register(String email, String username, String password) async {
    final json = await apiClient.post('/api/v1/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    });

    final token = json['token'] as String;
    final userId = json['userId'] as String;

    await secureStorage.write(key: _tokenKey, value: token);
    await secureStorage.write(key: _userIdKey, value: userId);
    apiClient.setToken(token);

    return AuthResultDTO(token: token, userId: userId);
  }

  @override
  Future<void> logout() async {
    apiClient.clearToken();
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: _userIdKey);
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
