import 'direction.dart';

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  Position translate(Direction direction) =>
      Position(x + direction.dx, y + direction.dy);

  String toKey() => '$x,$y';

  bool equals(Position other) => x == other.x && y == other.y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && equals(other);

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Position(x: $x, y: $y)';
}
