import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/level_mapper.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/progress_mapper.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/auth_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/game_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/leaderboard_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/level_select_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/settings_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/auth_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/audio_service_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/game_progress_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/in_memory_board_cache.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/leaderboard_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/level_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/auth_state.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/game_state.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/leaderboard_state.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/level_select_state.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/settings_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/login_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/logout_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/register_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/face_id_login_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/face_id_login_with_email_use_case.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/services/biometric_service.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/activate_arrow_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/get_level_summaries_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/load_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/pause_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/preload_levels_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/restart_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/resume_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/use_power_up_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/leaderboard/get_leaderboard_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/get_local_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/save_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/sync_progress_use_case.dart';

// API
final apiClientProvider = Provider((ref) => ApiClient(
  baseUrl: 'http://172.16.0.146:3000',
));

// Mappers
final levelMapperProvider = Provider((ref) => LevelMapper());
final progressMapperProvider = Provider((ref) => ProgressMapper());

// Repositories
final levelRepositoryProvider = Provider((ref) => LevelRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
  levelMapper: ref.watch(levelMapperProvider),
));

final gameProgressRepositoryProvider = Provider((ref) => GameProgressRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
  progressMapper: ref.watch(progressMapperProvider),
));

final authRepositoryProvider = Provider((ref) => AuthRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
));

final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
));

final audioServiceProvider = Provider((ref) => AudioServiceImpl());

final biometricServiceProvider = Provider((ref) => BiometricService());

// In-memory cache of pre-generated boards, shared by LoadLevelUseCase
// (consumer) and PreloadLevelsUseCase (producer). Kept alive for the app's
// lifetime, same as the other repository providers.
final boardCacheProvider = Provider((ref) => InMemoryBoardCache());

// Use Cases
final loadLevelUseCaseProvider = Provider((ref) => LoadLevelUseCase(
  levelRepository: ref.watch(levelRepositoryProvider),
  boardCache: ref.watch(boardCacheProvider),
));

final preloadLevelsUseCaseProvider = Provider((ref) => PreloadLevelsUseCase(
  levelRepository: ref.watch(levelRepositoryProvider),
  boardCache: ref.watch(boardCacheProvider),
));

final activateArrowUseCaseProvider = Provider((ref) => ActivateArrowUseCase(
  audioService: ref.watch(audioServiceProvider),
));

final pauseLevelUseCaseProvider = Provider((ref) => PauseLevelUseCase());

final resumeLevelUseCaseProvider = Provider((ref) => ResumeLevelUseCase());

final restartLevelUseCaseProvider = Provider((ref) => RestartLevelUseCase(
  loadLevelUseCase: ref.watch(loadLevelUseCaseProvider),
));

final usePowerUpUseCaseProvider = Provider((ref) => UsePowerUpUseCase(
  progressRepository: ref.watch(gameProgressRepositoryProvider),
  audioService: ref.watch(audioServiceProvider),
));

final saveProgressUseCaseProvider = Provider((ref) => SaveProgressUseCase(
  progressRepository: ref.watch(gameProgressRepositoryProvider),
));

final getLocalProgressUseCaseProvider = Provider((ref) => GetLocalProgressUseCase(
  progressRepository: ref.watch(gameProgressRepositoryProvider),
));

final syncProgressUseCaseProvider = Provider((ref) => SyncProgressUseCase(
  progressRepository: ref.watch(gameProgressRepositoryProvider),
));

final getLevelSummariesUseCaseProvider = Provider((ref) => GetLevelSummariesUseCase(
  levelRepository: ref.watch(levelRepositoryProvider),
  progressRepository: ref.watch(gameProgressRepositoryProvider),
));

final getLeaderboardUseCaseProvider = Provider((ref) => GetLeaderboardUseCase(
  leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
));

final loginUseCaseProvider = Provider((ref) => LoginUseCase(
  authRepository: ref.watch(authRepositoryProvider),
));

final registerUseCaseProvider = Provider((ref) => RegisterUseCase(
  authRepository: ref.watch(authRepositoryProvider),
));

final logoutUseCaseProvider = Provider((ref) => LogoutUseCase(
  authRepository: ref.watch(authRepositoryProvider),
));

final faceIdLoginUseCaseProvider = Provider((ref) => FaceIdLoginUseCase(
  authRepository: ref.watch(authRepositoryProvider),
  biometricService: ref.watch(biometricServiceProvider),
));

final faceIdLoginWithEmailUseCaseProvider = Provider((ref) => FaceIdLoginWithEmailUseCase(
  authRepository: ref.watch(authRepositoryProvider),
  biometricService: ref.watch(biometricServiceProvider),
));

// StateNotifiers
final gameNotifierProvider = StateNotifierProvider<GameNotifier, GameState>((ref) =>
  GameNotifier(
    loadLevelUseCase: ref.watch(loadLevelUseCaseProvider),
    activateArrowUseCase: ref.watch(activateArrowUseCaseProvider),
    pauseLevelUseCase: ref.watch(pauseLevelUseCaseProvider),
    resumeLevelUseCase: ref.watch(resumeLevelUseCaseProvider),
    restartLevelUseCase: ref.watch(restartLevelUseCaseProvider),
    usePowerUpUseCase: ref.watch(usePowerUpUseCaseProvider),
    saveProgressUseCase: ref.watch(saveProgressUseCaseProvider),
    getLocalProgressUseCase: ref.watch(getLocalProgressUseCaseProvider),
    preloadLevelsUseCase: ref.watch(preloadLevelsUseCaseProvider),
  )
);

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) =>
  AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    syncProgressUseCase: ref.watch(syncProgressUseCaseProvider),
    faceIdLoginUseCase: ref.watch(faceIdLoginUseCaseProvider),
    faceIdLoginWithEmailUseCase: ref.watch(faceIdLoginWithEmailUseCaseProvider),
  )
);

final levelSelectNotifierProvider = StateNotifierProvider<LevelSelectNotifier, LevelSelectState>((ref) =>
  LevelSelectNotifier(
    getLevelSummariesUseCase: ref.watch(getLevelSummariesUseCaseProvider),
    preloadLevelsUseCase: ref.watch(preloadLevelsUseCaseProvider),
  )
);

final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) =>
  LeaderboardNotifier(
    getLeaderboardUseCase: ref.watch(getLeaderboardUseCaseProvider),
  )
);

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) =>
  SettingsNotifier(
    audioService: ref.watch(audioServiceProvider),
  )
);
