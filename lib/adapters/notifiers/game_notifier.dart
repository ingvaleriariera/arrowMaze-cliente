import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../application/use_cases/game/activate_arrow_use_case.dart';
import '../../application/use_cases/game/load_level_use_case.dart';
import '../../application/use_cases/game/pause_level_use_case.dart';
import '../../application/use_cases/game/restart_level_use_case.dart';
import '../../application/use_cases/game/resume_level_use_case.dart';
import '../../application/use_cases/power_ups/use_power_up_use_case.dart';
import '../../application/use_cases/progress/get_local_progress_use_case.dart';
import '../../application/use_cases/progress/save_progress_use_case.dart';
import '../../application/use_cases/progress/sync_progress_use_case.dart';
import '../../domain/entities/game_progress.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/power_ups/hammer_power_up.dart';
import '../../domain/power_ups/hint_power_up.dart';
import '../../domain/power_ups/magnet_power_up.dart';
import '../../domain/power_ups/power_up.dart';
import '../../domain/value_objects/direction.dart';

class GameState {
  final GameSession? session;
  final GameProgress? progress;

  const GameState({this.session, this.progress});

  GameState copyWith({GameSession? session, GameProgress? progress}) {
    return GameState(
      session: session ?? this.session,
      progress: progress ?? this.progress,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final LoadLevelUseCase loadLevelUseCase;
  final ActivateArrowUseCase activateArrowUseCase;
  final PauseLevelUseCase pauseUseCase;
  final ResumeLevelUseCase resumeUseCase;
  final RestartLevelUseCase restartUseCase;
  final UsePowerUpUseCase usePowerUpUseCase;
  final SaveProgressUseCase saveProgressUseCase;
  final SyncProgressUseCase syncProgressUseCase;
  final GetLocalProgressUseCase getProgressUseCase;

  String? _userId;
  String? _levelId;
  Timer? _timer;

  // Evita que una carga de nivel obsoleta (resuelta fuera de orden si el
  // usuario navega entre niveles rápido) sobrescriba la sesión actual.
  int _loadRequestId = 0;

  GameNotifier(
    this.loadLevelUseCase,
    this.activateArrowUseCase,
    this.pauseUseCase,
    this.resumeUseCase,
    this.restartUseCase,
    this.usePowerUpUseCase,
    this.saveProgressUseCase,
    this.syncProgressUseCase,
    this.getProgressUseCase,
  ) : super(const GameState());

  Future<void> loadLevel(String levelId, {String? userId}) async {
    final requestId = ++_loadRequestId;
    final session = await loadLevelUseCase.execute(levelId);
    final progress = userId != null ? await getProgressUseCase.execute(userId) : null;
    // Si se pidió otra carga mientras esta estaba en vuelo, se descarta:
    // ya no representa el nivel que el usuario está viendo.
    if (requestId != _loadRequestId) return;
    _levelId = levelId;
    _userId = userId;
    state = GameState(session: session, progress: progress);
    if (session.isTimedLevel()) {
      _startTimer();
    }
  }

  void activateArrow(String arrowId) {
    final session = state.session;
    if (session == null) return;
    activateArrowUseCase.execute(session, arrowId);
    state = state.copyWith(session: session);
    if (session.isOver()) {
      _stopTimer();
      _onLevelOver(session);
    }
  }

  Future<void> useHint() => _applyPowerUp(HintPowerUp());

  Future<void> useHammer(String arrowId) => _applyPowerUp(HammerPowerUp(arrowId));

  Future<void> useMagnet(Direction direction) => _applyPowerUp(MagnetPowerUp(direction));

  void pause() {
    final session = state.session;
    if (session == null) return;
    pauseUseCase.execute(session);
    _stopTimer();
    state = state.copyWith(session: session);
  }

  void resume() {
    final session = state.session;
    if (session == null) return;
    resumeUseCase.execute(session);
    if (session.isTimedLevel()) {
      _startTimer();
    }
    state = state.copyWith(session: session);
  }

  Future<void> restart() async {
    final levelId = _levelId;
    if (levelId == null) return;
    _stopTimer();
    final session = await restartUseCase.execute(levelId);
    state = state.copyWith(session: session);
    if (session.isTimedLevel()) {
      _startTimer();
    }
  }

  Future<void> _applyPowerUp(PowerUp powerUp) async {
    final session = state.session;
    final progress = state.progress;
    if (session == null || progress == null) return;
    await usePowerUpUseCase.execute(session, powerUp, progress);
    state = state.copyWith(session: session, progress: progress);
  }

  void _onLevelOver(GameSession session) {
    final progress = state.progress;
    final userId = _userId;
    final levelId = _levelId;
    if (progress == null || userId == null || levelId == null) return;
    if (session.getState().getLabel() == 'victory') {
      progress.recordCompletion(levelId, session.getScore());
      saveProgressUseCase.execute(progress);
      syncProgressUseCase.execute(userId);
    }
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = state.session;
      if (session == null) return;
      session.tick();
      state = state.copyWith(session: session);
      if (session.isOver()) {
        _stopTimer();
        _onLevelOver(session);
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
