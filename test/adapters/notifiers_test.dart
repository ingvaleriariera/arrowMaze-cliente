import 'package:test/test.dart';
import 'package:arrow_maze_cliente_copy/adapters/notifiers/game_notifier.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/game_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/activate_arrow_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/load_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/pause_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/restart_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/resume_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/use_power_up_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/save_progress_use_case.dart';
import 'test/application/mocks/mock_audio_service.dart';
import 'test/application/mocks/mock_game_progress_repository.dart';
import 'test/application/mocks/mock_level_repository.dart';

void main() {
  group('Adapter Layer - Notifiers', () {
    test('Scenario 6: GameNotifier loads level and initializes GameState', () async {
      final levelRepo = MockLevelRepository();
      final progressRepo = MockGameProgressRepository();
      final audioService = MockAudioService();

      final loadLevelUseCase = LoadLevelUseCase(levelRepository: levelRepo);
      final activateArrowUseCase = ActivateArrowUseCase(audioService: audioService);
      final pauseLevelUseCase = PauseLevelUseCase();
      final resumeLevelUseCase = ResumeLevelUseCase();
      final restartLevelUseCase = RestartLevelUseCase(loadLevelUseCase: loadLevelUseCase);
      final usePowerUpUseCase = UsePowerUpUseCase(
        progressRepository: progressRepo,
        audioService: audioService,
      );
      final saveProgressUseCase = SaveProgressUseCase(progressRepository: progressRepo);

      final gameNotifier = GameNotifier(
        loadLevelUseCase: loadLevelUseCase,
        activateArrowUseCase: activateArrowUseCase,
        pauseLevelUseCase: pauseLevelUseCase,
        resumeLevelUseCase: resumeLevelUseCase,
        restartLevelUseCase: restartLevelUseCase,
        usePowerUpUseCase: usePowerUpUseCase,
        saveProgressUseCase: saveProgressUseCase,
      );

      expect(gameNotifier.state.session, isNull);
      
      await gameNotifier.loadLevel('level_001', 'user_123');

      expect(gameNotifier.state.session, isNotNull);
      expect(gameNotifier.state.session!.levelId, equals('level_001'));
      expect(gameNotifier.state.session!.maxMoves, equals(10));
    });

    test('Scenario 7: GameNotifier.pause stops timer and updates state', () async {
      final levelRepo = MockLevelRepository();
      final progressRepo = MockGameProgressRepository();
      final audioService = MockAudioService();

      final loadLevelUseCase = LoadLevelUseCase(levelRepository: levelRepo);
      final activateArrowUseCase = ActivateArrowUseCase(audioService: audioService);
      final pauseLevelUseCase = PauseLevelUseCase();
      final resumeLevelUseCase = ResumeLevelUseCase();
      final restartLevelUseCase = RestartLevelUseCase(loadLevelUseCase: loadLevelUseCase);
      final usePowerUpUseCase = UsePowerUpUseCase(
        progressRepository: progressRepo,
        audioService: audioService,
      );
      final saveProgressUseCase = SaveProgressUseCase(progressRepository: progressRepo);

      final gameNotifier = GameNotifier(
        loadLevelUseCase: loadLevelUseCase,
        activateArrowUseCase: activateArrowUseCase,
        pauseLevelUseCase: pauseLevelUseCase,
        resumeLevelUseCase: resumeLevelUseCase,
        restartLevelUseCase: restartLevelUseCase,
        usePowerUpUseCase: usePowerUpUseCase,
        saveProgressUseCase: saveProgressUseCase,
      );

      await gameNotifier.loadLevel('level_001', 'user_123');
      gameNotifier.pause();

      expect(gameNotifier.state.session!.isPlaying(), isFalse);
    });
  });
}
