import '../entities/board.dart';
import '../entities/move_result.dart';
import 'i_game_state.dart';

class PlayingState implements IGameState {
  @override
  MoveResult handle(String arrowId, Board board) {
    if (!board.isActivatable(arrowId)) {
      return MoveResult.failure(arrowId);
    }
    final arrow = board.getArrows()[arrowId];
    if (arrow == null) {
      return MoveResult.failure(arrowId);
    }
    final segments = arrow.getSegments();
    board.removeArrow(arrowId);
    return MoveResult.success(arrowId, segments);
  }

  @override
  bool isPlaying() => true;

  @override
  bool isOver() => false;

  @override
  String getLabel() => 'playing';
}
