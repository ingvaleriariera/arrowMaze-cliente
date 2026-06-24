import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/auth_state.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/login_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/register_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/login_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/logout_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/register_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/sync_progress_use_case.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final SyncProgressUseCase syncProgressUseCase;

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.syncProgressUseCase,
  }) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final input = LoginInputDTO(email: email, password: password);
      final result = await loginUseCase.execute(input);
      
      // Sync progress from backend
      await syncProgressUseCase.execute(result.userId);

      state = state.copyWith(
        isAuthenticated: true,
        userId: result.userId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final input = RegisterInputDTO(email: email, username: username, password: password);
      final result = await registerUseCase.execute(input);

      // Sync progress from backend
      await syncProgressUseCase.execute(result.userId);

      state = state.copyWith(
        isAuthenticated: true,
        userId: result.userId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    try {
      await logoutUseCase.execute();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> checkAuth() async {
    // Check if user is already authenticated (e.g., from stored token)
    // This would be called on app startup
  }
}
