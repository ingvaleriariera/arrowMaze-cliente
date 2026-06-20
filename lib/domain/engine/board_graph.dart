import '../entities/arrow.dart';
import '../value_objects/board_shape.dart';
import 'arrow_node.dart';

class BoardGraph {
  final Map<String, ArrowNode> nodes;

  BoardGraph() : nodes = {};

  void build(Map<String, Arrow> arrows, BoardShape shape) {
    nodes.clear();
    final grid = <String, String>{};
    for (final arrow in arrows.values) {
      for (final segment in arrow.getSegments()) {
        grid[segment.getPosition().toKey()] = arrow.getId();
      }
    }
    for (final arrow in arrows.values) {
      final blockers = <String>{};
      final direction = arrow.getDirection();
      var current = arrow.getHead().getPosition();
      while (!shape.isExitFrom(current, direction)) {
        current = current.translate(direction);
        final occupant = grid[current.toKey()];
        if (occupant != null && occupant != arrow.getId()) {
          blockers.add(occupant);
        }
      }
      nodes[arrow.getId()] = ArrowNode(arrow.getId(), blockers);
    }
  }

  void removeArrow(String arrowId) {
    nodes.remove(arrowId);
    for (final node in nodes.values) {
      node.removeBlocker(arrowId);
    }
  }

  List<String> getActivatable() => nodes.values
      .where((node) => node.isActivatable())
      .map((node) => node.getArrowId())
      .toList();

  bool isActivatable(String arrowId) => nodes[arrowId]?.isActivatable() ?? false;

  int size() => nodes.length;
}
