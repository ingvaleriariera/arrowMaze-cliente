import 'dart:convert';

import 'direction.dart';
import 'position.dart';

class BoardShape {
  final Set<String> validCells;

  BoardShape._(this.validCells);

  static BoardShape fromJson(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final grid = decoded['grid'] as List<dynamic>;
    final cells = <String>{};
    for (var y = 0; y < grid.length; y++) {
      final row = grid[y] as List<dynamic>;
      for (var x = 0; x < row.length; x++) {
        if (row[x] == 1) {
          cells.add('$x,$y');
        }
      }
    }
    return BoardShape._(cells);
  }

  bool contains(Position position) => validCells.contains(position.toKey());

  bool isExitFrom(Position position, Direction direction) =>
      !contains(position.translate(direction));

  List<Position> getCells() {
    return validCells.map((key) {
      final parts = key.split(',');
      return Position(int.parse(parts[0]), int.parse(parts[1]));
    }).toList();
  }

  int size() => validCells.length;
}
