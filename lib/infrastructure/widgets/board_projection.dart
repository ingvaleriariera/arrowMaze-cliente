import 'dart:ui';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

/// Cascade (isometric-style) projection for 3D boards: every layer is
/// drawn simultaneously, each one offset diagonally (up-right) from the
/// layer below, so arrow bodies crossing layers appear as continuous
/// diagonal strokes "in the air" between floors.
///
/// This is the single source of truth for cell(x,y,z) → pixel math —
/// shared by BoardPainter (drawing) and GameScreen (tap hit-testing), so
/// what you see is exactly what you tap. Flat boards (maxZ = 0) project
/// identically to the old 2D math.
class BoardProjection {
  /// Diagonal shift between consecutive layers, as a fraction of a cell.
  /// Larger values make each floor visually further apart → the prism looks
  /// fat and three-dimensional. 2D boards (maxZ = 0) are unaffected — the
  /// step is multiplied by z/maxZ which is always 0 for flat shapes.
  static const double depthStep = 1.5;

  final double cellSize;
  final int minX;
  final int minY;
  final int maxZ;

  const BoardProjection({
    required this.cellSize,
    required this.minX,
    required this.minY,
    required this.maxZ,
  });

  double get _step => cellSize * depthStep;

  /// Screen center of a cell. Layer z is shifted right by z steps and up
  /// by z steps; the whole stack is pushed down by maxZ steps so the top
  /// layer never leaves the canvas.
  Offset centerOf(Position pos) =>
      centerOfXYZf(pos.x.toDouble(), pos.y.toDouble(), pos.z.toDouble());

  /// Same as [centerOf] but accepts fractional grid coordinates — used by
  /// the exit animation, which interpolates between cells.
  Offset centerOfXYZ(double gx, double gy, int z) =>
      centerOfXYZf(gx, gy, z.toDouble());

  /// Same as [centerOfXYZ] but accepts a fractional z coordinate — used by
  /// the worm exit animation so Z-exit arrows glide smoothly between layers
  /// instead of jumping. Planar arrows pass their integer z cast to double
  /// and get exactly the same result as before.
  Offset centerOfXYZf(double gx, double gy, double z) => Offset(
        (gx - minX) * cellSize + cellSize / 2 + z * _step,
        (gy - minY) * cellSize + cellSize / 2 + (maxZ - z) * _step,
      );

  /// Canvas size needed to fit [cols] × [rows] cells plus the cascade.
  Size canvasSize(int cols, int rows) => Size(
        cols * cellSize + maxZ * _step,
        rows * cellSize + maxZ * _step,
      );

  /// The grid cell of layer [z] under a local pixel position, or null if
  /// the pixel falls outside that layer's grid area. Callers hit-test
  /// layers from the top (z = maxZ) down so upper floors win where the
  /// cascades overlap.
  Position? cellAt(Offset local, int z) {
    final px = local.dx - z * _step;
    final py = local.dy - (maxZ - z) * _step;
    if (px < 0 || py < 0) return null;
    final gridX = (px / cellSize).floor() + minX;
    final gridY = (py / cellSize).floor() + minY;
    return Position(gridX, gridY, z);
  }

  /// Screen-space unit vector for a direction: planar directions map to
  /// themselves; Z directions map to the cascade diagonal (forward/z+1
  /// climbs up-right, back/z-1 dives down-left).
  (double, double) screenVector(int dx, int dy, int dz) {
    if (dz == 0) return (dx.toDouble(), dy.toDouble());
    const diag = 0.7071; // 1/√2 — unit-length diagonal
    return (dz * diag, -dz * diag);
  }
}
