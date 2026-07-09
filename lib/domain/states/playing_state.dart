import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/states/i_game_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

class PlayingState implements IGameState {
  @override
  MoveResult handle(String arrowId, Board board) {
    if (!board.isActivatable(arrowId)) {
      return MoveResult.exitFailure(arrowId);
    }

    if (board.graph.hasVoidReentry(arrowId, board.arrows, board.grid, board.shape)) {
      return MoveResult.exitFailure(arrowId);
    }

    final arrow = board.arrows[arrowId];
    if (arrow == null) {
      return MoveResult.exitFailure(arrowId);
    }

    final segments = arrow.segments;
    board.removeArrow(arrowId);
    return MoveResult.exitSuccess(arrowId, segments);
  }

  @override
  bool isPlaying() => true;

  @override
  bool isOver() => false;

  @override
  String getLabel() => 'PLAYING';
}
