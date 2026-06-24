import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/graph/arrow_node.dart';

class LevelValidator {
  bool validate(Level level) {
    return level.id.isNotEmpty &&
        level.moveLimit > 0 &&
        level.boardLayout.isNotEmpty;
  }

  bool isSolvable(Board board) {
    // Kahn's algorithm to detect cycles and verify solvability
    final inDegree = <String, int>{};
    final graph = board.graph.nodes;

    // Initialize in-degree for all nodes
    for (final nodeId in graph.keys) {
      inDegree[nodeId] = graph[nodeId]!.blockedBy.length;
    }

    // Find all nodes with no incoming edges (activatable)
    final queue = <String>[
      for (final entry in inDegree.entries)
        if (entry.value == 0) entry.key
    ];

    int processed = 0;

    // Process nodes with no incoming edges
    while (queue.isNotEmpty) {
      final nodeId = queue.removeAt(0);
      processed++;

      // For each arrow blocked by this one, remove this as a blocker
      for (final entry in graph.entries) {
        if (entry.value.blockedBy.contains(nodeId)) {
          inDegree[entry.key] = inDegree[entry.key]! - 1;
          if (inDegree[entry.key] == 0) {
            queue.add(entry.key);
          }
        }
      }
    }

    // If all nodes were processed, the board is solvable
    return processed == graph.length;
  }
}
