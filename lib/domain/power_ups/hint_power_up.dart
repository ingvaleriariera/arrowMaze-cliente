import '../entities/board.dart';
import 'power_up.dart';

class HintPowerUp extends PowerUp {
  @override
  bool canApply(Board board) => board.getHint() != null;

  @override
  void apply(Board board) {
    board.getHint();
  }

  @override
  int getCost() => 10;

  @override
  String getType() => 'hint';
}
