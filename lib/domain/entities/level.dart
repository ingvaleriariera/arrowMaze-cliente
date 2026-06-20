import '../value_objects/board_shape.dart';
import '../value_objects/time_limit.dart';

class Level {
  final String id;
  final String difficulty;
  final String boardLayout;
  final int moveLimit;
  final TimeLimit? timeLimit;

  Level(this.id, this.difficulty, this.boardLayout, this.moveLimit, this.timeLimit);

  String getId() => id;
  BoardShape getBoardShape() => BoardShape.fromJson(boardLayout);
  int getMoveLimit() => moveLimit;
  String getDifficulty() => difficulty;
  String getBoardLayout() => boardLayout;
  TimeLimit? getTimeLimit() => timeLimit;
  bool isTimed() => timeLimit != null && timeLimit!.hasLimit();
}
