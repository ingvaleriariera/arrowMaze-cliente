import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/game_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/activate_arrow_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/load_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/pause_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/restart_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/resume_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/use_power_up_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/save_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';

class GameNotifier extends StateNotifier<GameState> {
  final LoadLevelUseCase loadLevelUseCase;
  final ActivateArrowUseCase activateArrowUseCase;
  final PauseLevelUseCase pauseLevelUseCase;
  final ResumeLevelUseCase resumeLevelUseCase;
  final RestartLevelUseCase restartLevelUseCase;
  final UsePowerUpUseCase usePowerUpUseCase;
  final SaveProgressUseCase saveProgressUseCase;

  Timer? _timer;

  GameNotifier({
    required this.loadLevelUseCase,
    required this.activateArrowUseCase,
    required this.pauseLevelUseCase,
    required this.resumeLevelUseCase,
    required this.restartLevelUseCase,
    required this.usePowerUpUseCase,
    required this.saveProgressUseCase,
  }) : super(const GameState());

  Future<void> loadLevel(String levelId, String userId) async {
    debugPrint('🎮 GameNotifier.loadLevel called with: $levelId');
    
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('   State set to isLoading=true');

    try {
      debugPrint('📞 GameNotifier: Calling loadLevelUseCase.execute($levelId)');
      final session = await loadLevelUseCase.execute(levelId);
      
      debugPrint('✅ GameNotifier: LoadLevelUseCase returned session');
      debugPrint('   Session: levelId=${session.levelId}, maxMoves=${session.maxMoves}');

      debugPrint('🔄 GameNotifier: Updating state with session');
      state = state.copyWith(
        session: session,
        isLoading: false,
      );
      
      debugPrint('✅ GameNotifier.loadLevel: State updated successfully');
      debugPrint('   Current state: isLoading=${state.isLoading}, session=${state.session != null ? "exists" : "null"}');

      if (session.isTimedLevel()) {
        debugPrint('⏱️  GameNotifier: Level is timed, would start timer here');
        _startTimer();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ GameNotifier.loadLevel: Exception caught');
      debugPrint('   Exception: $e');
      debugPrint('   StackTrace: $stackTrace');
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> activateArrow(String arrowId) async {
    if (state.session == null) return;

    try {
      debugPrint('🎯 GameNotifier.activateArrow: Trying to activate $arrowId');

      // CHECK FIRST: Is this arrow activatable?
      final isActivatable = state.session!.board.graph.isActivatable(arrowId);
      debugPrint('   isActivatable=$isActivatable');

      if (!isActivatable) {
        debugPrint('❌ GameNotifier: Arrow is BLOCKED, cannot fire');
        state = state.copyWith(lastFailedArrowId: arrowId);
        return; // Don't execute move
      }

      // Arrow is activatable, execute the move
      debugPrint('✅ GameNotifier: Arrow is activatable, executing move');
      final result = await activateArrowUseCase.execute(state.session!, arrowId);

      if (result.success) {
        debugPrint('✅ GameNotifier: Move executed successfully');
        state = state.copyWith(
          session: state.session,
          lastFailedArrowId: null,
        );

        if (state.session!.state is VictoryState ||
            state.session!.state is DefeatState) {
          _stopTimer();
          if (state.progress != null) {
            await saveProgressUseCase.execute(state.progress!);
          }
        }
      } else {
        // This shouldn't happen if isActivatable check passed
        debugPrint('❌ GameNotifier: Move failed unexpectedly');
        state = state.copyWith(lastFailedArrowId: arrowId);
      }
    } catch (e) {
      debugPrint('❌ GameNotifier.activateArrow: Exception - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> usePowerUp(PowerUp powerUp) async {
    if (state.session == null || state.progress == null) return;

    try {
      await usePowerUpUseCase.execute(
        state.session!,
        powerUp,
        state.progress!,
      );
      state = state.copyWith(
        session: state.session,
        progress: state.progress,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void pause() {
    if (state.session == null) return;
    pauseLevelUseCase.execute(state.session!);
    _stopTimer();
    state = state.copyWith(session: state.session);
  }

  void resume() {
    if (state.session == null) return;
    resumeLevelUseCase.execute(state.session!);
    if (state.session!.isTimedLevel()) {
      _startTimer();
    }
    state = state.copyWith(session: state.session);
  }

  Future<void> restart(String levelId, String userId) async {
    _stopTimer();
    await loadLevel(levelId, userId);
  }

  void _startTimer() {
    debugPrint('⏱️  GameNotifier._startTimer: Starting timer');
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.session != null && state.session!.isPlaying()) {
        state.session!.tick();
        state = state.copyWith(session: state.session);

        if (state.session!.isOver()) {
          _stopTimer();
        }
      }
    });
  }

  void _stopTimer() {
    debugPrint('⏱️  GameNotifier._stopTimer: Stopping timer');
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
