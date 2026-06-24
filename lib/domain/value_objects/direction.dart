class Direction {
  final int dx;
  final int dy;

  const Direction._(this.dx, this.dy);

  static const Direction up = Direction._(0, -1);
  static const Direction down = Direction._(0, 1);
  static const Direction left = Direction._(-1, 0);
  static const Direction right = Direction._(1, 0);

  Direction opposite() {
    if (this == up) return down;
    if (this == down) return up;
    if (this == left) return right;
    if (this == right) return left;
    return this;
  }

  bool equals(Direction other) => dx == other.dx && dy == other.dy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Direction && equals(other);

  @override
  int get hashCode => Object.hash(dx, dy);

  @override
  String toString() => 'Direction(dx: $dx, dy: $dy)';
}
