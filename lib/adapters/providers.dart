import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/api/api_client.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/locale_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/level_mapper.dart';
import 'package:arrow_maze_cliente_copy/adapters/mappers/progress_mapper.dart';
import 'package:arrow_maze_cliente_copy/adapters/observers/audio_observer.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/config/api_config.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/auth_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/game_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/leaderboard_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/level_select_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/settings_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/auth_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/audio_service_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/game_progress_database.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/game_progress_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/in_memory_board_cache.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/leaderboard_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/score_repository_impl.dart';
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
import 'package:arrow_maze_cliente_copy/application/usecases/score/submit_score_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/leaderboard/get_global_leaderboard_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/get_local_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/save_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/sync_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_time_limit_policy.dart';
import 'package:arrow_maze_cliente_copy/domain/services/per_arrow_time_limit_policy.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/lives_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/lives_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/lives_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/buy_life_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/get_lives_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/lives/lose_life_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_lives_repository.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/boards_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/custom_aware_level_repository.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/custom_board_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/my_boards_repository_impl.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/boards_state.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_custom_board_repository.dart';
import 'package:arrow_maze_cliente_copy/application/ports/i_my_boards_repository.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/create_custom_board_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/delete_custom_board_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/get_community_boards_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/boards/manage_my_boards_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/builders/board_generation_request.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_level_repository.dart';

// API
final apiClientProvider = Provider((ref) => ApiClient(
  baseUrl: ApiConfig.apiBaseUrl,
));

// Mappers
final levelMapperProvider = Provider((ref) => LevelMapper());
final progressMapperProvider = Provider((ref) => ProgressMapper());

// Repositories
// Decorator chain (see CustomAwareLevelRepository): ids with the
// 'custom-' prefix resolve from the locally adopted community boards,
// everything else hits the standard backend-backed repository. Consumers
// only ever see ILevelRepository — the game pipeline can't tell player-
// made boards from seeded ones.
final levelRepositoryProvider = Provider<ILevelRepository>((ref) =>
    CustomAwareLevelRepository(
      inner: LevelRepositoryImpl(
        apiClient: ref.watch(apiClientProvider),
        levelMapper: ref.watch(levelMapperProvider),
      ),
      myBoards: ref.watch(myBoardsRepositoryProvider),
    ));

final gameProgressRepositoryProvider = Provider((ref) => GameProgressRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
  progressMapper: ref.watch(progressMapperProvider),
  database: ref.watch(gameProgressDatabaseProvider),
));

final authRepositoryProvider = Provider((ref) => AuthRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
));

final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
));

final scoreRepositoryProvider = Provider((ref) => ScoreRepositoryImpl(
  apiClient: ref.watch(apiClientProvider),
));

final audioServiceProvider = Provider((ref) => AudioServiceImpl());

// Observer that responds to game events with audio effects and music
final audioObserverProvider = Provider((ref) => AudioObserver(
  ref.watch(audioServiceProvider),
));

final biometricServiceProvider = Provider((ref) => BiometricService());

final gameProgressDatabaseProvider = Provider((ref) => GameProgressDatabase());

// In-memory cache of pre-generated boards, shared by LoadLevelUseCase
// (consumer) and PreloadLevelsUseCase (producer). Kept alive for the app's
// lifetime, same as the other repository providers.
final boardCacheProvider = Provider((ref) => InMemoryBoardCache());

// Clock rule for timed levels (Strategy): typed as the port so consumers
// depend on the abstraction, not on the concrete per-arrow rule.
final timeLimitPolicyProvider =
    Provider<ITimeLimitPolicy>((ref) => PerArrowTimeLimitPolicy());

// Extrusion depth for board construction, driven by the "Juego 3D"
// setting. select() keeps unrelated settings changes (sound, vibration…)
// from rebuilding the level-loading use cases; flipping THIS toggle does
// rebuild them (and GameNotifier), which is fine — it happens in the
// settings screen, never mid-game. The board cache is depth-keyed, so
// layouts generated at one depth are never replayed at another.
final boardDepthProvider = Provider<int>((ref) =>
    ref.watch(settingsNotifierProvider.select((s) => s.game3DEnabled))
        ? kBoardDepth3D
        : kBoardDepth);

// Use Cases
final loadLevelUseCaseProvider = Provider((ref) => LoadLevelUseCase(
  levelRepository: ref.watch(levelRepositoryProvider),
  boardCache: ref.watch(boardCacheProvider),
  timeLimitPolicy: ref.watch(timeLimitPolicyProvider),
  boardDepth: ref.watch(boardDepthProvider),
));

