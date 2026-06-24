import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';

class BoardShape {
  final Set<String> validCells;

  BoardShape({required this.validCells});

  factory BoardShape.fromJson(String jsonString) {
    debugPrint('=== BoardShape.fromJson RAW INPUT ===');
    debugPrint(jsonString.substring(0, (jsonString.length < 200 ? jsonString.length : 200)));

    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final grid = map['grid'] as List<dynamic>;
    final validCells = <String>{};

    final rows = grid.length;
    final cols = rows > 0 ? (grid[0] as List<dynamic>).length : 0;

    for (int row = 0; row < grid.length; row++) {
      final cols = grid[row] as List<dynamic>;
      for (int col = 0; col < cols.length; col++) {
        if (cols[col] == 1) {
          validCells.add('$col,$row'); // x=col, y=row
        }
      }
    }

    debugPrint(
        '🔲 BoardShape.fromJson: ${validCells.length} valid cells from ${rows}x${cols} grid');

    // Verify first 10 keys are in correct x,y format
    final sortedKeys = validCells.toList()..sort();
    debugPrint('📍 BoardShape validCells (first 10):');
    final first10 = sortedKeys.take(10).toList();
    debugPrint('   $first10');
    debugPrint(
        '   (should be [0,0, 1,0, 2,0, 3,0, 4,0, 0,1, 1,1, 2,1, 3,1, 4,1] for 5x5)');

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
