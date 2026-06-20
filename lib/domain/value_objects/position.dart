import 'direction.dart';

class Position {
  final int x;
  final int y;

  Position(this.x, this.y);

  int getX() => x;
  int getY() => y;

  Position translate(Direction direction) =>
      Position(x + direction.getDx(), y + direction.getDy());

  bool equals(Position other) => x == other.x && y == other.y;

  String toKey() => '$x,$y';
}
