import '../entities/board.dart';
import '../value_objects/direction.dart';
import 'power_up.dart';

class MagnetPowerUp extends PowerUp {
  final Direction direction;

  MagnetPowerUp(this.direction);

  @override
  bool canApply(Board board) => _matchingArrows(board).isNotEmpty;

  @override
  void apply(Board board) {
    for (final arrowId in _matchingArrows(board)) {
      board.removeArrow(arrowId);
    }
  }

  @override
  int getCost() => 50;

  @override
  String getType() => 'magnet';

  List<String> _matchingArrows(Board board) {
    return board.getActivatableArrows().where((arrowId) {
      final arrow = board.getArrows()[arrowId];
      return arrow != null && arrow.getDirection().equals(direction);
    }).toList();
  }
}
