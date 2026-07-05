import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';

class HintPowerUp extends PowerUp {
  @override
  bool canApply(Board board) {
    return board.getHint() != null;
  }

  @override
  void apply(Board board) {
    // Hint doesn't modify the board, just provides information
  }

  @override
  PowerUpResult use(Board board) {
    if (!canApply(board)) {
      return PowerUpResult.applyFailure('No activatable arrows available');
    }

    final hint = board.getHint();
    apply(board);
    return PowerUpResult.applySuccess(
      'Hint revealed',
      affectedArrowIds: [hint!],
    );
  }

  @override
  int getCost() => 100;

  @override
  String getType() => 'HINT';
}
