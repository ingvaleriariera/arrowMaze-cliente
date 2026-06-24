import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
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
  int moves = 0;
  int score = 0;
  int? timeRemaining;

  IGameState _state;

  GameSession({
    required this.board,
    required this.levelId,
    required this.maxMoves,
    this.timeRemaining,
  }) : _state = PlayingState();

  IGameState get state => _state;

  MoveResult executeMove(String arrowId) {
    final result = _state.handle(arrowId, board);

    if (result.success) {
      moves++;
      score += 10 * result.exitedSegments.length;

      // Check for victory
      if (board.isEmpty()) {
        _state = VictoryState();
        return result;
      }

      // Check for deadlock (no activatable arrows)
      if (board.getActivatableArrows().isEmpty) {
        _state = DefeatState(reason: 'DEADLOCK');
        return result;
      }

      // Check for defeat by moves
      if (moves >= maxMoves) {
        _state = DefeatState(reason: 'OUT_OF_MOVES');
        return result;
      }
    } else {
      // Failed move
      score = (score - 5).clamp(0, 999999);
    }

    return result;
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
      }
    }
  }

  PowerUpResult applyPowerUp(PowerUp powerUp) {
    return powerUp.use(board);
  }

  bool isOver() => _state.isOver();

  bool isPlaying() => _state.isPlaying();

  bool isTimedLevel() => timeRemaining != null;

  @override
  String toString() =>
      'GameSession(level: $levelId, moves: $moves/$maxMoves, score: $score, state: ${_state.getLabel()})';
}
