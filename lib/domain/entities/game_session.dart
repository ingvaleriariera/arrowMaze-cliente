import '../power_ups/power_up.dart';
import '../state/defeat_state.dart';
import '../state/i_game_state.dart';
import '../state/paused_state.dart';
import '../state/playing_state.dart';
import '../state/victory_state.dart';
import '../value_objects/time_limit.dart';
import 'board.dart';
import 'move_result.dart';
import 'power_up_result.dart';

class GameSession {
  final Board board;
  final String levelId;
  int score = 0;
  int moves = 0;
  final int maxMoves;
  int? timeRemaining;
  IGameState state = PlayingState();

  GameSession(this.board, this.levelId, this.maxMoves, TimeLimit? timeLimit) {
    if (timeLimit != null && timeLimit.hasLimit()) {
      timeRemaining = timeLimit.getValue();
    }
  }

  MoveResult executeMove(String arrowId) {
    final result = state.handle(arrowId, board);
    if (result.isSuccess()) {
      moves++;
      score += result.getExitedSegments().length;
      if (board.isEmpty()) {
        state = VictoryState();
      } else if (moves >= maxMoves) {
        state = DefeatState();
      }
    }
    return result;
  }

  PowerUpResult applyPowerUp(PowerUp powerUp) => powerUp.use(board);

  void pause() {
    if (state.isPlaying()) {
      state = PausedState();
    }
  }

  void resume() {
    if (state is PausedState) {
      state = PlayingState();
    }
  }

  void tick() {
    if (!state.isPlaying() || timeRemaining == null) return;
    timeRemaining = timeRemaining! - 1;
    if (timeRemaining! <= 0) {
      state = DefeatState();
    }
  }

  Board getBoard() => board;
  int getScore() => score;
  int getMoves() => moves;
  IGameState getState() => state;
  bool isOver() => state.isOver();
  bool isTimedLevel() => timeRemaining != null;
}
