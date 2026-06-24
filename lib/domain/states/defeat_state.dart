import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/states/i_game_state.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

class DefeatState implements IGameState {
  final String reason;

  DefeatState({this.reason = 'UNKNOWN'});

  @override
  MoveResult handle(String arrowId, Board board) {
    return MoveResult.exitFailure(arrowId);
  }

  @override
  bool isPlaying() => false;

  @override
  bool isOver() => true;

  @override
  String getLabel() => 'DEFEAT ($reason)';
}
