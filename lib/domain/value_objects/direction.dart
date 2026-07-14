class Direction {
  final int dx;
  final int dy;

  /// Depth component for 3D boards: [forward] dives into the prism,
  /// [back] comes out of it. The four planar directions keep dz=0, so all
  /// existing 2D logic is untouched.
  final int dz;

  const Direction._(this.dx, this.dy, [this.dz = 0]);

  static const Direction up = Direction._(0, -1);
  static const Direction down = Direction._(0, 1);
  static const Direction left = Direction._(-1, 0);
  static const Direction right = Direction._(1, 0);
  static const Direction forward = Direction._(0, 0, 1);
  static const Direction back = Direction._(0, 0, -1);

  /// The four planar directions — what 2D boards use.
  static const List<Direction> planar = [up, down, left, right];

  /// All six cell connections — what extruded (3D) boards use.
  static const List<Direction> all = [up, down, left, right, forward, back];

  Direction opposite() {
    if (this == up) return down;
    if (this == down) return up;
    if (this == left) return right;
    if (this == right) return left;
    if (this == forward) return back;
    if (this == back) return forward;
    return this;
  }

  bool equals(Direction other) =>
      dx == other.dx && dy == other.dy && dz == other.dz;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Direction && equals(other);

  @override
  int get hashCode => Object.hash(dx, dy, dz);

  @override
  String toString() => 'Direction(dx: $dx, dy: $dy, dz: $dz)';
}
