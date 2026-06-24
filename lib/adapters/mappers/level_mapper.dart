import 'package:arrow_maze_cliente_copy/domain/entities/arrow.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/entities/level.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/position.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/time_limit.dart';

class LevelMapper {
  Level fromJson(Map<String, dynamic> json) {
    final timeSeconds = json['timeLimitSeconds'] as int?;
    final timeLimit = timeSeconds != null && timeSeconds > 0
        ? TimeLimit.of(timeSeconds)
        : TimeLimit.none;

    return Level(
      id: json['id'] as String,
      difficulty: json['difficulty'] as String,
      boardLayout: json['boardLayout'] as String,
      moveLimit: json['moveLimit'] as int,
      timeLimit: timeLimit,
    );
  }

  List<Level> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
  }

  Arrow arrowFromJson(Map<String, dynamic> json) {
    final segments = <ArrowSegment>[];
    final positionList = json['cells'] as List<dynamic>? ?? [];
    final dirHex = json['color'] as String;

    for (int i = 0; i < positionList.length; i++) {
      final pos = positionList[i] as Map<String, dynamic>;
      final x = pos['x'] as int;
      final y = pos['y'] as int;
      final position = Position(x, y);

      // Direction for the segment (all segments point in the arrow's direction)
      final direction = _parseDirection(json['direction'] as String);

      segments.add(ArrowSegment(
        position: position,
        directionToNext: direction,
      ));
    }

    return Arrow(
      id: json['id'] as String,
      segments: segments,
      color: ArrowColor.fromHex(dirHex),
    );
  }

  Direction _parseDirection(String directionStr) {
    switch (directionStr.toUpperCase()) {
      case 'UP':
        return Direction.up;
      case 'DOWN':
        return Direction.down;
      case 'LEFT':
        return Direction.left;
      case 'RIGHT':
        return Direction.right;
      default:
        return Direction.right;
    }
  }
}
