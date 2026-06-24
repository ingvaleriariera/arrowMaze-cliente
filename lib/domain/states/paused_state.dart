import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/states/i_game_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

class PausedState implements IGameState {
  @override
  MoveResult handle(String arrowId, Board board) {
    return MoveResult.exitFailure(arrowId);
  }

  @override
  bool isPlaying() => false;

  @override
  bool isOver() => false;

  @override
  String getLabel() => 'PAUSED';
}
