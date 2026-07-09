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

    // For each arrow, scan its exit path from the HEAD
    for (final arrow in arrows.values) {
      var position = arrow.getHead().position;
      final direction = arrow.getDirection();

      // Scan from head in direction until we reach exit (edge or void)
      while (true) {
        final nextPos = position.translate(direction);

        // Stop if: board edge OR void cell
        if (!shape.contains(nextPos)) {
          break; // Arrow can exit here
        }

        // Check if another arrow occupies this cell
        final occupiedByArrowId = grid[nextPos.toKey()];
        if (occupiedByArrowId != null && occupiedByArrowId != arrow.id) {
          // Found blocker — add it but CONTINUE scanning
          nodes[arrow.id]!.blockedBy.add(occupiedByArrowId);
        }

        position = nextPos;
      }
      bool foundVoid = false;
      var position2 = arrow.getHead().position;
      final allCells = shape.getCells();
      late int maxX, maxY;
      if (allCells.isNotEmpty) {
        maxX = allCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
        maxY = allCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);
      } else {
        maxX = 100;
        maxY = 100;
      }
      while (true) {
        final nextPos2 = position2.translate(direction);
        if (nextPos2.x < 0 || nextPos2.y < 0 || nextPos2.x > maxX || nextPos2.y > maxY) break;
        if (!shape.contains(nextPos2)) { foundVoid = true; }
        else if (foundVoid && shape.contains(nextPos2)) { nodes[arrow.id]!.blockedByVoidReentry = true; break; }
        position2 = nextPos2;
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
    late int maxX, maxY;
    if (allCells.isNotEmpty) {
      maxX = allCells.map((c) => c.x).reduce((a, b) => a > b ? a : b);
      maxY = allCells.map((c) => c.y).reduce((a, b) => a > b ? a : b);
    } else {
      maxX = 100;
      maxY = 100;
    }
    while (true) {
      final nextPos = position.translate(direction);
      if (nextPos.x < 0 || nextPos.y < 0 || nextPos.x > maxX || nextPos.y > maxY) break;
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
