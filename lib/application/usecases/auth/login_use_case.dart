import 'package:arrow_maze_cliente_copy/application/dtos/auth_result_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/login_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository authRepository;

  LoginUseCase({required this.authRepository});

  Future<AuthResultDTO> execute(LoginInputDTO input) async {
    return authRepository.login(input.email, input.password);
  }
}