final preloadLevelsUseCaseProvider = Provider((ref) => PreloadLevelsUseCase(
  levelRepository: ref.watch(levelRepositoryProvider),
  boardCache: ref.watch(boardCacheProvider),
  boardDepth: ref.watch(boardDepthProvider),
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

final getGlobalLeaderboardUseCaseProvider = Provider((ref) => GetGlobalLeaderboardUseCase(
  leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
));

final submitScoreUseCaseProvider = Provider((ref) => SubmitScoreUseCase(
  scoreRepository: ref.watch(scoreRepositoryProvider),
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
    submitScoreUseCase: ref.watch(submitScoreUseCaseProvider),
    getVibrationEnabled: () => ref.read(settingsNotifierProvider).vibrationEnabled,
    audioObserver: ref.watch(audioObserverProvider),
    audioService: ref.watch(audioServiceProvider),
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
    manageMyBoardsUseCase: ref.watch(manageMyBoardsUseCaseProvider),
    audioService: ref.watch(audioServiceProvider),
  )
);

// Lives
final livesRepositoryProvider =
    Provider<ILivesRepository>((ref) => LivesRepositoryImpl());

final getLivesUseCaseProvider = Provider((ref) => GetLivesUseCase(
  livesRepository: ref.watch(livesRepositoryProvider),
));

final loseLifeUseCaseProvider = Provider((ref) => LoseLifeUseCase(
  livesRepository: ref.watch(livesRepositoryProvider),
));

final buyLifeUseCaseProvider = Provider((ref) => BuyLifeUseCase(
  livesRepository: ref.watch(livesRepositoryProvider),
  progressRepository: ref.watch(gameProgressRepositoryProvider),
));

final livesNotifierProvider = StateNotifierProvider<LivesNotifier, LivesState>((ref) =>
  LivesNotifier(
    getLivesUseCase: ref.watch(getLivesUseCaseProvider),
    loseLifeUseCase: ref.watch(loseLifeUseCaseProvider),
    buyLifeUseCase: ref.watch(buyLifeUseCaseProvider),
  )
);

// Custom boards (community level editor)
final customBoardRepositoryProvider = Provider<ICustomBoardRepository>(
    (ref) => CustomBoardRepositoryImpl(apiClient: ref.watch(apiClientProvider)));

final myBoardsRepositoryProvider =
    Provider<IMyBoardsRepository>((ref) => MyBoardsRepositoryImpl());

final getCommunityBoardsUseCaseProvider = Provider((ref) =>
    GetCommunityBoardsUseCase(
        customBoardRepository: ref.watch(customBoardRepositoryProvider)));

final manageMyBoardsUseCaseProvider = Provider((ref) =>
    ManageMyBoardsUseCase(myBoardsRepository: ref.watch(myBoardsRepositoryProvider)));

final createCustomBoardUseCaseProvider = Provider((ref) => CreateCustomBoardUseCase(
      customBoardRepository: ref.watch(customBoardRepositoryProvider),
      myBoardsRepository: ref.watch(myBoardsRepositoryProvider),
    ));

final deleteCustomBoardUseCaseProvider = Provider((ref) => DeleteCustomBoardUseCase(
      customBoardRepository: ref.watch(customBoardRepositoryProvider),
    ));

final boardsNotifierProvider = StateNotifierProvider<BoardsNotifier, BoardsState>((ref) =>
  BoardsNotifier(
    getCommunityBoardsUseCase: ref.watch(getCommunityBoardsUseCaseProvider),
    manageMyBoardsUseCase: ref.watch(manageMyBoardsUseCaseProvider),
    createCustomBoardUseCase: ref.watch(createCustomBoardUseCaseProvider),
    deleteCustomBoardUseCase: ref.watch(deleteCustomBoardUseCaseProvider),
  )
);

final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) =>
  LeaderboardNotifier(
    getLeaderboardUseCase: ref.watch(getLeaderboardUseCaseProvider),
    getGlobalLeaderboardUseCase: ref.watch(getGlobalLeaderboardUseCaseProvider),
  )
);

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) =>
  SettingsNotifier(
    audioService: ref.watch(audioServiceProvider),
  )
);

final localeNotifierProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) =>
  LocaleNotifier(const Locale('en', ''))
);
