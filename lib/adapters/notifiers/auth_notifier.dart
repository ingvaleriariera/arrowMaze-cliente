import 'package:flutter_riverpod/legacy.dart';

import '../../application/dtos/login_input_dto.dart';
import '../../application/dtos/register_input_dto.dart';
import '../../application/use_cases/auth/login_use_case.dart';
import '../../application/use_cases/auth/logout_use_case.dart';
import '../../application/use_cases/auth/register_use_case.dart';
import '../../application/use_cases/progress/sync_progress_use_case.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;

  const AuthState({this.isAuthenticated = false, this.userId});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final SyncProgressUseCase syncProgressUseCase;

  AuthNotifier(
    this.loginUseCase,
    this.registerUseCase,
    this.logoutUseCase,
    this.syncProgressUseCase,
  ) : super(const AuthState());

  Future<void> login(String email, String password) async {
    final result = await loginUseCase.execute(LoginInputDTO(email, password));
    state = AuthState(isAuthenticated: true, userId: result.userId);
    await syncProgressUseCase.execute(result.userId);
  }

  Future<void> register(String email, String username, String password) async {
    final result = await registerUseCase.execute(RegisterInputDTO(email, username, password));
    state = AuthState(isAuthenticated: true, userId: result.userId);
    await syncProgressUseCase.execute(result.userId);
  }

  Future<void> logout() async {
    await logoutUseCase.execute();
    state = const AuthState();
  }

  bool getIsAuthenticated() => state.isAuthenticated;

  String? getUserId() => state.userId;
}
