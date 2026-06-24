import 'package:arrow_maze_cliente_copy/domain/entities/arrow_segment.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/arrow_color.dart';
import 'package:arrow_maze_cliente_copy/domain/value_objects/direction.dart';

class Arrow {
  final String id;
  final List<ArrowSegment> segments;
  final ArrowColor color;

  const Arrow({
    required this.id,
    required this.segments,
    required this.color,
  }) : assert(segments.length > 0, 'Arrow must have at least one segment');

  ArrowSegment getHead() => segments.last;

  Direction getDirection() => getHead().directionToNext;

  @override
  String toString() => 'Arrow(id: $id, segments: ${segments.length}, color: $color)';
}
