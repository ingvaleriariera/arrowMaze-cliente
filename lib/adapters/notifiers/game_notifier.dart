import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrow_maze_cliente_copy/adapters/state/game_state.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/activate_arrow_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/load_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/pause_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/preload_levels_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/restart_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/resume_level_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/game/use_power_up_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/get_local_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/progress/save_progress_use_case.dart';
import 'package:arrow_maze_cliente_copy/application/usecases/score/submit_score_use_case.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/game_progress.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/infrastructure/widgets/board_painter.dart';

class GameNotifier extends StateNotifier<GameState> {
  final LoadLevelUseCase loadLevelUseCase;
  final ActivateArrowUseCase activateArrowUseCase;
  final PauseLevelUseCase pauseLevelUseCase;
  final ResumeLevelUseCase resumeLevelUseCase;
  final RestartLevelUseCase restartLevelUseCase;
  final UsePowerUpUseCase usePowerUpUseCase;
  final SaveProgressUseCase saveProgressUseCase;
  final GetLocalProgressUseCase getLocalProgressUseCase;
  final PreloadLevelsUseCase preloadLevelsUseCase;
  final SubmitScoreUseCase submitScoreUseCase;
  final bool Function() getVibrationEnabled;

  Timer? _timer;
  String? _userId;

  GameNotifier({
    required this.loadLevelUseCase,
    required this.activateArrowUseCase,
    required this.pauseLevelUseCase,
    required this.resumeLevelUseCase,
    required this.restartLevelUseCase,
    required this.usePowerUpUseCase,
    required this.saveProgressUseCase,
    required this.getLocalProgressUseCase,
    required this.preloadLevelsUseCase,
    required this.submitScoreUseCase,
    required this.getVibrationEnabled,
  }) : super(const GameState());

  Future<void> _triggerHaptic(Future<void> Function() hapticCall) async {
    try {
      if (getVibrationEnabled()) {
        await hapticCall();
      }
    } catch (e) {
      debugPrint('⚠️  GameNotifier: Haptic feedback failed - $e');
    }
  }

