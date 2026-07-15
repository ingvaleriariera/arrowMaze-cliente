import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;

/// Computes true 3D to 2D screen projections using a camera matrix.
/// Replaces the static isometric BoardProjection for true volumetric rendering.
class Math3DProjection {
  final double cellSize;
  final int minX;
  final int minY;
  final int cols;
  final int rows;
  final int maxZ;
  final Size canvasSize;

  late final math.Matrix4 _transform;

  /// Distance between Z layers.
  double get zStep => cellSize * 1.5;

  Math3DProjection({
    required this.cellSize,
    required this.minX,
    required this.minY,
    required this.cols,
    required this.rows,
    required this.maxZ,
    required this.canvasSize,
    required double rotX,
    required double rotY,
  }) {
    // 1. Center of the board in logical grid units.
    final cx = (cols - 1) / 2.0;
    final cy = (rows - 1) / 2.0;
    final cz = maxZ / 2.0;

    // 2. Build the transformation matrix.
    _transform = math.Matrix4.identity();
    
    // Move origin to the center of the screen
    _transform.translate(canvasSize.width / 2, canvasSize.height / 2, 0.0);
    
    // Add perspective
    _transform.setEntry(3, 2, 0.0015);
    
    // Apply camera rotation
    _transform.rotateX(rotX);
    _transform.rotateY(rotY);
    
    // Scale by cellSize so grid units become screen pixels
    _transform.scale(cellSize, cellSize, zStep);

    // Translate so the board is centered at (0,0,0) before rotation
    _transform.translate(-cx, -cy, -cz);
  }

  /// Projects a logical grid coordinate (gx, gy, gz) to 2D screen coordinates
  /// and returns the depth (w) for Z-sorting.
  ({Offset screen, double depth}) project(double gx, double gy, double gz) {
    // 1. Local coordinate relative to min bounds
    final lx = gx - minX;
    final ly = gy - minY;
    // Z is reversed physically so lower floors are visually "below" upper floors.
    // In our grid: z=0 is ground, z=maxZ is top.
    // In 3D space, Y is usually down, but let's map Z directly and adjust in matrix.
    // Wait, if Z is up, then positive Z comes TOWARDS the camera if we look down.
    // Actually, let's just project lx, ly, lz.
    final lz = gz;

    final vec = math.Vector4(lx, ly, lz, 1.0);
    final transformed = _transform.transform(vec);
    
    // Perspective divide
    final w = transformed.w;
    final sx = transformed.x / w;
    final sy = transformed.y / w;
    
    return (screen: Offset(sx, sy), depth: w);
  }

  /// Calculates the screen-space vector for a given direction.
  /// Used to orient the arrow heads correctly in 2D space.
  (double, double) screenVector(double gx, double gy, double gz, double dx, double dy, double dz) {
    final p1 = project(gx, gy, gz).screen;
    final p2 = project(gx + dx, gy + dy, gz + dz).screen;
    final v = p2 - p1;
    final len = v.distance;
    if (len == 0) return (0.0, 0.0);
    return (v.dx / len, v.dy / len);
  }
}
