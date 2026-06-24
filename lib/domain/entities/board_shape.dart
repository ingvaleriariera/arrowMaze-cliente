import 'dart:convert';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class BoardShape {
  final Set<String> validCells;

  BoardShape({required this.validCells});

  factory BoardShape.fromJson(String json) {
    List<List<int>> grid = List<List<int>>.from(
      jsonDecode(json).map((row) => List<int>.from(row)),
    );

    final cells = <String>{};
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        if (grid[y][x] == 1) {
          cells.add('$x,$y');
        }
      }
    }
    return BoardShape(validCells: cells);
  }

  bool contains(Position position) =>
      validCells.contains(position.toKey());

  bool isExitFrom(Position position, Direction direction) {
    final next = position.translate(direction);
    return !contains(next);
  }

  List<Position> getCells() => validCells
      .map((key) {
        final parts = key.split(',');
        return Position(int.parse(parts[0]), int.parse(parts[1]));
      })
      .toList();

  int size() => validCells.length;

  @override
  String toString() => 'BoardShape(cells: ${validCells.length})';
}
