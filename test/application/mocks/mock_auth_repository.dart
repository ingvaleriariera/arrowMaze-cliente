import 'package:arrow_maze_cliente_copy/application/dtos/auth_result_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';

class MockAuthRepository implements IAuthRepository {
  String? _token;
  String? _userId;
  bool _isLoggedIn = false;

  final Map<String, String> _users = {
    'test@example.com': 'password123',
  };

  @override
  Future<AuthResultDTO> login(String email, String password) async {
    if (_users[email] == password) {
      _token = 'mock_token_${email}_${DateTime.now().millisecondsSinceEpoch}';
      _userId = 'user_${email.hashCode}';
      _isLoggedIn = true;
      return AuthResultDTO(token: _token!, userId: _userId!);
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<AuthResultDTO> register(String email, String username, String password) async {
    if (_users.containsKey(email)) {
      throw Exception('Email already registered');
    }
    _users[email] = password;
    _token = 'mock_token_${email}_${DateTime.now().millisecondsSinceEpoch}';
    _userId = 'user_${email.hashCode}';
    _isLoggedIn = true;
    return AuthResultDTO(token: _token!, userId: _userId!);
  }

  @override
  Future<void> logout() async {
    _token = null;
    _userId = null;
    _isLoggedIn = false;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<bool> isAuthenticated() async => _isLoggedIn;
}
