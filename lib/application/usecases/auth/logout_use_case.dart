import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository authRepository;

  LogoutUseCase({required this.authRepository});

  Future<void> execute() async {
    return authRepository.logout();
  }
}
