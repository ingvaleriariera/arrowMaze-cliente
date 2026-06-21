import '../../dtos/auth_result_dto.dart';
import '../../ports/i_auth_repository.dart';

/// Restaura la sesión local (token + userId) al reabrir la app, para que
/// AuthNotifier tenga el userId real en vez de caer en un fallback vacío.
class RestoreSessionUseCase {
  final IAuthRepository authRepository;

  RestoreSessionUseCase(this.authRepository);

  Future<AuthResultDTO?> execute() async {
    final isAuth = await authRepository.isAuthenticated();
    if (!isAuth) return null;
    final token = await authRepository.getToken();
    final userId = await authRepository.getUserId();
    if (token == null || userId == null) return null;
    return AuthResultDTO(token, userId);
  }
}
