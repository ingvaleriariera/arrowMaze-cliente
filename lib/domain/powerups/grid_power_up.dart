import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';

/// Reveals every arrow's exit direction at once. Purely informational —
/// unlike Hint (which points at one arrow via [PowerUpResult]), the caller
/// already has the full [Board] and can read each arrow's own head/direction
/// directly, so there's nothing for apply() to compute or mutate.
class GridPowerUp extends PowerUp {
  @override
  void apply(Board board) {
    // No-op: showing the grid overlay is a rendering concern, not a
    // domain mutation.
  }

  @override
  int getCost() => 50;

  @override
  String getType() => 'GRID';
}
