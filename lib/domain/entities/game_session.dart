import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/ports/i_game_observer.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';
import 'package:arrow_maze_cliente_copy/domain/states/defeat_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/i_game_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/paused_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/playing_state.dart';
import 'package:arrow_maze_cliente_copy/domain/states/victory_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

class GameSession {
  final Board board;
  final String levelId;
  final int maxMoves;
  final int maxScore;
  int moves = 0;
  int failedMoves = 0;
  int score = 0;
  int? timeRemaining;

  IGameState _state;

  // Observer pattern: Subject (GameSession) notifies these observers
  final List<IGameObserver> _observers = [];

  GameSession({
    required this.board,
    required this.levelId,
    required this.maxMoves,
    this.timeRemaining,
  }) : maxScore = ((board.arrows.values.fold<int>(0, (sum, arrow) => sum + (arrow.segments.length * 10)) + 50) ~/ 100) * 100,
       _state = PlayingState();

  IGameState get state => _state;

  // Observer management (Subject interface)
  void addObserver(IGameObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  void removeObserver(IGameObserver observer) {
    _observers.remove(observer);
  }

  // Private notification methods (Observer pattern dispatch)
  void _notifyPlayerMoved(MoveResult result) {
    for (final observer in _observers) {
      observer.onPlayerMoved(result);
    }
  }

  void _notifyScoreUpdated() {
    for (final observer in _observers) {
      observer.onScoreUpdated(score);
    }
  }

  void _notifyLevelCompleted(bool success) {
    for (final observer in _observers) {
      observer.onLevelCompleted(success, score);
    }
  }

  MoveResult executeMove(String arrowId) {
    final result = _state.handle(arrowId, board);

    if (result.success) {
      moves++;
      final previousScore = score;
      score += 10 * result.exitedSegments.length;

      // Notify player moved (regardless of score change, as board state changed)
      _notifyPlayerMoved(result);

      // Notify score updated if score actually changed
      if (score != previousScore) {
        _notifyScoreUpdated();
      }

      // Check for victory
      if (board.isEmpty()) {
        _state = VictoryState();
        _notifyLevelCompleted(true);
        return result;
      }

      // Check for deadlock (no activatable arrows)
      if (board.getActivatableArrows().isEmpty) {
        _state = DefeatState(reason: 'DEADLOCK');
        _notifyLevelCompleted(false);
        return result;
      }

      // Check for defeat by moves
      if (moves >= maxMoves) {
        _state = DefeatState(reason: 'OUT_OF_MOVES');
        _notifyLevelCompleted(false);
        return result;
      }
    } else {
      // Failed move
      failedMoves++;
      _notifyPlayerMoved(result);
    }

    return result;
  }

  void deductMove() {
    moves++;

    // Check for defeat by moves after deducting move
    if (moves >= maxMoves) {
      _state = DefeatState(reason: 'OUT_OF_MOVES');
      _notifyLevelCompleted(false);
    }
  }

  void pause() {
    if (_state is PlayingState) {
      _state = PausedState();
    }
  }

  void resume() {
    if (_state is PausedState) {
      _state = PlayingState();
    }
  }

  void tick() {
    if (isTimedLevel() && timeRemaining != null) {
      timeRemaining = timeRemaining! - 1;
      if (timeRemaining! <= 0) {
        _state = DefeatState(reason: 'TIME_UP');
        _notifyLevelCompleted(false);
      }
    }
  }

  PowerUpResult applyPowerUp(PowerUp powerUp) {
    final result = powerUp.use(board);

    // Hammer/Magnet remove arrows directly on the board, bypassing
    // executeMove() — without redoing its post-move checks here, clearing
    // the board (or deadlocking it) via a power-up would never transition
    // out of PlayingState.
    if (result.success) {
      if (board.isEmpty()) {
        _state = VictoryState();
        _notifyLevelCompleted(true);
      } else if (board.getActivatableArrows().isEmpty) {
        _state = DefeatState(reason: 'DEADLOCK');
        _notifyLevelCompleted(false);
      }
    }

    return result;
  }

  void calculateFinalScore() {
    if (_state is! VictoryState) return;
    final accuracy = moves > 0 ? (moves - failedMoves) / moves : 1.0;
    score = (maxScore * accuracy).toInt().clamp(0, maxScore);
  }

  bool isOver() => _state.isOver();

  bool isPlaying() => _state.isPlaying();

  bool isTimedLevel() => timeRemaining != null;

  @override
  String toString() =>
      'GameSession(level: $levelId, moves: $moves/$maxMoves, score: $score, state: ${_state.getLabel()})';
}
