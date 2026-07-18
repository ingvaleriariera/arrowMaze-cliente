import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class BoardShape {
  final Set<String> validCells;

  BoardShape({required this.validCells});

  factory BoardShape.fromJson(String jsonString) {
    debugPrint('=== BoardShape.fromJson RAW INPUT ===');
    debugPrint(jsonString.substring(0, (jsonString.length < 200 ? jsonString.length : 200)));

    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final grid = map['grid'] as List<dynamic>;
    final validCells = <String>{};

    final rows = grid.length;
    final cols = rows > 0 ? (grid[0] as List<dynamic>).length : 0;

    for (int row = 0; row < grid.length; row++) {
      final cols = grid[row] as List<dynamic>;
      for (int col = 0; col < cols.length; col++) {
        if (cols[col] == 1) {
          validCells.add('$col,$row'); // x=col, y=row
        }
      }
    }

    debugPrint(
        '🔲 BoardShape.fromJson: ${validCells.length} valid cells from ${rows}x${cols} grid');

    // Verify first 10 keys are in correct x,y format
    final sortedKeys = validCells.toList()..sort();
    debugPrint('📍 BoardShape validCells (first 10):');
    final first10 = sortedKeys.take(10).toList();
    debugPrint('   $first10');
    debugPrint(
        '   (should be [0,0, 1,0, 2,0, 3,0, 4,0, 0,1, 1,1, 2,1, 3,1, 4,1] for 5x5)');

    return BoardShape(validCells: validCells);
  }

  /// Extrudes a flat silhouette into a prism of [depth] identical layers:
  /// every "x,y" cell becomes cells at z=0..depth-1. With depth=1 the
  /// result has exactly the same keys as [shape2D] (z=0 uses the 2-part
  /// canonical key), so 2D boards flow through unchanged.
  ///
  /// This is the ONLY place 3D boards are born — the backend keeps sending
  /// flat 0/1 grids and never learns about depth.
  static BoardShape extrude(BoardShape shape2D, int depth) {
    if (depth <= 1) return shape2D;

    final cells = <String>{};
    for (final cell in shape2D.getCells()) {
      for (int z = 0; z < depth; z++) {
        cells.add(Position(cell.x, cell.y, z).toKey());
      }
    }
    return BoardShape(validCells: cells);
  }

  /// A hexagonal region of [radius] rings around axial center (centerQ,
  /// centerR) — shared by [hexagon] and [hexagonRing] below.
  static Set<String> _hexRegion(int centerQ, int centerR, int radius) {
    final cells = <String>{};
    for (int dq = -radius; dq <= radius; dq++) {
      final rMin = dq < 0 ? -radius - dq : -radius;
      final rMax = dq < 0 ? radius : radius - dq;
      for (int dr = rMin; dr <= rMax; dr++) {
        cells.add(Position(centerQ + dq, centerR + dr).toKey());
      }
    }
    return cells;
  }

  /// A hexagon made of hexagons, [radius] rings out from the center,
  /// addressed by axial coordinates (x=q, y=r). Offset so every
  /// coordinate stays >= 0 — BoardBuilder/BoardGraph's ray-scan treats a
  /// negative x/y as "already off the board", same assumption the 2D
  /// square boards rely on. Only meaningful paired with
  /// `BoardBuilder(useHexDirections: true)`; used with the normal 4/6
  /// planar directions it's just a same-shaped square-ish region.
  static BoardShape hexagon(int radius) =>
      BoardShape(validCells: _hexRegion(radius, radius, radius));

  /// A hexagonal "donut" — a big hexagon with a smaller
  /// hexagonal hole punched out of its center. A bigger, structurally
  /// different board than [hexagon]: it forces arrows to route around
  /// the hole (and exercises the same "void re-entry" rule the square
  /// ring-shaped levels already rely on), instead of just being a
  /// larger version of the same solid shape.
  static BoardShape hexagonRing(int outerRadius, int innerRadius) {
    final outer = _hexRegion(outerRadius, outerRadius, outerRadius);
    final inner = _hexRegion(outerRadius, outerRadius, innerRadius);
    return BoardShape(validCells: outer.difference(inner));
  }

  bool contains(Position position) =>
      validCells.contains(position.toKey());

  bool isExitFrom(Position position, Direction direction) {
    final next = position.translate(direction);
    return !contains(next);
  }

  /// Distance in cell-units from [from] to the board's exit (the border or
  /// a void cell) along [direction]. Used both to check activatability
  /// (board_builder.dart) and to size the exit animation (GameScreen).
  int distanceToExit(Position from, Direction direction) {
    var pos = from;
    var distance = 0;
    while (true) {
      final next = pos.translate(direction);
      distance++;
      if (!contains(next)) break;
      pos = next;
    }
    return distance;
  }

  List<Position> getCells() =>
      validCells.map(Position.fromKey).toList();

  /// Highest z among the shape's cells (0 for flat boards). Ray scans use
  /// it the same way they use the x/y bounding box: a ray traveling along
  /// Z has truly left the board once it passes this.
  int maxZ() {
    var max = 0;
    for (final cell in getCells()) {
      if (cell.z > max) max = cell.z;
    }
    return max;
  }

  int size() => validCells.length;

  @override
  String toString() => 'BoardShape(cells: ${validCells.length})';
}
