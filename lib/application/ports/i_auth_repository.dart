import 'package:arrow_maze_cliente_copy/application/dtos/auth_result_dto.dart';
import 'package:arrow_maze_cliente_copy/domain/exceptions/app_exceptions.dart';

abstract class IAuthRepository {
  /// Autentica un usuario con sus credenciales.
  ///
  /// Throws:
  /// - [UnauthorizedException] si las credenciales son inválidas
  /// - [BadRequestException] si los parámetros son inválidos
  /// - [NetworkException] si hay problemas de conexión
  /// - [ServerException] si hay un error del servidor
  Future<AuthResultDTO> login(String email, String password);

  /// Registra un nuevo usuario.
  ///
  /// Throws:
  /// - [UnauthorizedException] si el email o usuario ya existe
  /// - [BadRequestException] si los parámetros son inválidos
  /// - [NetworkException] si hay problemas de conexión
  /// - [ServerException] si hay un error del servidor
  Future<AuthResultDTO> register(String email, String username, String password);

  Future<void> logout();
  Future<String?> getToken();
  Future<bool> isAuthenticated();
}
