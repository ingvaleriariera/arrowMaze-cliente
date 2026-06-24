import 'dart:async';
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
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';

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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final session = await loadLevelUseCase.execute(levelId);
      // Load progress from local storage (in a real app)
      state = state.copyWith(
        session: session,
        isLoading: false,
      );

      if (session.isTimedLevel()) {
        _startTimer();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> activateArrow(String arrowId) async {
    if (state.session == null) return;

    try {
      final result = await activateArrowUseCase.execute(state.session!, arrowId);

      if (result.success) {
        state = state.copyWith(
          session: state.session,
        );

        if (state.session!.state is VictoryState ||
            state.session!.state is DefeatState) {
          _stopTimer();
          if (state.progress != null) {
            await saveProgressUseCase.execute(state.progress!);
          }
        }
      }
    } catch (e) {
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
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