  Future<void> loadLevel(String levelId, String userId) async {
    debugPrint('🎮 GameNotifier.loadLevel called with: $levelId');
    _userId = userId;

    // Clear the previous session immediately so a stale VictoryState/
    // DefeatState from the last level can't be shown while this one loads.
    state = state.copyWith(isLoading: true, error: null, clearSession: true);
    debugPrint('   State set to isLoading=true, session cleared');

    try {
      debugPrint('📞 GameNotifier: Calling loadLevelUseCase.execute($levelId)');
      final session = await loadLevelUseCase.execute(levelId);

      debugPrint('✅ GameNotifier: LoadLevelUseCase returned session');
      debugPrint('   Session: levelId=${session.levelId}, maxMoves=${session.maxMoves}');

      // Progress is re-fetched on EVERY level load, never kept across
      // loads: the repository hands back the one shared instance (cheap,
      // memory-cached), which is also what Home, the lives purchase and
      // the login sync read/write. Holding a reference across the whole
      // session instead meant that whenever the cached object was
      // replaced (re-login sync, account switch), the game kept spending
      // and showing coins on a stale, disconnected copy — Home showed
      // the real balance while the in-game counter never updated.
      final progress = await getLocalProgressUseCase.execute(userId) ??
          GameProgress(userId: userId);
      debugPrint('📖 GameNotifier: Loaded progress (${progress.completedLevels.length} completed, ${progress.coins} coins)');

      debugPrint('🔄 GameNotifier: Updating state with session');
      state = state.copyWith(
        session: session,
        progress: progress,
        isLoading: false,
      );
      
      debugPrint('✅ GameNotifier.loadLevel: State updated successfully');
      debugPrint('   Current state: isLoading=${state.isLoading}, session=${state.session != null ? "exists" : "null"}');

      if (session.isTimedLevel()) {
        debugPrint('⏱️  GameNotifier: Level is timed, would start timer here');
        _startTimer();
      }

      // Fire-and-forget: warm the cache for the next couple of levels
      // while the player is busy with this one, so selecting one of them
      // next skips board generation entirely. A failure here must never
      // affect the level that just loaded successfully.
      unawaited(preloadLevelsUseCase
          .execute(_nextLevelIds(levelId, 2))
          .catchError((e) => debugPrint('⚠️  GameNotifier: Preload failed — $e')));
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
        debugPrint('❌ GameNotifier: Arrow is BLOCKED, deducting move');

        // Haptic feedback for blocked arrow
        await _triggerHaptic(() => HapticFeedback.mediumImpact());

        // Deduct move even though arrow is blocked
        state.session!.failedMoves++;
        state.session!.deductMove();

        // Start flash
        final newFlashMap = Map<String, FlashType>.from(state.flashMap);
        newFlashMap[arrowId] = FlashType.fail;
        state = state.copyWith(flashMap: newFlashMap, session: state.session);

        // Remove flash after 500ms
        await Future.delayed(const Duration(milliseconds: 500));
        final updatedFlashMap = Map<String, FlashType>.from(state.flashMap);
        updatedFlashMap.remove(arrowId);
        state = state.copyWith(flashMap: updatedFlashMap);

        // Check if game is over after deducting move
        if (!state.session!.isPlaying()) {
          debugPrint('🎯 GameNotifier: Game over after deducting move (blocked arrow attempt)');
        }

        return; // Don't execute move
      }

      // CHECK FOR VOID RE-ENTRY: Even if activatable, check if blocked by void re-entry
      final hasVoidReentry = state.session!.board.graph.hasVoidReentry(arrowId, state.session!.board.arrows, state.session!.board.grid, state.session!.board.shape);
      if (hasVoidReentry) {
        debugPrint('❌ GameNotifier: Arrow is BLOCKED by void re-entry, deducting move');

        // Haptic feedback for blocked arrow
        await _triggerHaptic(() => HapticFeedback.mediumImpact());

        // Deduct move even though arrow is blocked
        state.session!.failedMoves++;
        state.session!.deductMove();

        // Start flash
        final newFlashMap = Map<String, FlashType>.from(state.flashMap);
        newFlashMap[arrowId] = FlashType.fail;
        state = state.copyWith(flashMap: newFlashMap, session: state.session);

        // Remove flash after 500ms
        await Future.delayed(const Duration(milliseconds: 500));
        final updatedFlashMap = Map<String, FlashType>.from(state.flashMap);
        updatedFlashMap.remove(arrowId);
        state = state.copyWith(flashMap: updatedFlashMap);

        // Check if game is over after deducting move
        if (!state.session!.isPlaying()) {
          debugPrint('🎯 GameNotifier: Game over after deducting move (void re-entry attempt)');
        }

        return; // Don't execute move
      }

      // Arrow is activatable, execute the move
      debugPrint('✅ GameNotifier: Arrow is activatable, executing move');
      final result = await activateArrowUseCase.execute(state.session!, arrowId);

      if (result.success) {
        debugPrint('✅ GameNotifier: Move executed successfully');
        state = state.copyWith(session: state.session);
        await _handleSessionOverIfNeeded();
      } else {
        // This shouldn't happen if isActivatable check passed
        debugPrint('❌ GameNotifier: Move failed unexpectedly');

        final newFlashMap = Map<String, FlashType>.from(state.flashMap);
        newFlashMap[arrowId] = FlashType.fail;
        state = state.copyWith(flashMap: newFlashMap);

        await Future.delayed(const Duration(milliseconds: 500));
        final updatedFlashMap = Map<String, FlashType>.from(state.flashMap);
        updatedFlashMap.remove(arrowId);
        state = state.copyWith(flashMap: updatedFlashMap);
      }
    } catch (e) {
      debugPrint('❌ GameNotifier.activateArrow: Exception - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<PowerUpResult?> usePowerUp(PowerUp powerUp) async {
    if (state.session == null || state.progress == null) return null;

    try {
      final result = await usePowerUpUseCase.execute(
        state.session!,
        powerUp,
        state.progress!,
      );
      state = state.copyWith(
        session: state.session,
        progress: state.progress,
      );
      if (result.success) {
        await _handleSessionOverIfNeeded();
      }
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Shared victory/defeat post-processing for anything that can end the
  /// game — a normal move (activateArrow) or a power-up that empties or
  /// deadlocks the board (Hammer/Magnet). Stops the timer, records level
  /// completion (this is what actually unlocks the next level), and
  /// persists progress.
  Future<void> _handleSessionOverIfNeeded() async {
    if (state.session!.state is VictoryState || state.session!.state is DefeatState) {
      _stopTimer();

      if (state.session!.state is VictoryState) {
        // Haptic feedback for level completed (three strong impacts)
        await _triggerHaptic(() => HapticFeedback.heavyImpact());
        await Future.delayed(const Duration(milliseconds: 100));
        await _triggerHaptic(() => HapticFeedback.heavyImpact());
        await Future.delayed(const Duration(milliseconds: 100));
        await _triggerHaptic(() => HapticFeedback.heavyImpact());

        state.session!.calculateFinalScore();
        final progress = state.progress ?? GameProgress(userId: _userId ?? state.session!.levelId);
        progress.recordCompletion(state.session!.levelId, state.session!.score);
        debugPrint('🏆 GameNotifier: Recorded completion of ${state.session!.levelId} (score: ${state.session!.score})');
        state = state.copyWith(progress: progress);

        // Feeds the per-level leaderboard (score_entries on the backend) —
        // separate from progress/sync below, which only feeds PlayerProgress
        // (used for the global leaderboard). A failure here shouldn't block
        // the victory screen, same reasoning as the background progress sync
        // in AuthNotifier.
        if (_userId != null) {
          try {
            await submitScoreUseCase.execute(_userId!, state.session!.levelId, state.session!.score);
            debugPrint('🏆 GameNotifier: Score submitted to leaderboard');
          } catch (e) {
            debugPrint('⚠️  GameNotifier: Score submission failed (non-blocking) - $e');
          }
        }
      }

      if (state.progress != null) {
        await saveProgressUseCase.execute(state.progress!);
      }
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
          // Running out of time must close the session the same way a
          // deadlock or out-of-moves defeat does (save progress etc.) —
          // this is the only game-over that doesn't come from executeMove.
          unawaited(_handleSessionOverIfNeeded());
        }
      }
    });
  }

  /// For screens leaving mid-game (e.g. iOS swipe-back out of GameScreen):
  /// without this, a timed session keeps ticking in the background and can
  /// "lose" a level the player already walked away from.
  void stopTimer() => _stopTimer();

  void _stopTimer() {
    debugPrint('⏱️  GameNotifier._stopTimer: Stopping timer');
    _timer?.cancel();
    _timer = null;
  }

  /// Next [count] level ids following [levelId], assuming the
  /// `level-NNN` zero-padded sequential naming used across the app
  /// (level select sorts on the same convention). Best-effort: ids past
  /// the last seeded level simply won't be found by PreloadLevelsUseCase
  /// and are silently skipped there.
  List<String> _nextLevelIds(String levelId, int count) {
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(levelId);
    if (match == null) return [];

    final prefix = match.group(1)!;
    final digits = match.group(2)!;
    final number = int.parse(digits);

    return List.generate(count, (i) {
      final next = number + i + 1;
      return '$prefix${next.toString().padLeft(digits.length, '0')}';
    });
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
