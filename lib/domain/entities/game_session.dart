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
    // SIEMPRE incrementar movimientos (exitoso o no)
    moves++;

    final result = state.handle(arrowId, board);

    if (result.isSuccess()) {
      // Flecha activable: sumar puntos por segmentos
      score += result.getExitedSegments().length * 10;
      if (board.isEmpty()) {
        state = VictoryState();
      }
    } else {
      // Flecha bloqueada: restar 5 puntos
      score = (score - 5).clamp(0, 999999);
    }

    // Verificar derrota por movimientos
    if (moves >= maxMoves && state.getLabel() == 'playing') {
      state = DefeatState();
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
