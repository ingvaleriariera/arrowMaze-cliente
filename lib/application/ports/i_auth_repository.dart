import '../dtos/auth_result_dto.dart';

abstract class IAuthRepository {
  Future<AuthResultDTO> login(String email, String password);
  Future<AuthResultDTO> register(String email, String username, String password);
  Future<void> logout();
  Future<String?> getToken();
  Future<bool> isAuthenticated();
}
