import 'dart:math';
import 'dart:ui';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

/// Pixel math for a pointy-top hexagonal board addressed by
/// axial coordinates (x=q, y=r), matching the 6 neighbor deltas in
/// Direction.hexAll: [+1,0] [+1,-1] [0,-1] [-1,0] [-1,+1] [0,+1].
///
/// Formulas are the standard axial<->pixel conversion for pointy-top
/// hexagons (see redblobgames.com/grids/hexagons — the reference every
/// hex-grid implementation traces back to). Kept as a standalone
/// projection (mirrors BoardProjection's role for the cascade 3D view)
/// so painting and hit-testing always agree on the same math.
class HexProjection {
  static const double _sqrt3 = 1.7320508075688772;

  /// Distance from a hex's center to any of its 6 corners.
  final double hexSize;

  const HexProjection({required this.hexSize});

  /// Pixel center of a cell, in an unbounded coordinate space centered on
  /// axial (0,0) — callers translate by [originOffset] to fit a canvas.
  Offset centerOf(Position pos) => centerOfFractional(pos.x.toDouble(), pos.y.toDouble());

  /// Same as [centerOf] but accepts fractional axial coordinates — used by
  /// the exit animation, which interpolates a snake's body between cells
  /// (and beyond the last one, off the board) frame by frame.
  Offset centerOfFractional(double q, double r) => Offset(
        hexSize * (_sqrt3 * q + _sqrt3 / 2 * r),
        hexSize * (1.5 * r),
      );

  /// The 6 corners of the hexagon centered at [center], pointy-top
  /// orientation (a corner straight up, not a flat edge).
  List<Offset> cornersOf(Offset center) {
    return List.generate(6, (i) {
      final angleDeg = 60.0 * i - 30.0;
      final angleRad = angleDeg * pi / 180.0;
      return center + Offset(hexSize * cos(angleRad), hexSize * sin(angleRad));
    });
  }

  /// Screen-space unit vector for an axial direction (dx, dy) — the
  /// hex grid isn't axis-aligned on screen, so this is the actual pixel
  /// direction from one cell's center to its neighbor's, not (dx, dy)
  /// itself. Used to orient arrow heads/necks correctly.
  Offset screenVector(int dx, int dy) {
    final delta = centerOf(Position(dx, dy)) - centerOf(const Position(0, 0));
    final len = delta.distance;
    return len == 0 ? Offset.zero : delta / len;
  }

  /// Inverse of [centerOf]: the axial cell under a local pixel position
  /// (already translated into the same unbounded space [centerOf] uses).
  /// Uses cube-coordinate rounding — snapping q and r independently picks
  /// the wrong hex near cell borders, this doesn't.
  Position cellAt(Offset local) {
    final q = (_sqrt3 / 3 * local.dx - 1 / 3 * local.dy) / hexSize;
    final r = (2 / 3 * local.dy) / hexSize;
    return _roundToCube(q, r);
  }

  Position _roundToCube(double q, double r) {
    final cx = q, cz = r, cy = -cx - cz;
    var rx = cx.roundToDouble();
    var ry = cy.roundToDouble();
    var rz = cz.roundToDouble();

    final dx = (rx - cx).abs();
    final dy = (ry - cy).abs();
    final dz = (rz - cz).abs();

    if (dx > dy && dx > dz) {
      rx = -ry - rz;
    } else if (dy > dz) {
      ry = -rx - rz;
    } else {
      rz = -rx - ry;
    }

    return Position(rx.toInt(), rz.toInt());
  }
}
