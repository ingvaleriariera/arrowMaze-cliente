import '../value_objects/direction.dart';
import '../value_objects/position.dart';

class ArrowSegment {
  final Position position;
  final Direction directionToNext;

  ArrowSegment(this.position, this.directionToNext);

  Position getPosition() => position;
  Direction getDirectionToNext() => directionToNext;
}
