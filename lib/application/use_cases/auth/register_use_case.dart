import '../../dtos/auth_result_dto.dart';
import '../../dtos/register_input_dto.dart';
import '../../ports/i_auth_repository.dart';

class RegisterUseCase {
  final IAuthRepository authRepository;

  RegisterUseCase(this.authRepository);

  Future<AuthResultDTO> execute(RegisterInputDTO input) =>
      authRepository.register(input.email, input.username, input.password);
}
