import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';

class MagnetPowerUp extends PowerUp {
  static const int maxArrowsRemoved = 5;

  @override
  bool canApply(Board board) => board.getActivatableArrows().isNotEmpty;

  List<String> _targets(Board board) =>
      board.getActivatableArrows().take(maxArrowsRemoved).toList();

  @override
  void apply(Board board) {
    for (final arrowId in _targets(board)) {
      board.removeArrow(arrowId);
    }
  }

  @override
  PowerUpResult use(Board board) {
    if (!canApply(board)) {
      return PowerUpResult.applyFailure('No activatable arrows available');
    }

    final targets = _targets(board);
    apply(board);
    return PowerUpResult.applySuccess(
      'Removed ${targets.length} arrow(s) with magnet',
      affectedArrowIds: targets,
    );
  }

  @override
  int getCost() => 500;

  @override
  String getType() => 'MAGNET';
}
