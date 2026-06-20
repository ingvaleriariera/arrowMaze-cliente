import '../entities/board.dart';
import '../entities/move_result.dart';

abstract class IGameState {
  MoveResult handle(String arrowId, Board board);
  bool isPlaying();
  bool isOver();
  String getLabel();
}
