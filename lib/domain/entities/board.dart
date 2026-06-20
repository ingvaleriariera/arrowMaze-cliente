import '../engine/board_graph.dart';
import '../value_objects/board_shape.dart';
import '../value_objects/position.dart';
import 'arrow.dart';

class Board {
  final BoardShape shape;
  final Map<String, Arrow> arrows;
  final Map<String, String> grid;
  final BoardGraph graph;

  Board(this.shape, this.arrows)
      : grid = _buildGrid(arrows),
        graph = _buildGraph(arrows, shape);

  static Map<String, String> _buildGrid(Map<String, Arrow> arrows) {
    final grid = <String, String>{};
    for (final arrow in arrows.values) {
      for (final segment in arrow.getSegments()) {
        grid[segment.getPosition().toKey()] = arrow.getId();
      }
    }
    return grid;
  }

  static BoardGraph _buildGraph(Map<String, Arrow> arrows, BoardShape shape) {
    final graph = BoardGraph();
    graph.build(arrows, shape);
    return graph;
  }

  Arrow? getArrowAt(Position position) {
    final arrowId = grid[position.toKey()];
    if (arrowId == null) return null;
    return arrows[arrowId];
  }

  void removeArrow(String arrowId) {
    if (!graph.isActivatable(arrowId)) return;
    _removeArrowInternal(arrowId);
  }

  void forceRemoveArrow(String arrowId) {
    _removeArrowInternal(arrowId);
  }

  void _removeArrowInternal(String arrowId) {
    final arrow = arrows.remove(arrowId);
    if (arrow == null) return;
    for (final segment in arrow.getSegments()) {
      grid.remove(segment.getPosition().toKey());
    }
    graph.removeArrow(arrowId);
  }

  List<String> getActivatableArrows() => graph.getActivatable();

  bool isActivatable(String arrowId) => graph.isActivatable(arrowId);

  String? getHint() {
    final activatable = getActivatableArrows();
    return activatable.isEmpty ? null : activatable.first;
  }

  bool isEmpty() => arrows.isEmpty;

  Map<String, Arrow> getArrows() => arrows;

  BoardShape getShape() => shape;
}
