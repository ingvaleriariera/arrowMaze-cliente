import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';

abstract class PowerUp {
  PowerUpResult use(Board board) {
    if (!canApply(board)) {
      return PowerUpResult.applyFailure('Cannot apply this power-up');
    }

    apply(board);
    return PowerUpResult.applySuccess(
      'Applied ${getType()}',
    );
  }

  bool canApply(Board board) => true;

  void apply(Board board);

  int getCost();

  String getType();
}
