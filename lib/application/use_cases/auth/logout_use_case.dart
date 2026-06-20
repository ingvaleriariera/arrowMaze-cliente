import '../../ports/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository authRepository;

  LogoutUseCase(this.authRepository);

  Future<void> execute() => authRepository.logout();
}
