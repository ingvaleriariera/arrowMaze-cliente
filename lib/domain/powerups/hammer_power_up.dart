import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';

class HammerPowerUp extends PowerUp {
  final String targetArrowId;

  HammerPowerUp({required this.targetArrowId});

  @override
  bool canApply(Board board) {
    return board.arrows.containsKey(targetArrowId);
  }

  @override
  void apply(Board board) {
    board.forceRemoveArrow(targetArrowId);
  }

  @override
  PowerUpResult use(Board board) {
    if (!canApply(board)) {
      return PowerUpResult.applyFailure('Target arrow not found');
    }

    apply(board);
    return PowerUpResult.applySuccess(
      'Arrow destroyed with hammer',
      affectedArrowId: targetArrowId,
    );
  }

  @override
  int getCost() => 30;

  @override
  String getType() => 'HAMMER';
}
