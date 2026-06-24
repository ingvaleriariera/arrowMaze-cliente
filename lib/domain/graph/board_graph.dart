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

      // Scan from head in direction until we hit an exit
      // Continue scanning entire path — do NOT break at first blocker
      while (!shape.isExitFrom(position, direction)) {
        position = position.translate(direction);

        // Check if another arrow occupies this position
        final occupiedByArrowId = grid[position.toKey()];
        if (occupiedByArrowId != null && occupiedByArrowId != arrow.id) {
          // Found a blocker — add it but CONTINUE scanning
          nodes[arrow.id]!.blockedBy.add(occupiedByArrowId);
          // DO NOT break — keep scanning the entire path
        }
      }
    }
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

  int size() => nodes.length;

  @override
  String toString() => 'BoardGraph(nodes: ${nodes.length})';
}
