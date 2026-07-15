import 'direction.dart';

class Position {
  final int x;
  final int y;

  /// Depth coordinate for 3D boards (extruded prisms). Defaults to 0 so
  /// every existing 2D call site keeps working unchanged.
  final int z;

  const Position(this.x, this.y, [this.z = 0]);

  Position translate(Direction direction) =>
      Position(x + direction.dx, y + direction.dy, z + direction.dz);

  /// Canonical key: "x,y" for the base layer and "x,y,z" above it. Keeping
  /// the 2-part form for z=0 is deliberate — it's the exact format produced
  /// by BoardShape.fromJson, the tap handler and the board editor, so the
  /// whole existing 2D pipeline keeps matching without touching a single
  /// key producer.
  String toKey() => z == 0 ? '$x,$y' : '$x,$y,$z';

  /// Inverse of [toKey]: accepts both the 2-part (z=0) and 3-part forms.
  static Position fromKey(String key) {
    final parts = key.split(',');
    return Position(
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }

  bool equals(Position other) => x == other.x && y == other.y && z == other.z;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && equals(other);

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Position(x: $x, y: $y, z: $z)';
}
