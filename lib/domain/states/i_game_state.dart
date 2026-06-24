import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/move_result.dart';

abstract class IGameState {
  MoveResult handle(String arrowId, Board board);
  bool isPlaying();
  bool isOver();
  String getLabel();
}
