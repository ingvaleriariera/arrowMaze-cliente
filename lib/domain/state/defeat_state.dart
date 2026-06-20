import '../entities/board.dart';
import '../entities/move_result.dart';
import 'i_game_state.dart';

class DefeatState implements IGameState {
  @override
  MoveResult handle(String arrowId, Board board) => MoveResult.failure(arrowId);

  @override
  bool isPlaying() => false;

  @override
  bool isOver() => true;

  @override
  String getLabel() => 'defeat';
}
