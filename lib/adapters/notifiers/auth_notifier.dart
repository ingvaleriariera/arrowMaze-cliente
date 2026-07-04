import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/auth_state.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/login_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/register_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/login_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/logout_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/register_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/sync_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/exceptions/app_exceptions.dart';

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

  Future<void> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint('🔐 AuthNotifier.login: Attempting login for $emailOrUsername');
      final input = LoginInputDTO(emailOrUsername: emailOrUsername, password: password);
      final result = await loginUseCase.execute(input);
      
      debugPrint('✅ Login successful, userId=${result.userId}');
      
      // Update auth state immediately - don't wait for sync
      state = state.copyWith(
        isAuthenticated: true,
        userId: result.userId,
        isLoading: false,
      );

      // Sync progress in background - non-blocking
      debugPrint('🔄 AuthNotifier: Starting background sync');
      try {
        await syncProgressUseCase.execute(result.userId);
        debugPrint('✅ AuthNotifier: Background sync completed successfully');
      } catch (e) {
        // Sync failure is NOT a login failure - log it but don't block
        debugPrint('⚠️  AuthNotifier: Background sync failed (non-blocking) - $e');
        debugPrint('   User still authenticated and can proceed');
      }
    } on UnauthorizedException catch (e) {
      debugPrint('❌ AuthNotifier.login: Invalid credentials - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        isAuthenticated: false,
      );
    } catch (e) {
      debugPrint('❌ AuthNotifier.login: Login error - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Ocurrió un error. Intente de nuevo.',
        isAuthenticated: false,
      );
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint('📝 AuthNotifier.register: Attempting registration for $email');
      final input = RegisterInputDTO(email: email, username: username, password: password);
      final result = await registerUseCase.execute(input);

      debugPrint('✅ Registration successful, userId=${result.userId}');

      // Update auth state immediately - don't wait for sync
      state = state.copyWith(
        isAuthenticated: true,
        userId: result.userId,
        isLoading: false,
      );

      // Sync progress in background - non-blocking
      debugPrint('🔄 AuthNotifier: Starting background sync');
      try {
        await syncProgressUseCase.execute(result.userId);
        debugPrint('✅ AuthNotifier: Background sync completed successfully');
      } catch (e) {
        // Sync failure is NOT a registration failure - log it but don't block
        debugPrint('⚠️  AuthNotifier: Background sync failed (non-blocking) - $e');
        debugPrint('   User still authenticated and can proceed');
      }
    } on UnauthorizedException catch (e) {
      debugPrint('❌ AuthNotifier.register: Email or username already exists - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        isAuthenticated: false,
      );
    } catch (e) {
      debugPrint('❌ AuthNotifier.register: Registration error - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Ocurrió un error. Intentá de nuevo.',
        isAuthenticated: false,
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

  void clearError() {
    state = state.copyWith(error: null);
  }
}
