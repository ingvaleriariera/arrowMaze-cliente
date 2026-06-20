class Direction {
  final int dx;
  final int dy;

  Direction._(this.dx, this.dy);

  static Direction up() => Direction._(0, -1);
  static Direction down() => Direction._(0, 1);
  static Direction left() => Direction._(-1, 0);
  static Direction right() => Direction._(1, 0);

  int getDx() => dx;
  int getDy() => dy;

  Direction opposite() => Direction._(-dx, -dy);

  bool equals(Direction other) => dx == other.dx && dy == other.dy;
}
