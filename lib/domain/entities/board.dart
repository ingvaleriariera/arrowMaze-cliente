import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/graph/board_graph.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class Board {
  final BoardShape shape;
  final Map<String, Arrow> arrows;
  final Map<String, String> grid;
  final BoardGraph graph;

  Board({
    required this.shape,
    required this.arrows,
    required this.grid,
    required this.graph,
  });

  Arrow? getArrowAt(Position position) {
    final arrowId = grid[position.toKey()];
    return arrowId != null ? arrows[arrowId] : null;
  }

  void removeArrow(String arrowId) {
    if (!isActivatable(arrowId)) return;

    final arrow = arrows[arrowId];
    if (arrow == null) return;

    // Remove from grid
    for (final segment in arrow.segments) {
      grid.remove(segment.position.toKey());
    }

    // Remove from arrows
    arrows.remove(arrowId);

    // Update graph
    graph.removeArrow(arrowId);
  }

  void forceRemoveArrow(String arrowId) {
    final arrow = arrows[arrowId];
    if (arrow == null) return;

    // Remove from grid
    for (final segment in arrow.segments) {
      grid.remove(segment.position.toKey());
    }

    // Remove from arrows
    arrows.remove(arrowId);

    // Update graph
    graph.removeArrow(arrowId);
  }

  List<String> getActivatableArrows() => graph.getActivatable();

  bool isActivatable(String arrowId) => graph.isActivatable(arrowId);

  String? getHint() {
    final activatable = getActivatableArrows();
    return activatable.isNotEmpty ? activatable.first : null;
  }

  bool isEmpty() => arrows.isEmpty;

  @override
  String toString() => 'Board(arrows: ${arrows.length}, cells: ${shape.size()})';
}
