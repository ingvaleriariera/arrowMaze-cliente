import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

class Level {
  final String id;
  final String difficulty;
  final String boardLayout;
  final int moveLimit;
  final TimeLimit timeLimit;

  Level({
    required this.id,
    required this.difficulty,
    required this.boardLayout,
    required this.moveLimit,
    required this.timeLimit,
  });

  BoardShape getBoardShape() => BoardShape.fromJson(boardLayout);

  bool isTimed() => timeLimit.hasLimit();

  @override
  String toString() =>
      'Level(id: $id, difficulty: $difficulty, moveLimit: $moveLimit)';
}
