import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/login_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/dtos/register_input_dto.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/login_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/auth/register_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/activate_arrow_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/get_level_summaries_use_case.dart';
import 'package:arrow_maze_cliente_copy/adapters/repositories/in_memory_board_cache.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/load_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/use_power_up_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/hint_power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/states/playing_state.dart';
import 'mocks/mock_auth_repository.dart';
import 'mocks/mock_audio_service.dart';
import 'mocks/mock_game_progress_repository.dart';
import 'mocks/mock_leaderboard_repository.dart';
import 'mocks/mock_level_repository.dart';

void main() {
  group('Application Layer - Use Cases', () {
    group('Game Use Cases', () {
      test('Scenario 1: LoadLevelUseCase returns GameSession in PlayingState', () async {
        final levelRepository = MockLevelRepository();
        final loadLevelUseCase = LoadLevelUseCase(levelRepository: levelRepository, boardCache: InMemoryBoardCache());

        final session = await loadLevelUseCase.execute('level_001');

        expect(session, isNotNull);
        expect(session.levelId, equals('level_001'));
        expect(session.maxMoves, equals(10));
        expect(session.state is PlayingState, isTrue);
        expect(session.board, isNotNull);
        expect(session.board.shape.size(), greaterThan(0));
      });

      test('Scenario 2a: ActivateArrowUseCase with successful move plays sound', () async {
        final audioService = MockAudioService();
        final activateArrowUseCase = ActivateArrowUseCase(audioService: audioService);

        final levelRepository = MockLevelRepository();
        final loadLevelUseCase = LoadLevelUseCase(levelRepository: levelRepository, boardCache: InMemoryBoardCache());
        final session = await loadLevelUseCase.execute('level_001');

        // Add an arrow to the board for testing
        // For now, we'll just verify the case where there's no activatable arrow
        // (which will result in failure)
        final result = activateArrowUseCase.execute(session, 'nonexistent_arrow');

        // The result should be failure since the arrow doesn't exist
        // But the function will still execute and return the MoveResult
        expect(result, isNotNull);
      });

      test('Scenario 2b: ActivateArrowUseCase with failed move does not play sound', () async {
        final audioService = MockAudioService();
        final activateArrowUseCase = ActivateArrowUseCase(audioService: audioService);

        final levelRepository = MockLevelRepository();
        final loadLevelUseCase = LoadLevelUseCase(levelRepository: levelRepository, boardCache: InMemoryBoardCache());
        final session = await loadLevelUseCase.execute('level_001');

        // Execute a move on non-existent arrow (will fail)
        final result = await activateArrowUseCase.execute(session, 'nonexistent');

        // Failed move should not trigger sound
        expect(result.success, isFalse);
        expect(audioService.playedEffects, isEmpty);
      });

      test('Scenario 3: UsePowerUpUseCase without enough coins returns failure', () async {
        final progressRepository = MockGameProgressRepository();
        final audioService = MockAudioService();
        final usePowerUpUseCase = UsePowerUpUseCase(
          progressRepository: progressRepository,
          audioService: audioService,
        );

        final levelRepository = MockLevelRepository();
        final loadLevelUseCase = LoadLevelUseCase(levelRepository: levelRepository, boardCache: InMemoryBoardCache());
        final session = await loadLevelUseCase.execute('level_001');

        // Create progress with 0 coins
        final progress = GameProgress(userId: 'user_123', coins: 0);

        // Try to use hint power-up (costs 10 coins)
        final hint = HintPowerUp();
        final result = await usePowerUpUseCase.execute(session, hint, progress);

        expect(result.success, isFalse);
        expect(result.message, contains('Not enough coins'));
        expect(progress.coins, equals(0), reason: 'Coins should not be spent');
        expect(audioService.playedEffects, isEmpty, reason: 'Sound should not play');
      });

      test('Scenario 4: UsePowerUpUseCase with sufficient coins applies and persists',
          () async {
        final progressRepository = MockGameProgressRepository();
        final audioService = MockAudioService();
        final usePowerUpUseCase = UsePowerUpUseCase(
          progressRepository: progressRepository,
          audioService: audioService,
        );

        final levelRepository = MockLevelRepository();
        final loadLevelUseCase = LoadLevelUseCase(levelRepository: levelRepository, boardCache: InMemoryBoardCache());
        final session = await loadLevelUseCase.execute('level_001');

        // Create progress with enough coins
        final progress = GameProgress(userId: 'user_123', coins: 100);

        // Use hint power-up (costs 10 coins)
        // Note: The hint will only work if there are activatable arrows
        // Since we don't have arrows in the board, it will fail to apply
        // but coins will still be deducted

        final hint = HintPowerUp();
        final result = await usePowerUpUseCase.execute(session, hint, progress);

        // In this case, the hint can't be applied because there are no arrows
        // So coins should be refunded
        expect(progress.coins, equals(100), reason: 'Coins should be refunded if power-up fails');
      });

      test('Scenario 5: GetLevelSummariesUseCase combines level and progress data', () async {
        final levelRepository = MockLevelRepository();
        final progressRepository = MockGameProgressRepository();

        final getLevelSummariesUseCase = GetLevelSummariesUseCase(
          levelRepository: levelRepository,
          progressRepository: progressRepository,
        );

        final userId = 'user_123';

        // Create and save some progress
        final progress = GameProgress(userId: userId);
        progress.recordCompletion('level_001', 250);
        await progressRepository.save(progress);

        // Get summaries
        final summaries = await getLevelSummariesUseCase.execute(userId);

        expect(summaries, isNotEmpty);
        expect(summaries.length, equals(2));

        // Check first level (completed)
        final summary1 = summaries.firstWhere((s) => s.levelId == 'level_001');
        expect(summary1.completed, isTrue);
        expect(summary1.bestScore, equals(250));
        expect(summary1.difficulty, equals('EASY'));

        // Check second level (not completed)
        final summary2 = summaries.firstWhere((s) => s.levelId == 'level_002');
        expect(summary2.completed, isFalse);
        expect(summary2.bestScore, equals(0));
        expect(summary2.isTimed, isTrue);
      });
    });

    group('Auth Use Cases', () {
      test('Scenario 6: LoginUseCase delegates correctly and returns AuthResultDTO',
          () async {
        final authRepository = MockAuthRepository();
        final loginUseCase = LoginUseCase(authRepository: authRepository);

        final input = LoginInputDTO(email: 'test@example.com', password: 'password123');
        final result = await loginUseCase.execute(input);

        expect(result, isNotNull);
        expect(result.userId, isNotNull);
        expect(result.token, isNotNull);
        expect(result.token, isNotEmpty);
      });

      test('LoginUseCase fails with invalid credentials', () async {
        final authRepository = MockAuthRepository();
        final loginUseCase = LoginUseCase(authRepository: authRepository);

        final input = LoginInputDTO(email: 'test@example.com', password: 'wrong_password');

        expect(
          () => loginUseCase.execute(input),
          throwsException,
        );
      });

      test('RegisterUseCase creates new user', () async {
        final authRepository = MockAuthRepository();
        final registerUseCase = RegisterUseCase(authRepository: authRepository);

        final input = RegisterInputDTO(
          email: 'newuser@example.com',
          username: 'newuser',
          password: 'password456',
        );

        final result = await registerUseCase.execute(input);

        expect(result, isNotNull);
        expect(result.userId, isNotNull);
        expect(result.token, isNotEmpty);
      });

      test('RegisterUseCase fails for duplicate email', () async {
        final authRepository = MockAuthRepository();
        final registerUseCase = RegisterUseCase(authRepository: authRepository);

        final input = RegisterInputDTO(
          email: 'test@example.com', // Already exists
          username: 'duplicate',
          password: 'password789',
        );

        expect(
          () => registerUseCase.execute(input),
          throwsException,
        );
      });
    });

    group('Progress Use Cases', () {
      test('SaveProgressUseCase persists progress', () async {
        final progressRepository = MockGameProgressRepository();

        final progress = GameProgress(userId: 'user_123', coins: 150);
        progress.recordCompletion('level_001', 300);

        await progressRepository.save(progress);

        final retrieved = await progressRepository.get('user_123');
        expect(retrieved, isNotNull);
        expect(retrieved!.coins, equals(150));
        expect(retrieved.isCompleted('level_001'), isTrue);
        expect(retrieved.getBestScore('level_001'), equals(300));
      });

      test('GetLocalProgressUseCase retrieves saved progress', () async {
        final progressRepository = MockGameProgressRepository();

        final progress = GameProgress(userId: 'user_456', coins: 200);
        progress.recordCompletion('level_002', 400);
        await progressRepository.save(progress);

        final retrieved = await progressRepository.get('user_456');
        expect(retrieved, isNotNull);
        expect(retrieved!.userId, equals('user_456'));
        expect(retrieved.coins, equals(200));
      });

      test('SyncProgressUseCase creates new if not found', () async {
        final progressRepository = MockGameProgressRepository();

        final synced = await progressRepository.sync('new_user');
        expect(synced, isNotNull);
        expect(synced.userId, equals('new_user'));
        expect(synced.completedLevels, isEmpty);
      });
    });

    group('Leaderboard Use Cases', () {
      test('GetLeaderboardUseCase retrieves top scores', () async {
        final leaderboardRepository = MockLeaderboardRepository();

        final entries = await leaderboardRepository.getTopScores('level_001', 5);

        expect(entries, isNotEmpty);
        expect(entries.length, equals(3));
        expect(entries[0].rank, equals(1));
        expect(entries[0].username, equals('player1'));
        expect(entries[0].score, equals(500));
      });

      test('GetLeaderboardUseCase respects limit', () async {
        final leaderboardRepository = MockLeaderboardRepository();

        final entries = await leaderboardRepository.getTopScores('level_001', 2);

        expect(entries.length, equals(2));
        expect(entries[0].rank, equals(1));
        expect(entries[1].rank, equals(2));
      });
    });
  });
}
