import 'dart:convert';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class BoardShape {
  final Set<String> validCells;

  BoardShape({required this.validCells});

  factory BoardShape.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final grid = map['grid'] as List<dynamic>;
    final validCells = <String>{};

    for (int row = 0; row < grid.length; row++) {
      final cols = grid[row] as List<dynamic>;
      for (int col = 0; col < cols.length; col++) {
        if (cols[col] == 1) {
          validCells.add('$col,$row'); // x=col, y=row
        }
      }
    }

    return BoardShape(validCells: validCells);
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
