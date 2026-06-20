import '../../domain/entities/arrow.dart';
import '../../domain/entities/arrow_segment.dart';
import '../../domain/entities/level.dart';
import '../../domain/value_objects/arrow_color.dart';
import '../../domain/value_objects/direction.dart';
import '../../domain/value_objects/position.dart';
import '../../domain/value_objects/time_limit.dart';

class LevelMapper {
  Level fromJson(Map<String, dynamic> json) {
    final difficulty = json['difficulty'] as String;
    final timeLimitSeconds = json['timeLimitSeconds'] as int?;
    final timeLimit = timeLimitSeconds != null
        ? TimeLimit.of(timeLimitSeconds)
        : (difficulty == 'hard' ? TimeLimit.of(60) : TimeLimit.none());

    return Level(
      json['id'] as String,
      difficulty,
      json['boardLayout'] as String,
      json['moveLimit'] as int,
      timeLimit,
    );
  }

  // Unused: arrows are generated client-side by LevelGenerator,
  // not received from backend. Kept for potential future use.
  Arrow arrowFromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as List<dynamic>;
    final segments = segmentsJson.map((segmentJson) {
      final segment = segmentJson as Map<String, dynamic>;
      final position = Position(segment['x'] as int, segment['y'] as int);
      final direction = _directionFromString(segment['direction'] as String);
      return ArrowSegment(position, direction);
    }).toList();

    return Arrow(
      json['id'] as String,
      segments,
      ArrowColor.fromHex(json['color'] as String),
    );
  }

  Direction _directionFromString(String value) {
    switch (value) {
      case 'up':
        return Direction.up();
      case 'down':
        return Direction.down();
      case 'left':
        return Direction.left();
      case 'right':
        return Direction.right();
      default:
        throw ArgumentError('Unknown direction: $value');
    }
  }
}
