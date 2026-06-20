import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

import '../../adapters/api/api_client.dart';
import '../../adapters/mappers/level_mapper.dart';
import '../../adapters/mappers/progress_mapper.dart';
import '../../adapters/notifiers/auth_notifier.dart';
import '../../adapters/notifiers/game_notifier.dart';
import '../../adapters/notifiers/leaderboard_notifier.dart';
import '../../adapters/notifiers/level_select_notifier.dart';
import '../../adapters/notifiers/settings_notifier.dart';
import '../../adapters/repositories/auth_repository_impl.dart';
import '../../adapters/repositories/game_progress_repository_impl.dart';
import '../../adapters/repositories/leaderboard_repository_impl.dart';
import '../../adapters/repositories/level_repository_impl.dart';
import '../../adapters/services/audio_service_impl.dart';
import '../../application/dtos/leaderboard_entry_dto.dart';
import '../../application/dtos/level_summary_dto.dart';
import '../../application/ports/i_auth_repository.dart';
import '../../application/ports/i_audio_service.dart';
import '../../application/ports/i_leaderboard_repository.dart';
import '../../application/use_cases/auth/login_use_case.dart';
import '../../application/use_cases/auth/logout_use_case.dart';
import '../../application/use_cases/auth/register_use_case.dart';
import '../../application/use_cases/game/activate_arrow_use_case.dart';
import '../../application/use_cases/game/get_level_summaries_use_case.dart';
import '../../application/use_cases/game/load_level_use_case.dart';
import '../../application/use_cases/game/pause_level_use_case.dart';
import '../../application/use_cases/game/restart_level_use_case.dart';
import '../../application/use_cases/game/resume_level_use_case.dart';
import '../../application/use_cases/power_ups/use_power_up_use_case.dart';
import '../../application/use_cases/progress/get_leaderboard_use_case.dart';
import '../../application/use_cases/progress/get_local_progress_use_case.dart';
import '../../application/use_cases/progress/save_progress_use_case.dart';
import '../../application/use_cases/progress/sync_progress_use_case.dart';
import '../../domain/ports/i_game_progress_repository.dart';
import '../../domain/ports/i_level_repository.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/error_interceptor.dart';
import '../interceptors/logging_interceptor.dart';

// ─── Infraestructura ──────────────────────────────────────────────────────────

/// Inicializado en main() con ProviderScope(overrides: [databaseProvider.overrideWithValue(...)])
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Database must be overridden in ProviderScope');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage();
});

// ─── Auth Repository (sin interceptores de auth para evitar ciclo) ─────────────

final _authDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
  dio.interceptors.addAll([LoggingInterceptor(), ErrorInterceptor()]);
  return dio;
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl(
    ApiClient(ref.read(_authDioProvider)),
    ref.read(secureStorageProvider),
  );
});

// ─── ApiClient principal (con auth interceptor) ───────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
  dio.interceptors.addAll([
    AuthInterceptor(ref.read(authRepositoryProvider)),
    LoggingInterceptor(),
    ErrorInterceptor(),
  ]);
  return ApiClient(dio);
});

// ─── Repositorios ────────────────────────────────────────────────────────────

final levelRepositoryProvider = Provider<ILevelRepository>((ref) {
  return LevelRepositoryImpl(ref.read(apiClientProvider), LevelMapper());
});

final progressRepositoryProvider = Provider<IGameProgressRepository>((ref) {
  return GameProgressRepositoryImpl(
    ref.read(apiClientProvider),
    ProgressMapper(),
    ref.read(databaseProvider),
  );
});

final leaderboardRepositoryProvider = Provider<ILeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl(ref.read(apiClientProvider));
});

final audioServiceProvider = Provider<IAudioService>((_) {
  return AudioServiceImpl();
});

// ─── Use Cases ────────────────────────────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

final loadLevelUseCaseProvider = Provider<LoadLevelUseCase>((ref) {
  return LoadLevelUseCase(ref.read(levelRepositoryProvider));
});

final activateArrowUseCaseProvider = Provider<ActivateArrowUseCase>((ref) {
  return ActivateArrowUseCase(ref.read(audioServiceProvider));
});

final pauseLevelUseCaseProvider = Provider<PauseLevelUseCase>((_) {
  return PauseLevelUseCase();
});

final resumeLevelUseCaseProvider = Provider<ResumeLevelUseCase>((_) {
  return ResumeLevelUseCase();
});

final restartLevelUseCaseProvider = Provider<RestartLevelUseCase>((ref) {
  return RestartLevelUseCase(ref.read(loadLevelUseCaseProvider));
});

final usePowerUpUseCaseProvider = Provider<UsePowerUpUseCase>((ref) {
  return UsePowerUpUseCase(
    ref.read(progressRepositoryProvider),
    ref.read(audioServiceProvider),
  );
});

final saveProgressUseCaseProvider = Provider<SaveProgressUseCase>((ref) {
  return SaveProgressUseCase(ref.read(progressRepositoryProvider));
});

final getLocalProgressUseCaseProvider = Provider<GetLocalProgressUseCase>((ref) {
  return GetLocalProgressUseCase(ref.read(progressRepositoryProvider));
});

final syncProgressUseCaseProvider = Provider<SyncProgressUseCase>((ref) {
  return SyncProgressUseCase(ref.read(progressRepositoryProvider));
});

final getLevelSummariesUseCaseProvider = Provider<GetLevelSummariesUseCase>((ref) {
  return GetLevelSummariesUseCase(
    ref.read(levelRepositoryProvider),
    ref.read(progressRepositoryProvider),
  );
});

final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>((ref) {
  return GetLeaderboardUseCase(ref.read(leaderboardRepositoryProvider));
});

// ─── State Notifiers (Capa 3) ─────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(loginUseCaseProvider),
    ref.read(registerUseCaseProvider),
    ref.read(logoutUseCaseProvider),
    ref.read(syncProgressUseCaseProvider),
  );
});

final gameNotifierProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(
    ref.read(loadLevelUseCaseProvider),
    ref.read(activateArrowUseCaseProvider),
    ref.read(pauseLevelUseCaseProvider),
    ref.read(resumeLevelUseCaseProvider),
    ref.read(restartLevelUseCaseProvider),
    ref.read(usePowerUpUseCaseProvider),
    ref.read(saveProgressUseCaseProvider),
    ref.read(syncProgressUseCaseProvider),
    ref.read(getLocalProgressUseCaseProvider),
  );
});

final levelSelectNotifierProvider =
    StateNotifierProvider<LevelSelectNotifier, List<LevelSummaryDTO>>((ref) {
  return LevelSelectNotifier(ref.read(getLevelSummariesUseCaseProvider));
});

final leaderboardNotifierProvider =
    StateNotifierProvider<LeaderboardNotifier, List<LeaderboardEntryDTO>>(
        (ref) {
  return LeaderboardNotifier(ref.read(getLeaderboardUseCaseProvider));
});

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, bool>((ref) {
  return SettingsNotifier(ref.read(audioServiceProvider));
});
