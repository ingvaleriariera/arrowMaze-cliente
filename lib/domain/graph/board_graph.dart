import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/graph/arrow_node.dart';

class BoardGraph {
  final Map<String, ArrowNode> nodes;

  BoardGraph({required this.nodes});

  factory BoardGraph.empty() => BoardGraph(nodes: {});

  void build(
    Map<String, Arrow> arrows,
    Map<String, String> grid,
    BoardShape shape,
  ) {
    nodes.clear();

    // Create empty node for each arrow
    for (final arrow in arrows.values) {
      nodes[arrow.id] = ArrowNode(
        arrowId: arrow.id,
        blockedBy: {},
      );
    }

    // The shape's bounding box: an arrow's ray only truly leaves the
    // board once it passes this, not at the first void cell — interior
    // holes are NOT exits when there's board (and possibly arrows)
    // beyond them. Computed once, not per arrow. The Z bound matters as
    // much as X/Y on extruded boards: without it a forward/back ray
    // (which never changes x or y) would scan forever.
    final allCells = shape.getCells();
    late int maxX, maxY, maxZ;
    if (allCells.isNotEmpty) {
      maxX = allCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
      maxY = allCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);
      maxZ = allCells.map((c) => c.z).reduce((a, b) => a > b ? a : b);
    } else {
      maxX = 100;
      maxY = 100;
      maxZ = 0;
    }

    // For each arrow, scan its exit path from the HEAD all the way to
    // the bounding box — tunneling across interior holes. This makes
    // blockedBy encode the same rule the game applies on tap
    // (isActivatable + hasVoidReentry): an arrow whose ray crosses a
    // hole and hits an arrow on the far side is blocked by it, and gets
    // freed dynamically when that arrow fires (removeArrow prunes
    // blockedBy). Stopping at the first void instead — the old behavior
    // — declared those arrows free, which is what made ring-shaped
    // boards (level 15) unwinnable: generation and the solvability
    // check believed arrows could exit into the hollow center while the
    // actual game refused to fire them.
    for (final arrow in arrows.values) {
      var position = arrow.getHead().position;
      final direction = arrow.getDirection();

      while (true) {
        final nextPos = position.translate(direction);
        if (nextPos.x < 0 ||
            nextPos.y < 0 ||
            nextPos.z < 0 ||
            nextPos.x > maxX ||
            nextPos.y > maxY ||
            nextPos.z > maxZ) {
          break; // Truly off the board — the arrow can exit here
        }

        if (shape.contains(nextPos)) {
          final occupiedByArrowId = grid[nextPos.toKey()];
          if (occupiedByArrowId != null && occupiedByArrowId != arrow.id) {
            nodes[arrow.id]!.blockedBy.add(occupiedByArrowId);
          }
        }

        position = nextPos;
      }
    }

    // DEBUG: Print collision info
    debugPrint('🔍 BoardGraph collision analysis:');
    for (final arrow in arrows.values) {
      final direction = arrow.getDirection();
      final blockedBy = nodes[arrow.id]?.blockedBy ?? {};
      debugPrint(
          '  Arrow ${arrow.id} dir=(${direction.dx},${direction.dy}) blockedBy=$blockedBy');
    }

    final activatable = getActivatable();
    debugPrint('🎯 Activatable arrows: $activatable (${activatable.length}/${arrows.length})');
  }

  void removeArrow(String arrowId) {
    nodes.remove(arrowId);

    // Remove this arrow as a blocker from all other nodes
    for (final node in nodes.values) {
      node.removeBlocker(arrowId);
    }
  }

  List<String> getActivatable() => [
        for (final entry in nodes.entries)
          if (entry.value.isActivatable()) entry.key
      ];

  bool isActivatable(String arrowId) =>
      nodes[arrowId]?.isActivatable() ?? false;

  bool hasVoidReentry(String arrowId, Map<String, Arrow> arrows, Map<String, String> grid, BoardShape shape) {
    final arrow = arrows[arrowId];
    if (arrow == null) return false;
    final direction = arrow.getDirection();
    var position = arrow.getHead().position;
    bool foundVoid = false;
    final allCells = shape.getCells();
    late int maxX, maxY, maxZ;
    if (allCells.isNotEmpty) {
      maxX = allCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
      maxY = allCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);
      maxZ = allCells.map((c) => c.z).reduce((a, b) => a > b ? a : b);
    } else {
      maxX = 100;
      maxY = 100;
      maxZ = 0;
    }
    while (true) {
      final nextPos = position.translate(direction);
      if (nextPos.x < 0 ||
          nextPos.y < 0 ||
          nextPos.z < 0 ||
          nextPos.x > maxX ||
          nextPos.y > maxY ||
          nextPos.z > maxZ) break;
      if (!shape.contains(nextPos)) { foundVoid = true; }
      else if (foundVoid && shape.contains(nextPos)) {
        final occupiedBy = grid[nextPos.toKey()];
        if (occupiedBy != null && occupiedBy != arrowId) { return true; }
      }
      position = nextPos;
    }
    return false;
  }

  int size() => nodes.length;

  @override
  String toString() => 'BoardGraph(nodes: ${nodes.length})';
}
