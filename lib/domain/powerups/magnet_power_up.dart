import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up.dart';
import 'package:arrow_maze_cliente_copy/domain/powerups/power_up_result.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';

class MagnetPowerUp extends PowerUp {
  final Direction direction;

  MagnetPowerUp({required this.direction});

  @override
  bool canApply(Board board) {
    final activatable = board.getActivatableArrows();
    return activatable.any((arrowId) {
      final arrow = board.arrows[arrowId];
      return arrow != null && arrow.getDirection() == direction;
    });
  }

  @override
  void apply(Board board) {
    final activatable = board.getActivatableArrows();
    final toRemove = <String>[
      for (final arrowId in activatable)
        if (board.arrows[arrowId]?.getDirection() == direction) arrowId
    ];

    for (final arrowId in toRemove) {
      board.removeArrow(arrowId);
    }
  }

  @override
  int getCost() => 20;

  @override
  String getType() => 'MAGNET';
}
