import '../engine/board_graph.dart';
import '../entities/arrow.dart';
import '../entities/board.dart';
import '../entities/level.dart';

class LevelValidator {
  bool validate(Level level) {
    if (level.getId().isEmpty) return false;
    if (level.getMoveLimit() <= 0) return false;
    try {
      level.getBoardShape();
    } catch (_) {
      return false;
    }
    return true;
  }

  bool isSolvable(Board board) {
    final remaining = Map<String, Arrow>.from(board.getArrows());
    final graph = BoardGraph();
    graph.build(remaining, board.getShape());
    while (remaining.isNotEmpty) {
      final activatable = graph.getActivatable();
      if (activatable.isEmpty) return false;
      final arrowId = activatable.first;
      remaining.remove(arrowId);
      graph.removeArrow(arrowId);
    }
    return true;
  }
}
