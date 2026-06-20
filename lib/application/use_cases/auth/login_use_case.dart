import '../../dtos/auth_result_dto.dart';
import '../../dtos/login_input_dto.dart';
import '../../ports/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository authRepository;

  LoginUseCase(this.authRepository);

  Future<AuthResultDTO> execute(LoginInputDTO input) =>
      authRepository.login(input.email, input.password);
}
