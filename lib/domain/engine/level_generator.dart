import 'dart:math';

import '../entities/arrow.dart';
import '../entities/arrow_segment.dart';
import '../value_objects/arrow_color.dart';
import '../value_objects/board_shape.dart';
import '../value_objects/direction.dart';
import '../value_objects/position.dart';

class LevelGenerator {
  static const List<String> _palette = [
    '#E53935',
    '#1E88E5',
    '#43A047',
    '#FBC02D',
    '#8E24AA',
    '#FB8C00',
  ];

  final Random _random;

  LevelGenerator([Random? random]) : _random = random ?? Random();

  List<Arrow> generate(BoardShape shape, {int? arrowCount, int maxAttempts = 500}) {
    final cells = shape.getCells();
    final targetCount = arrowCount ?? (cells.length / 3).floor().clamp(1, cells.length);
    final occupied = <String, String>{};
    final placedArrows = <Arrow>[];
    final directions = [
      Direction.up(),
      Direction.down(),
      Direction.left(),
      Direction.right(),
    ];

    var attempts = 0;
    while (placedArrows.length < targetCount && attempts < maxAttempts) {
      attempts++;

      final head = cells[_random.nextInt(cells.length)];
      if (occupied.containsKey(head.toKey())) continue;

      final direction = directions[_random.nextInt(directions.length)];
      if (!_isExitPathClear(head, direction, shape, occupied)) continue;

      final maxLength = _maxBodyLength(head, direction, shape, occupied);
      if (maxLength < 1) continue;
      final length = 1 + _random.nextInt(maxLength);

      final segments = _buildSegments(head, direction, length);
      final arrowId = 'arrow_${placedArrows.length}';
      final color = ArrowColor.fromHex(_palette[placedArrows.length % _palette.length]);
      final arrow = Arrow(arrowId, segments, color);

      for (final segment in segments) {
        occupied[segment.getPosition().toKey()] = arrowId;
      }
      placedArrows.add(arrow);
    }

    return placedArrows;
  }

  bool _isExitPathClear(
    Position head,
    Direction direction,
    BoardShape shape,
    Map<String, String> occupied,
  ) {
    var current = head;
    while (!shape.isExitFrom(current, direction)) {
      current = current.translate(direction);
      if (occupied.containsKey(current.toKey())) return false;
    }
    return true;
  }

  int _maxBodyLength(
    Position head,
    Direction direction,
    BoardShape shape,
    Map<String, String> occupied,
  ) {
    final backward = direction.opposite();
    var current = head;
    var length = 1;
    while (true) {
      final next = current.translate(backward);
      if (!shape.contains(next) || occupied.containsKey(next.toKey())) break;
      current = next;
      length++;
    }
    return length;
  }

  List<ArrowSegment> _buildSegments(Position head, Direction direction, int length) {
    final segments = <ArrowSegment>[ArrowSegment(head, direction)];
    final backward = direction.opposite();
    var current = head;
    for (var i = 1; i < length; i++) {
      current = current.translate(backward);
      segments.add(ArrowSegment(current, direction));
    }
    return segments;
  }
}
