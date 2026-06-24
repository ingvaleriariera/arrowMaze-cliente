import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/board_shape.dart';
import 'package:arrow_maze_cliente_copy/domain/graph/board_graph.dart';

class BoardBuilder {
  late BoardShape _shape;
  final Map<String, Arrow> _arrows = {};

  BoardBuilder();

  static BoardBuilder create() => BoardBuilder();

  BoardBuilder setShape(BoardShape shape) {
    _shape = shape;
    return this;
  }

  BoardBuilder addArrow(Arrow arrow) {
    _arrows[arrow.id] = arrow;
    return this;
  }

  Board build() {
    // Create grid mapping position -> arrowId
    final grid = <String, String>{};
    for (final arrow in _arrows.values) {
      for (final segment in arrow.segments) {
        grid[segment.position.toKey()] = arrow.id;
      }
    }

    // Build dependency graph
    final graph = BoardGraph.empty();
    graph.build(_arrows, grid, _shape);

    return Board(
      shape: _shape,
      arrows: _arrows,
      grid: grid,
      graph: graph,
    );
  }
}
