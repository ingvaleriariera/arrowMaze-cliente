import 'package:arrow_maze_cliente_copy/application/dtos/auth_result_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/register_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_auth_repository.dart';

class RegisterUseCase {
  final IAuthRepository authRepository;

  RegisterUseCase({required this.authRepository});

  Future<AuthResultDTO> execute(RegisterInputDTO input) async {
    return authRepository.register(input.email, input.username, input.password);
  }
}
