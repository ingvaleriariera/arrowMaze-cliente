import '../entities/board.dart';
import '../entities/power_up_result.dart';

abstract class PowerUp {
  PowerUpResult use(Board board) {
    if (!canApply(board)) {
      return PowerUpResult.failure('Cannot apply');
    }
    apply(board);
    return PowerUpResult.success(null);
  }

  bool canApply(Board board) => true;

  void apply(Board board);

  int getCost();

  String getType();
}
