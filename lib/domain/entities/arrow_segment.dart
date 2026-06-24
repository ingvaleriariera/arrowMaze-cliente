import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class ArrowSegment {
  final Position position;
  final Direction directionToNext;

  const ArrowSegment({
    required this.position,
    required this.directionToNext,
  });

  @override
  String toString() =>
      'ArrowSegment(position: $position, direction: $directionToNext)';
}
