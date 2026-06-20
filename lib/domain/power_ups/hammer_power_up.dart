import '../entities/board.dart';
import 'power_up.dart';

class HammerPowerUp extends PowerUp {
  final String targetArrowId;

  HammerPowerUp(this.targetArrowId);

  @override
  bool canApply(Board board) => board.getArrows().containsKey(targetArrowId);

  @override
  void apply(Board board) {
    board.forceRemoveArrow(targetArrowId);
  }

  @override
  int getCost() => 30;

  @override
  String getType() => 'hammer';
}
